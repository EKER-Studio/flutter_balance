import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/screens/weight_dashboard_screen.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:pure_weight/presentation/theme/app_theme.dart';

/// Root widget of the PureWeight application.
class App extends StatelessWidget {
  /// The [WeightRepository] backing the application.
  final WeightRepository repository;

  /// Creates an [App] with the given [repository].
  const App({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
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
              title: AppLocalizations.of(context).appTitle,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const WeightDashboardScreen(),
            );
          },
        ),
      ),
    );
  }
}
