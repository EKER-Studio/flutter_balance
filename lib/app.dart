import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:health/health.dart';
import 'package:balance/core/database/database_module.dart';
import 'package:balance/core/integrations/biometrics/biometric_lock_observer.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/core/presentation/screens/app_initialization_error_screen.dart';
import 'package:balance/core/presentation/screens/app_splash_screen.dart';
import 'package:balance/core/presentation/screens/biometric_shield_screen.dart';
import 'package:balance/features/navigation/presentation/screens/main_navigation_screen.dart';
import 'package:balance/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';

/// Root widget of the Balance application.
class App extends StatefulWidget {
  /// Optional repository override for testing.
  final WeightRepository? repositoryOverride;

  /// Optional health backend override for testing.
  final HealthService? healthServiceOverride;

  /// Creates the root [App] widget.
  ///
  /// @param repositoryOverride Optional repository override for testing.
  /// @param healthServiceOverride Optional health backend override for testing.
  const App({super.key, this.repositoryOverride, this.healthServiceOverride});

  @override
  State<App> createState() => _AppState();
}

/// State for the root [App] widget; owns service initialization and DI wiring.
class _AppState extends State<App> {
  late AppLocalizations _l10n;
  late Future<WeightRepository> _initFuture;

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

      // 1. Initialize Isar
      final isar = await DatabaseModule.initialize();
      final repository = IsarWeightRepository(
        isar: isar,
        unlockSignal: BiometricService.instance.authenticationSuccesses,
      );

      // 2. Notifications — evaluate exact alarm scheduling availability; the
      // SCHEDULE_EXACT_ALARM permission can be revoked by the user on Android
      // 12+ at any time, which would otherwise silently break daily reminders.
      await NotificationService.instance.initialize();
      final canScheduleExact = await NotificationService.instance
          .canScheduleExactNotifications();
      if (mounted) {
        context.read<AppSettingsBloc>().add(
          UpdateNotificationInexactScheduling(!canScheduleExact),
        );
      }

      // 3. Health — the plugin requires configure() before any other API call.
      // A failure (e.g. device_info channel error on devices without health
      // platform support) must not block app startup; every HealthService call
      // already degrades gracefully, so the plugin is simply left unconfigured.
      try {
        await Health().configure();
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('[App] Health().configure() failed: $e\n$stack');
        }
      }

      // 4. Biometrics — canAuthenticate() also covers OS PIN/pattern/password
      // fallback, not just enrolled biometric hardware (see
      // BiometricService.authenticate, which already supports it).
      final isBiometricSupported = await BiometricService.instance
          .canAuthenticate();
      if (mounted) {
        context.read<AppSettingsBloc>().add(
          UpdateBiometricSupport(isBiometricSupported),
        );
      }

      return repository;
    } finally {
      // Drop the native splash screen regardless of outcome so Flutter can render
      // the fake splash, the error screen, or the app.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }
  }

  /// Builds the provider stack that wires [repository] into the widget tree
  /// and resolves the root screen from [settingsState].
  Widget _buildAppContent(
    WeightRepository repository,
    AppSettingsState settingsState,
  ) {
    return RepositoryProvider.value(
      value: repository,
      child: BlocProvider(
        create: (context) {
          final settingsBloc = context.read<AppSettingsBloc>();
          final bloc = WeightBloc(
            repository: context.read<WeightRepository>(),
            appSettingsBloc: settingsBloc,
            healthService: widget.healthServiceOverride,
          )..add(const SubscribeToWeightChanges());
          // Pull in records recorded in Apple Health / Health Connect (e.g.
          // by a smart scale) since the last session when the user already
          // enabled health sync; the pull itself is gated inside the BLoC.
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
              child: !settingsState.isOnboardingCompleted
                  ? const OnboardingWizardScreen()
                  : const MainNavigationScreen(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          builder: (context, child) {
            return Stack(
              children: [
                ?child,
                if (settingsState.isLocked)
                  const Positioned.fill(child: BiometricShieldScreen()),
              ],
            );
          },
          home: widget.repositoryOverride != null
              ? _buildAppContent(widget.repositoryOverride!, settingsState)
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
                      return _buildAppContent(snapshot.data!, settingsState);
                    }
                  },
                ),
        );
      },
    );
  }
}

/// A widget that registers the [BiometricLockObserver] once the [WeightBloc]
/// provider is in scope.
///
/// Lives below the BlocProvider so the observer can resolve the weight BLoC
/// dynamically through its own context instead of capturing a direct instance
/// reference, which could go stale if the provider is ever recreated.
class _ObserverRegistrar extends StatefulWidget {
  /// Resolves the localized biometric authentication prompt reason.
  final String Function() localizedReason;

  /// The subtree rendered below the app-level providers.
  final Widget child;

  /// Creates an [_ObserverRegistrar] with [localizedReason] and [child].
  const _ObserverRegistrar({
    required this.localizedReason,
    required this.child,
  });

  @override
  State<_ObserverRegistrar> createState() => _ObserverRegistrarState();
}

/// State owning the [BiometricLockObserver] lifecycle and initial lock state.
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

/// A widget that dispatches [SyncHealthEntries] when the app returns to the
/// foreground and health sync is enabled.
///
/// Lives below the BlocProvider so the observer can resolve the weight and
/// settings BLoCs dynamically through its own context instead of capturing
/// direct instance references, which could go stale if the providers are ever
/// recreated. Entries recorded in Apple Health / Health Connect while the app
/// was backgrounded are thereby pulled in without any user action.
class _HealthSyncLifecycleObserver extends StatefulWidget {
  /// The subtree rendered below the app-level providers.
  final Widget child;

  /// Creates a [_HealthSyncLifecycleObserver] wrapping [child].
  const _HealthSyncLifecycleObserver({required this.child});

  @override
  State<_HealthSyncLifecycleObserver> createState() =>
      _HealthSyncLifecycleObserverState();
}

/// State owning the WidgetsBindingObserver registration for foreground sync.
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
  /// Child rendered below the [AppLocalizations] scope.
  final Widget child;

  /// Invoked with the active [AppLocalizations] whenever it is resolved or
  /// the locale changes.
  final void Function(AppLocalizations l10n) onLocalized;

  const _LocalizationSync({required this.child, required this.onLocalized});

  @override
  State<_LocalizationSync> createState() => _LocalizationSyncState();
}

/// State that forwards each locale change to [onLocalized].
class _LocalizationSyncState extends State<_LocalizationSync> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.onLocalized(AppLocalizations.of(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
