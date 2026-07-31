import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/core/services/biometric_lock_observer.dart';
import 'package:pure_weight/core/services/notification_service.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:pure_weight/presentation/screens/biometric_shield_screen.dart';
import 'package:pure_weight/presentation/screens/main_navigation_screen.dart';
import 'package:pure_weight/presentation/theme/app_theme.dart';

/// Root widget of the PureWeight application.
class App extends StatefulWidget {
  /// The [WeightRepository] backing the application.
  final WeightRepository repository;

  /// Creates an [App] with the given [repository].
  const App({super.key, required this.repository});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  BiometricLockObserver? _observer;

  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    final settingsBloc = context.read<AppSettingsBloc>();
    if (settingsBloc.state.isBiometricLockEnabled) {
      settingsBloc.add(const SetLocked(true));
    }
    _observer = BiometricLockObserver(
      isBiometricLockEnabled: () => settingsBloc.state.isBiometricLockEnabled,
      lockEnabledStream: settingsBloc.stream.map(
        (s) => s.isBiometricLockEnabled,
      ),
      onLockStateChanged: (locked) => settingsBloc.add(SetLocked(locked)),
      localizedReason: () => _l10n.biometricAuthReason,
    );
  }

  @override
  void dispose() {
    _observer?.removeThisObserver();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: widget.repository,
      child: BlocProvider(
        create: (context) =>
            WeightBloc(repository: context.read<WeightRepository>())
              ..add(const SubscribeToWeightChanges()),
        child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
          builder: (context, settingsState) {
            final themeMode = switch (settingsState.themeMode) {
              AppThemeMode.system => ThemeMode.system,
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
            };
            return MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: _LocalizationSync(
                onLocalized: (l10n) {
                  _l10n = l10n;
                  NotificationService.instance.setLocalizedTexts(
                    title: l10n.notificationReminderTitle,
                    body: l10n.notificationReminderBody,
                    channelName: l10n.notificationChannelName,
                    channelDescription: l10n.notificationChannelDescription,
                  );
                },
                child: settingsState.isLocked
                    ? const BiometricShieldScreen()
                    : const MainNavigationScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
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
