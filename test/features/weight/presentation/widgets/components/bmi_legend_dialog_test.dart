import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

class MockAppSettingsBloc extends MockBloc<AppSettingsEvent, AppSettingsState>
    implements AppSettingsBloc {}

class MockWeightBloc extends MockBloc<WeightEvent, WeightState>
    implements WeightBloc {}

void main() {
  late MockAppSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSettingsBloc = MockAppSettingsBloc();
    when(() => mockSettingsBloc.state).thenReturn(const AppSettingsState());
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    AppSettingsState? state,
  }) async {
    if (state != null) {
      when(() => mockSettingsBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      BlocProvider<AppSettingsBloc>.value(
        value: mockSettingsBloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const BmiLegendDialog(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders title and all six BMI category legend rows', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('BMI Categories'), findsOneWidget);

    expect(find.text('Underweight'), findsOneWidget);
    expect(find.text('< 18.5'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('18.5 – 24.9'), findsOneWidget);
    expect(find.text('Overweight'), findsOneWidget);
    expect(find.text('25.0 – 29.9'), findsOneWidget);
    expect(find.text('Obesity class I'), findsOneWidget);
    expect(find.text('30.0 – 34.9'), findsOneWidget);
    expect(find.text('Obesity class II'), findsOneWidget);
    expect(find.text('35.0 – 39.9'), findsOneWidget);
    expect(find.text('Obesity class III'), findsOneWidget);
    expect(find.text('≥ 40.0'), findsOneWidget);
  });

  testWidgets('renders a colored swatch per legend row', (tester) async {
    await pumpDialog(tester);

    final swatches = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(BmiLegendDialog),
            matching: find.byType(Container),
          ),
        )
        .where(
          (c) =>
              c.constraints?.maxWidth == 18 && c.constraints?.maxHeight == 18,
        )
        .toList();
    expect(swatches, hasLength(6));

    for (final swatch in swatches) {
      final decoration = swatch.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(5));
      expect(decoration.border, isNotNull);
    }
  });

  testWidgets('shows healthy weight range when height is configured', (
    tester,
  ) async {
    // Height: 180 cm -> 18.5 * 1.8^2 = 59.9 kg, 24.9 * 1.8^2 = 80.7 kg
    await pumpDialog(
      tester,
      state: const AppSettingsState(
        height: 180.0,
        measurementUnit: MeasurementUnit.metric,
      ),
    );

    expect(find.text('Healthy weight range'), findsOneWidget);
    expect(find.text('59.9 – 80.7 kg'), findsOneWidget);
  });

  testWidgets('shows healthy weight range in lb in imperial mode', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      state: const AppSettingsState(
        height: 180.0,
        measurementUnit: MeasurementUnit.imperial,
      ),
    );

    expect(find.text('Healthy weight range'), findsOneWidget);
    expect(find.textContaining('lb'), findsOneWidget);
  });

  testWidgets('OK button closes the dialog', (tester) async {
    await pumpDialog(tester);

    expect(find.byType(BmiLegendDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(BmiLegendDialog), findsNothing);
  });

  testWidgets('highlights user current BMI category with your result badge', (
    tester,
  ) async {
    final mockWeightBloc = MockWeightBloc();
    when(() => mockWeightBloc.state).thenReturn(
      WeightLoaded(
        entries: [
          WeightEntry(id: 1, weightKg: 86.5, dateTime: DateTime(2026, 8, 25)),
        ],
        filteredEntries: [],
      ),
    );

    when(() => mockSettingsBloc.state).thenReturn(
      const AppSettingsState(
        height: 177.0,
        measurementUnit: MeasurementUnit.metric,
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppSettingsBloc>.value(value: mockSettingsBloc),
          BlocProvider<WeightBloc>.value(value: mockWeightBloc),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const BmiLegendDialog(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Your result'), findsOneWidget);
  });
}
