import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pure_weight/core/database/database_module.dart';
import 'package:pure_weight/core/services/biometric_lock_observer.dart';
import 'package:pure_weight/core/services/biometric_service.dart';
import 'package:pure_weight/core/services/notification_service.dart';
import 'package:pure_weight/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:pure_weight/presentation/screens/app_initialization_error_screen.dart';
import 'package:pure_weight/presentation/screens/app_splash_screen.dart';
import 'package:pure_weight/presentation/screens/biometric_shield_screen.dart';
import 'package:pure_weight/presentation/screens/main_navigation_screen.dart';
import 'package:pure_weight/presentation/screens/onboarding/onboarding_wizard_screen.dart';
import 'package:pure_weight/presentation/theme/app_theme.dart';

/// Root widget of the PureWeight application.
class App extends StatefulWidget {
  /// Optional repository override for testing.
  final WeightRepository? repositoryOverride;

  /// Creates the root [App] widget.
  const App({super.key, this.repositoryOverride});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late AppLocalizations _l10n;
  late Future<WeightRepository> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

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

      // 2. Notifications
      await NotificationService.instance.initialize();

      // 3. Biometrics
      final isBiometricSupported = await BiometricService.instance
          .isAvailable();
      if (mounted) {
        context.read<AppSettingsBloc>().add(
          UpdateBiometricSupport(isBiometricSupported),
        );
      }

      return repository;
    } finally {
      // Regardless of success or failure, we drop the OS native splash screen
      // so Flutter can render either the fake splash, error screen, or the app.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }
  }

  Widget _buildAppContent(WeightRepository repository, AppSettingsState settingsState) {
    return RepositoryProvider.value(
      value: repository,
      child: BlocProvider(
        create: (context) => WeightBloc(repository: context.read<WeightRepository>())
          ..add(const SubscribeToWeightChanges()),
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
                : (settingsState.isLocked
                    ? const BiometricShieldScreen()
                    : const MainNavigationScreen()),
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
          home: widget.repositoryOverride != null 
              ? _buildAppContent(widget.repositoryOverride!, settingsState)
              : FutureBuilder<WeightRepository>(
                  future: _initFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppSplashScreen();
                    } else if (snapshot.hasError) {
                      return AppInitializationErrorScreen(
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

/// Registers the [BiometricLockObserver] once the [WeightBloc] provider is in scope.
///
/// Lives below the [BlocProvider] so the observer can resolve the weight BLoC
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

/// Synchronizes the active locale with services that live outside the widget tree.
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

class _LocalizationSyncState extends State<_LocalizationSync> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.onLocalized(AppLocalizations.of(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
