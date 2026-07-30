import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/widgets/latest_measurement_card.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockHydratedStorage storage;
  late AppSettingsBloc settingsBloc;

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    settingsBloc = AppSettingsBloc();
  });

  Widget createTestWidget(Widget child) {
    return BlocProvider<AppSettingsBloc>.value(
      value: settingsBloc,
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

  testWidgets('renders empty state when latestEntry is null', (tester) async {
    await tester.pumpWidget(
      createTestWidget(const LatestMeasurementCard(latestEntry: null)),
    );

    expect(
      find.text('No entries yet. Add your first measurement below!'),
      findsOneWidget,
    );
  });

  testWidgets('renders formatted weight, today timestamp, and triggers onTap', (
    tester,
  ) async {
    var tapped = false;
    final entry = WeightEntry(id: 1, weightKg: 75.4, dateTime: DateTime.now());

    await tester.pumpWidget(
      createTestWidget(
        LatestMeasurementCard(latestEntry: entry, onTap: () => tapped = true),
      ),
    );

    expect(find.text('Latest measurement'), findsOneWidget);
    expect(find.text('75.4'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });

  testWidgets('formats weight in imperial units (lb)', (tester) async {
    settingsBloc.emit(
      settingsBloc.state.copyWith(measurementUnit: MeasurementUnit.imperial),
    );

    final entry = WeightEntry(
      id: 1,
      weightKg: 70.0, // ~154.3 lb
      dateTime: DateTime(2026, 7, 10, 8, 30),
    );

    await tester.pumpWidget(
      createTestWidget(LatestMeasurementCard(latestEntry: entry)),
    );

    expect(find.text('154.3'), findsOneWidget);
    expect(find.text('lb'), findsOneWidget);
  });
}
