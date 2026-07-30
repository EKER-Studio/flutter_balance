import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/features/weight/presentation/screens/statistics_screen.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockWeightRepository repository;
  late MockHydratedStorage storage;

  setUp(() {
    repository = MockWeightRepository();
    storage = MockHydratedStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  Widget buildSubject({
    required AppSettingsBloc settingsBloc,
    required WeightBloc weightBloc,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settingsBloc),
        BlocProvider.value(value: weightBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('pl'),
        home: StatisticsScreen(),
      ),
    );
  }

  testWidgets('StatisticsScreen renders empty state when no entries exist', (
    tester,
  ) async {
    when(() => repository.watchAllEntries())
        .thenAnswer((_) => Stream.value(<WeightEntry>[]));

    final settingsBloc = AppSettingsBloc();
    final weightBloc = WeightBloc(repository: repository)
      ..add(const SubscribeToWeightChanges());

    await tester.pumpWidget(
      buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
    );
    await tester.pumpAndSettle();

    expect(find.text('Statystyki'), findsOneWidget);
    expect(find.text('Seria ważenia'), findsOneWidget);
    expect(find.text('Regularność w miesiącu'), findsOneWidget);
    expect(find.text('0 dni'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Najniższa'), findsOneWidget);
    expect(find.text('Najwyższa'), findsOneWidget);
    expect(find.text('Całkowita zmiana'), findsOneWidget);
    expect(find.text('BMI'), findsOneWidget);
  });

  testWidgets('StatisticsScreen displays calculated metrics and Bento Grid when entries exist', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = [
      WeightEntry(
        id: 1,
        weightKg: 80.0,
        dateTime: now.subtract(const Duration(days: 2)),
      ),
      WeightEntry(
        id: 2,
        weightKg: 75.0,
        dateTime: now.subtract(const Duration(days: 1)),
      ),
      WeightEntry(
        id: 3,
        weightKg: 74.0,
        dateTime: now,
      ),
    ];

    when(() => repository.watchAllEntries())
        .thenAnswer((_) => Stream.value(entries));

    final settingsBloc = AppSettingsBloc()..add(const UpdateHeight(180));
    final weightBloc = WeightBloc(repository: repository)
      ..add(const SubscribeToWeightChanges());

    await tester.pumpWidget(
      buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
    );
    await tester.pumpAndSettle();

    // Check lowest weight (74.0)
    expect(find.text('74.0'), findsOneWidget);
    // Check highest weight (80.0)
    expect(find.text('80.0'), findsOneWidget);
    // Check net progress (-6.0)
    expect(find.text('-6.0'), findsOneWidget);
    // Check trend percentage change badge (-7.5%)
    expect(find.text('-7.5%'), findsOneWidget);
  });

  testWidgets('StatisticsScreen updates metrics when unit is changed to imperial', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = [
      WeightEntry(
        id: 1,
        weightKg: 70.0,
        dateTime: now,
      ),
    ];

    when(() => repository.watchAllEntries())
        .thenAnswer((_) => Stream.value(entries));

    final settingsBloc = AppSettingsBloc();
    final weightBloc = WeightBloc(repository: repository)
      ..add(const SubscribeToWeightChanges());

    await tester.pumpWidget(
      buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
    );
    await tester.pumpAndSettle();

    expect(find.text('70.0'), findsWidgets);

    // Switch to imperial units
    settingsBloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));
    await tester.pumpAndSettle();

    // 70.0 kg is ~154.3 lb
    expect(find.text('154.3'), findsWidgets);
    expect(find.text('lb'), findsWidgets);
  });
}
