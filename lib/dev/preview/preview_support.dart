import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Wraps a preview in the application's light theme and English localization.
Widget lightPreviewWrapper(Widget child) => _previewApp(child, ThemeMode.light);

/// Wraps a preview in the application's dark theme and English localization.
Widget darkPreviewWrapper(Widget child) => _previewApp(child, ThemeMode.dark);

Widget _previewApp(Widget child, ThemeMode themeMode) => MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: themeMode,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

/// Provides state-only BLoC doubles to screens rendered by widget previews.
Widget withDashboardPreviewBlocs({
  required Widget child,
  required AppSettingsState settingsState,
  required WeightState weightState,
}) => MultiBlocProvider(
  providers: [
    BlocProvider<AppSettingsBloc>.value(
      value: _PreviewAppSettingsBloc(settingsState),
    ),
    BlocProvider<WeightBloc>.value(value: _PreviewWeightBloc(weightState)),
  ],
  child: child,
);

class _PreviewAppSettingsBloc implements AppSettingsBloc {
  _PreviewAppSettingsBloc(this.state);

  @override
  final AppSettingsState state;

  @override
  Stream<AppSettingsState> get stream => const Stream.empty();

  @override
  void add(AppSettingsEvent event) {}

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PreviewWeightBloc implements WeightBloc {
  _PreviewWeightBloc(this.state);

  @override
  final WeightState state;

  @override
  Stream<WeightState> get stream => const Stream.empty();

  @override
  void add(WeightEvent event) {}

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
