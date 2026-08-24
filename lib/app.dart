// Root widget of the Balance application plus the app-level DI, service
// lifecycle, and localization wiring surrounding it.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:balance/core/database/database_module.dart';
import 'package:balance/core/di/injection.dart';
import 'package:balance/core/integrations/biometrics/biometric_lock_observer.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/core/presentation/navigation/app_router.dart';
import 'package:balance/core/presentation/navigation/app_routes.dart';
import 'package:balance/core/presentation/screens/app_initialization_error_screen.dart';
import 'package:balance/core/presentation/screens/app_splash_screen.dart';
import 'package:balance/core/presentation/screens/biometric_shield_screen.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';

/// The root widget of the application, configuring global theme, localization,
/// dependency injection, and reactive [GoRouter] navigation.
class App extends StatefulWidget {
  /// An optional repository override for widget tests.
  final WeightRepository? repositoryOverride;

  /// An optional health service override for widget tests.
  final HealthService? healthServiceOverride;

  /// Creates the root [App] widget with optional test overrides.
  const App({super.key, this.repositoryOverride, this.healthServiceOverride});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late AppLocalizations _l10n;
  late Future<WeightRepository> _initFuture;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  /// Bootstraps the core services (database, notifications, health platform,
  /// biometrics) and returns the ready [WeightRepository] once all
  /// initialization has finished.
  Future<WeightRepository> _initializeApp() async {
    try {
      if (widget.repositoryOverride != null) {
        // Fast-path initialization for tests.
        return widget.repositoryOverride!;
      }

      final WeightRepository repository;
      final NotificationService notificationService;
      final BiometricService biometricService;

      if (getIt.isRegistered<WeightRepository>()) {
        repository = getIt<WeightRepository>();
        notificationService = getIt<NotificationService>();
        biometricService = getIt<BiometricService>();
      } else {
        // Fallback for tests when configureDependencies was not invoked
        final isar = await DatabaseModule.initialize();
        biometricService = BiometricService.instance;
        repository = IsarWeightRepository(
          isar: isar,
          unlockSignal: biometricService.authenticationSuccesses,
        );
        notificationService = NotificationService.instance;
      }

      // 2. Notifications — initialize the plugin and timezone database so
      // reminders can be scheduled with the device's local time zone.
      await notificationService.initialize();

      // 3. Health — the plugin requires configure() before any other API call.
      try {
        await Health().configure();
      } catch (e, stack) {
        AppCrashReporter.recordError(
          e,
          stack,
          reason: 'Health().configure() startup degradation',
          fatal: false,
        );
      }

      // 4. Biometrics — canAuthenticate() also covers OS PIN/pattern/password fallback.
      final isBiometricSupported = await biometricService.canAuthenticate();
      if (mounted) {
        context.read<AppSettingsBloc>().add(
          UpdateBiometricSupport(isBiometricSupported),
        );
      }

      return repository;
    } finally {
      // Drop the native splash screen regardless of outcome.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }
  }

  void _ensureRouter(AppSettingsBloc settingsBloc) {
    _router ??= createAppRouter(
      settingsBloc: settingsBloc,
      initialLocation: AppRoutes.today,
      observers: [
        if (AppAnalytics.instance != null)
          FirebaseAnalyticsObserver(analytics: AppAnalytics.instance!),
      ],
    );
    NotificationService.instance.onNotificationTapped = (payload) {
      _router?.go(payload);
    };
  }

  /// Builds the provider stack that wires [repository] into the widget tree
  /// and resolves the router content.
  Widget _buildAppContent(
    WeightRepository repository,
    AppSettingsState settingsState,
    AppSettingsBloc settingsBloc,
  ) {
    _ensureRouter(settingsBloc);

    return RepositoryProvider.value(
      value: repository,
      child: BlocProvider(
        create: (context) {
          final bloc =
              getIt.isRegistered<WeightBloc>() &&
                  widget.healthServiceOverride == null
              ? getIt<WeightBloc>()
              : WeightBloc(
                  repository: context.read<WeightRepository>(),
                  appSettingsBloc: settingsBloc,
                  healthService: widget.healthServiceOverride,
                );
          bloc.add(const SubscribeToWeightChanges());
          if (settingsBloc.state.isHealthSyncEnabled) {
            bloc.add(const SyncHealthEntries());
          }
          return bloc;
        },
        child: _HealthSyncLifecycleObserver(
          child: _ObserverRegistrar(
            localizedReason: () => _l10n.biometricAuthReason,
            child: _LocalizationSync(
              onLocalized: (l10n) {
                _l10n = l10n;
                NotificationService.instance.setLocalizedTexts(
                  title: l10n.notificationReminderTitle,
                  body: l10n.notificationReminderBody,
                  channelName: l10n.notificationChannelName,
                  channelDescription: l10n.notificationChannelDescription,
                );
              },
              child: BlocListener<AppSettingsBloc, AppSettingsState>(
                listenWhen: (previous, current) =>
                    previous.isLocked != current.isLocked ||
                    previous.isOnboardingCompleted !=
                        current.isOnboardingCompleted,
                listener: (context, state) {
                  _router?.refresh();
                },
                child: Router.withConfig(config: _router!),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the [MaterialApp] with the resolved theme, locale support,
  /// biometric shield overlay, and the appropriate root screen.
  @override
  Widget build(BuildContext context) {
    final settingsBloc = context.read<AppSettingsBloc>();

    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, settingsState) {
        final themeMode = switch (settingsState.themeMode) {
          AppThemeMode.system => ThemeMode.system,
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
        };

        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [
            if (AppAnalytics.instance != null)
              FirebaseAnalyticsObserver(analytics: AppAnalytics.instance!),
          ],
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.35,
                ),
              ),
              child: Stack(
                children: [
                  ?child,
                  if (settingsState.isLocked)
                    const Positioned.fill(child: BiometricShieldScreen()),
                ],
              ),
            );
          },
          home: widget.repositoryOverride != null
              ? _buildAppContent(
                  widget.repositoryOverride!,
                  settingsState,
                  settingsBloc,
                )
              : FutureBuilder<WeightRepository>(
                  future: _initFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppSplashScreen();
                    } else if (snapshot.hasError) {
                      return AppInitializationErrorContent(
                        error: snapshot.error!,
                        onRetry: () {
                          setState(() {
                            _initFuture = _initializeApp();
                          });
                        },
                      );
                    } else {
                      return _buildAppContent(
                        snapshot.data!,
                        settingsState,
                        settingsBloc,
                      );
                    }
                  },
                ),
        );
      },
    );
  }
}

