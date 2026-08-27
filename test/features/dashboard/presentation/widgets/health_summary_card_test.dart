import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/dashboard/presentation/widgets/sections/health_summary_card.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/widgets/components/target_weight_sheet.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_dialog.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockHydratedStorage storage;

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
  });

  Widget createTestWidget(Widget child, AppSettingsBloc bloc) {
    return BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders goal and BMI details from app settings', (tester) async {
    final bloc = AppSettingsBloc();
    bloc.add(const UpdateHeight(180));
    bloc.add(const TargetWeightChanged(70.0));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      createTestWidget(const HealthSummaryCard(latestWeightKg: 72.0), bloc),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('BMI'), findsAtLeastNWidgets(1));
    expect(find.text('Remaining: 2.0 kg'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    bloc.add(const TargetWeightChanged(68.0));
    await tester.pumpAndSettle();

    expect(find.text('Remaining: 4.0 kg'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('formats the goal in imperial units', (tester) async {
    final bloc = AppSettingsBloc();
    bloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));
    bloc.add(const TargetWeightChanged(70.0));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      createTestWidget(const HealthSummaryCard(latestWeightKg: 75.0), bloc),
    );
    await tester.pumpAndSettle();

    expect(find.text('Remaining: 11.0 lb'), findsOneWidget);
  });

  testWidgets(
    'renders Goal Achieved status when latestWeight <= targetWeight',
    (tester) async {
      final bloc = AppSettingsBloc();
      bloc.add(const TargetWeightChanged(75.0));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        createTestWidget(const HealthSummaryCard(latestWeightKg: 70.0), bloc),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Goal achieved!'), findsOneWidget);
    },
  );

  testWidgets('opens TargetWeightSheet on goal button tap', (tester) async {
    final bloc = AppSettingsBloc();
    bloc.add(
      const TargetWeightChanged(70.0),
    ); // Ensure button exists and is not achieved
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      createTestWidget(const HealthSummaryCard(latestWeightKg: 72.0), bloc),
    );
    await tester.pumpAndSettle();

    // Tapping the remaining-weight text resolves to its InkWell row.
    await tester.tap(find.text('Remaining: 2.0 kg'));
    await tester.pumpAndSettle();

    expect(find.byType(TargetWeightSheet), findsOneWidget);
  });

  testWidgets('opens BmiLegendDialog on BMI badge tap', (tester) async {
    final bloc = AppSettingsBloc();
    bloc.add(const UpdateHeight(180));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      createTestWidget(const HealthSummaryCard(latestWeightKg: 72.0), bloc),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.ancestor(of: find.text('BMI 22.2'), matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BmiLegendDialog), findsOneWidget);
  });

  testWidgets('clears the target weight when dialog goal is removed', (
    tester,
  ) async {
    final bloc = AppSettingsBloc();
    bloc.add(const TargetWeightChanged(70.0));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      createTestWidget(const HealthSummaryCard(latestWeightKg: 72.0), bloc),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remaining: 2.0 kg'));
    await tester.pumpAndSettle();
    expect(find.byType(TargetWeightSheet), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(bloc.state.targetWeight, isNull);
    expect(find.text('Remaining: 2.0 kg'), findsNothing);
    expect(find.text('Goal: Not set'), findsOneWidget);
    expect(find.text('Set goal'), findsOneWidget);
  });

  testWidgets(
    'renders unset goal prompt and opens sheet on tap when no target set',
    (tester) async {
      final bloc = AppSettingsBloc();

      await tester.pumpWidget(
        createTestWidget(const HealthSummaryCard(latestWeightKg: 72.0), bloc),
      );
      await tester.pumpAndSettle();

      expect(find.text('Goal: Not set'), findsOneWidget);
      expect(find.text('Set goal'), findsOneWidget);

      await tester.tap(find.text('Set goal'));
      await tester.pumpAndSettle();

      expect(find.byType(TargetWeightSheet), findsOneWidget);
    },
  );

  testWidgets('saves a new metric target weight from the dialog', (
    tester,
  ) async {
    final bloc = AppSettingsBloc();
    bloc.add(const TargetWeightChanged(70.0));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      createTestWidget(const HealthSummaryCard(latestWeightKg: 72.0), bloc),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remaining: 2.0 kg'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '65');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(bloc.state.targetWeight, closeTo(65.0, 0.001));
  });

  testWidgets('saves a new imperial target weight converted to kg', (
    tester,
  ) async {
    final bloc = AppSettingsBloc();
    bloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));
    bloc.add(const TargetWeightChanged(70.0));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      createTestWidget(const HealthSummaryCard(latestWeightKg: 75.0), bloc),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remaining: 11.0 lb'));
    await tester.pumpAndSettle();
    expect(find.byType(TargetWeightSheet), findsOneWidget);
    expect(find.textContaining('154.3'), findsWidgets);

    await tester.enterText(find.byType(TextField), '165.3');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(bloc.state.targetWeight, closeTo(75.0, 0.05));
  });

  testWidgets('formats an older last-updated timestamp as date and time', (
    tester,
  ) async {
    final bloc = AppSettingsBloc();

    await tester.pumpWidget(
      createTestWidget(
        HealthSummaryCard(
          latestWeightKg: 72.0,
          lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
        ),
        bloc,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(', '), findsOneWidget);
  });

  testWidgets('formats a today last-updated timestamp with the time only', (
    tester,
  ) async {
    final bloc = AppSettingsBloc();

    await tester.pumpWidget(
      createTestWidget(
        HealthSummaryCard(latestWeightKg: 72.0, lastUpdated: DateTime.now()),
        bloc,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Today, '), findsOneWidget);
  });
}
