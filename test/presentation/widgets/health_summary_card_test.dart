import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/measurement_unit.dart';
import 'package:pure_weight/presentation/widgets/health_summary_card.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockHydratedStorage storage;

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
  });

  testWidgets('renders goal and BMI details from app settings', (tester) async {
    final bloc = AppSettingsBloc();

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HealthSummaryCard(latestWeightKg: 72.0)),
        ),
      ),
    );

    expect(find.text('Goal not set'), findsOneWidget);
    expect(find.textContaining('BMI'), findsAtLeastNWidgets(1));

    bloc.add(const TargetWeightChanged(70.0));
    await tester.pump();

    expect(find.text('2.0 kg to target'), findsOneWidget);
  });

  testWidgets('formats the goal in imperial units', (tester) async {
    final bloc = AppSettingsBloc();
    bloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));
    bloc.add(const TargetWeightChanged(154.3));
    await tester.pump();

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HealthSummaryCard(latestWeightKg: 160.0)),
        ),
      ),
    );

    expect(find.text('12.6 lb to target'), findsOneWidget);
    expect(find.text('Target: 340.2 lbs'), findsOneWidget);
  });
}