/// Lives below the BlocProvider so the observer can resolve the weight BLoC
/// dynamically through its own context instead of capturing a direct instance
/// reference, which could go stale if the provider is ever recreated.
class _ObserverRegistrar extends StatefulWidget {
  final String Function() localizedReason;

  final Widget child;

  const _ObserverRegistrar({
    required this.localizedReason,
    required this.child,
  });

  @override
  State<_ObserverRegistrar> createState() => _ObserverRegistrarState();
}

class _ObserverRegistrarState extends State<_ObserverRegistrar> {
  BiometricLockObserver? _observer;

  @override
  void initState() {
    super.initState();
    final settingsBloc = context.read<AppSettingsBloc>();
    if (settingsBloc.state.isBiometricLockEnabled) {
      settingsBloc.add(const SetLocked(true));
    }
    _observer = BiometricLockObserver(
      isBiometricLockEnabled: () => settingsBloc.state.isBiometricLockEnabled,
      isAppLocked: () => settingsBloc.state.isLocked,
      lockEnabledStream: settingsBloc.stream.map(
        (s) => s.isBiometricLockEnabled,
      ),
      onLockStateChanged: (locked) => settingsBloc.add(SetLocked(locked)),
      localizedReason: widget.localizedReason,
      onDatabaseReopened: () async {
        if (mounted) {
          context.read<WeightBloc>().add(const SubscribeToWeightChanges());
        }
      },
      verifyDatabaseIntegrity: () async {
        final result = await DatabaseModule.ensureInstanceIntegrity();
        return (reopened: result.reopened);
      },
    );
  }

  @override
  void dispose() {
    try {
      _observer?.removeThisObserver();
    } finally {
      _observer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Lives below the BlocProvider so the observer can resolve the weight and
/// settings BLoCs dynamically through its own context instead of capturing
/// direct instance references, which could go stale if the providers are ever
/// recreated.
class _HealthSyncLifecycleObserver extends StatefulWidget {
  final Widget child;

  const _HealthSyncLifecycleObserver({required this.child});

  @override
  State<_HealthSyncLifecycleObserver> createState() =>
      _HealthSyncLifecycleObserverState();
}

class _HealthSyncLifecycleObserverState
    extends State<_HealthSyncLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    // Always dispatch a SubscribeToWeightChanges to immediately recover Isar streams
    // that might have been disrupted in the background, bypassing the exponential backoff.
    context.read<WeightBloc>().add(const SubscribeToWeightChanges());

    final settingsBloc = context.read<AppSettingsBloc>();
    if (!settingsBloc.state.isHealthSyncEnabled) return;
    context.read<WeightBloc>().add(const SyncHealthEntries());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A widget that synchronizes the active locale with services that live
/// outside the widget tree.
class _LocalizationSync extends StatefulWidget {
  final Widget child;

  final void Function(AppLocalizations l10n) onLocalized;

  const _LocalizationSync({required this.child, required this.onLocalized});

  @override
  State<_LocalizationSync> createState() => _LocalizationSyncState();
}

class _LocalizationSyncState extends State<_LocalizationSync> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.onLocalized(AppLocalizations.of(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
