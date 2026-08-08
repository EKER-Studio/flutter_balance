import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/app.dart';
import 'package:balance/core/services/health_service.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockHealthService extends Mock implements HealthService {}

void main() {
  late MockWeightRepository repository;
  late MockHydratedStorage storage;

  setUp(() {
    repository = MockWeightRepository();
    storage = MockHydratedStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    when(
      () => repository.watchAllEntries(),
    ).thenAnswer((_) => Stream.value(<WeightEntry>[]));
  });

  testWidgets(
    'App renders OnboardingWizardScreen when onboarding is not completed',
    (tester) async {
      final settingsBloc = AppSettingsBloc();

      await tester.pumpWidget(
        BlocProvider<AppSettingsBloc>.value(
          value: settingsBloc,
          child: App(repositoryOverride: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 7'), findsOneWidget);
      expect(find.text('Units & Height'), findsOneWidget);

      settingsBloc.close();
    },
  );

  testWidgets('App renders MainNavigationScreen when onboarding is completed', (
    tester,
  ) async {
    final settingsBloc = AppSettingsBloc();
    settingsBloc.add(const CompleteOnboarding());

    await tester.pumpWidget(
      BlocProvider<AppSettingsBloc>.value(
        value: settingsBloc,
        child: App(repositoryOverride: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    settingsBloc.close();
  });

  testWidgets(
    'App navigates back to OnboardingWizardScreen when app settings are reset',
    (tester) async {
      final settingsBloc = AppSettingsBloc();

      // 1. Arrange: Start with completed onboarding
      settingsBloc.add(const CompleteOnboarding());

      await tester.pumpWidget(
        BlocProvider<AppSettingsBloc>.value(
          value: settingsBloc,
          child: App(repositoryOverride: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure we are on the main screen
      expect(find.byType(NavigationBar), findsOneWidget);

      // 2. Act: Reset app settings (simulating "Wipe Data")
      settingsBloc.add(const ResetAppSettings());
      await tester.pumpAndSettle();

      // 3. Assert: Verify we are back on the Onboarding Screen
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Step 1 of 7'), findsOneWidget);
      expect(find.text('Units & Height'), findsOneWidget);

      settingsBloc.close();
    },
  );

  group('Health sync on app start and resume', () {
    MockHealthService healthServiceWithEntries() {
      final healthService = MockHealthService();
      when(
        () => healthService.fetchWeightHistory(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer(
        (_) async => [
          WeightEntry(weightKg: 76.5, dateTime: DateTime(2026, 1, 5)),
        ],
      );
      return healthService;
    }

    void stubRepositoryForSync() {
      when(() => repository.getAllEntries()).thenAnswer((_) async => []);
      when(
        () => repository.bulkImportEntries(any()),
      ).thenAnswer((_) async => 1);
    }

    testWidgets(
      'App dispatches SyncHealthEntries at startup when health sync was '
      'persisted as enabled',
      (tester) async {
        when(
          () => storage.read('AppSettingsBloc'),
        ).thenReturn({'isHealthSyncEnabled': true});
        final settingsBloc = AppSettingsBloc();
        final healthService = healthServiceWithEntries();
        stubRepositoryForSync();

        await tester.pumpWidget(
          BlocProvider<AppSettingsBloc>.value(
            value: settingsBloc,
            child: App(
              repositoryOverride: repository,
              healthServiceOverride: healthService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final imported =
            verify(
                  () => repository.bulkImportEntries(captureAny()),
                ).captured.single
                as List<WeightEntry>;
        expect(imported.single.weightKg, 76.5);
        expect(imported.single.dateTime, DateTime(2026, 1, 5));

        settingsBloc.close();
      },
    );

    testWidgets(
      'App does not dispatch SyncHealthEntries at startup when health sync '
      'is disabled',
      (tester) async {
        final settingsBloc = AppSettingsBloc();
        final healthService = healthServiceWithEntries();
        stubRepositoryForSync();

        await tester.pumpWidget(
          BlocProvider<AppSettingsBloc>.value(
            value: settingsBloc,
            child: App(
              repositoryOverride: repository,
              healthServiceOverride: healthService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        verifyNever(() => repository.bulkImportEntries(any()));

        settingsBloc.close();
      },
    );

    testWidgets(
      'App pulls health entries again when resumed with sync enabled',
      (tester) async {
        when(
          () => storage.read('AppSettingsBloc'),
        ).thenReturn({'isHealthSyncEnabled': true});
        final settingsBloc = AppSettingsBloc();
        final healthService = healthServiceWithEntries();
        stubRepositoryForSync();

        await tester.pumpWidget(
          BlocProvider<AppSettingsBloc>.value(
            value: settingsBloc,
            child: App(
              repositoryOverride: repository,
              healthServiceOverride: healthService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Background and resume the app; the lifecycle observer must pull
        // again, importing the entry a second time.
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pumpAndSettle();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        verify(
          () => healthService.fetchWeightHistory(
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).called(2);
        // Counts the startup import and the resume import (mocktail counts
        // only unverified calls, so no intermediate verify() may precede).
        verify(() => repository.bulkImportEntries(any())).called(2);

        settingsBloc.close();
      },
    );
  });
}
