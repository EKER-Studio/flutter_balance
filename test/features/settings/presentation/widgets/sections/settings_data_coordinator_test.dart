import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/sections/settings_data_coordinator.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/l10n/app_localizations.dart';

class MockAppSettingsBloc extends MockBloc<AppSettingsEvent, AppSettingsState>
    implements AppSettingsBloc {}

class MockWeightBloc extends MockBloc<WeightEvent, WeightState>
    implements WeightBloc {}

void main() {
  late MockAppSettingsBloc settingsBloc;
  late MockWeightBloc weightBloc;

  setUpAll(() {
    registerFallbackValue(const UpdateBiometricLock(false));
  });

  setUp(() {
    settingsBloc = MockAppSettingsBloc();
    weightBloc = MockWeightBloc();

    when(() => settingsBloc.state).thenReturn(const AppSettingsState());
    when(() => weightBloc.state).thenReturn(WeightInitial());
  });

  Widget buildTestableWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
        BlocProvider<WeightBloc>.value(value: weightBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  group('SettingsDataCoordinator', () {
    testWidgets(
      'handleBiometricToggle with false dispatches UpdateBiometricLock(false)',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      SettingsDataCoordinator.handleBiometricToggle(
                        context,
                        false,
                      ),
                  child: const Text('Toggle Off'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Toggle Off'));
        await tester.pumpAndSettle();

        verify(
          () => settingsBloc.add(const UpdateBiometricLock(false)),
        ).called(1);
      },
    );

    testWidgets('showBmiLegendDialog presents BmiLegendDialog', (tester) async {
      final entries = [
        WeightEntry(id: 1, weightKg: 78.5, dateTime: DateTime(2026, 1, 1)),
      ];
      when(
        () => weightBloc.state,
      ).thenReturn(WeightLoaded(entries: entries, filteredEntries: entries));

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () =>
                    SettingsDataCoordinator.showBmiLegendDialog(context),
                child: const Text('Show Legend'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Legend'));
      await tester.pumpAndSettle();

      expect(find.byType(BmiLegendDialog), findsOneWidget);
    });
  });
}
