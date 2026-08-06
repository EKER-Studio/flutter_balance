import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/weight/presentation/widgets/health_summary_card.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';
import 'package:balance/presentation/widgets/target_weight_dialog.dart';

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
    bloc.add(const UpdateHeight(180)); // Set height to calculate BMI
    bloc.add(
      const TargetWeightChanged(70.0),
    ); // Add a target weight so goal section shows
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      createTestWidget(const HealthSummaryCard(latestWeightKg: 72.0), bloc),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('BMI'), findsAtLeastNWidgets(1));
    expect(find.text('Remaining: 2.0 kg'), findsOneWidget);

    bloc.add(const TargetWeightChanged(68.0));
    await tester.pumpAndSettle();

    expect(find.text('Remaining: 4.0 kg'), findsOneWidget);
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

      expect(find.text('Goal achieved!'), findsOneWidget);
    },
  );

  testWidgets('opens TargetWeightDialog on goal button tap', (tester) async {
    final bloc = AppSettingsBloc();
    bloc.add(
      const TargetWeightChanged(70.0),
    ); // Ensure button exists and is not achieved
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      createTestWidget(const HealthSummaryCard(latestWeightKg: 72.0), bloc),
    );
    await tester.pumpAndSettle();

    // The remaining text might be inside a RichText or Row, but find.text usually works.
    // However, if we just tap the InkWell that contains 'Remaining: 2.0 kg' it works.
    await tester.tap(find.text('Remaining: 2.0 kg'));
    await tester.pumpAndSettle();

    expect(find.byType(TargetWeightDialog), findsOneWidget);
  });
}
