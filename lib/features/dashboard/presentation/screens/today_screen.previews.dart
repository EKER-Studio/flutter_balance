import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/features/dashboard/presentation/screens/today_screen.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Shows the Today screen with realistic demo data in the light theme.
@Preview(
  name: 'Today Screen - Light',
  group: 'Balance Screens',
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget todayScreenLightPreview() => _todayScreenPreview();

/// Shows the Today screen with realistic demo data in the dark theme.
@Preview(
  name: 'Today Screen - Dark',
  group: 'Balance Screens',
  brightness: Brightness.dark,
  wrapper: darkPreviewWrapper,
)
Widget todayScreenDarkPreview() => _todayScreenPreview();

/// Applies the application's light theme and localization to a preview.
Widget lightPreviewWrapper(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.light,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

/// Applies the application's dark theme and localization to a preview.
Widget darkPreviewWrapper(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.dark,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

Widget _todayScreenPreview() => MultiBlocProvider(
  providers: [
    BlocProvider<AppSettingsBloc>.value(
      value: _PreviewAppSettingsBloc(
        const AppSettingsState(height: 173, targetWeight: 72),
      ),
    ),
    BlocProvider<WeightBloc>.value(
      value: _PreviewWeightBloc(_demoWeightState()),
    ),
  ],
  child: const TodayScreen(),
);

WeightState _demoWeightState() {
  final now = DateTime.now();
  final entries = List.generate(14, (index) {
    final date = now.subtract(Duration(days: index));
    return WeightEntry(
      id: index + 1,
      weightKg: 76.4 - index * 0.12 + (index.isOdd ? 0.03 : 0),
      dateTime: DateTime(date.year, date.month, date.day, 7, 30),
      note: index == 0 ? 'Morning check-in' : null,
    );
  });
  return WeightLoaded(
    heightCm: 173,
    timePeriod: TimePeriod.week,
    entries: entries,
    filteredEntries: entries.take(7).toList(),
  );
}

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
