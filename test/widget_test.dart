import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:balance/app.dart';
import 'package:balance/core/database/database_module.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/presentation/screens/app_initialization_error_screen.dart';
import 'package:balance/core/presentation/screens/app_splash_screen.dart';
import 'package:balance/core/presentation/screens/biometric_shield_screen.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/navigation/presentation/screens/main_navigation_screen.dart';

/// A test double that points [getApplicationDocumentsDirectory] at a
/// temporary directory so [DatabaseModule.initialize] runs fully on disk.
class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.fileSystemPath);

  final String fileSystemPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => fileSystemPath;

  @override
  Future<String?> getApplicationSupportPath() async => fileSystemPath;

  @override
  Future<String?> getTemporaryPath() async => fileSystemPath;
}

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockHealthService extends Mock implements HealthService {}

void main() {
  late MockWeightRepository repository;
  late MockHydratedStorage storage;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

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

  Future<void> pumpForInitialization(
    WidgetTester tester,
    bool Function() until,
  ) async {
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump(const Duration(milliseconds: 250));
      if (until()) return;
    }
  }

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
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Welcome to Balance'), findsOneWidget);
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

    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    settingsBloc.close();
  });

  testWidgets(
    'App navigates back to OnboardingWizardScreen when app settings are reset',
    (tester) async {
      final settingsBloc = AppSettingsBloc();

      settingsBloc.add(const CompleteOnboarding());

      await tester.pumpWidget(
        BlocProvider<AppSettingsBloc>.value(
          value: settingsBloc,
          child: App(repositoryOverride: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScreen), findsOneWidget);

      settingsBloc.add(const ResetAppSettings());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MainNavigationScreen), findsNothing);
      expect(find.text('Welcome to Balance'), findsOneWidget);
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
        () => repository.syncRemoteEntries(any()),
      ).thenAnswer((_) async => 1);
    }

    testWidgets(
      'App dispatches SyncHealthEntries at startup when health sync was persisted as enabled',
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
        await tester.pump(const Duration(milliseconds: 300));

        final imported =
            verify(
                  () => repository.syncRemoteEntries(captureAny()),
                ).captured.single
                as List<WeightEntry>;
        expect(imported.single.weightKg, 76.5);
        expect(imported.single.dateTime, DateTime(2026, 1, 5));

        settingsBloc.close();
      },
    );

    testWidgets(
      'App does not dispatch SyncHealthEntries at startup when health sync is disabled',
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
        await tester.pump(const Duration(milliseconds: 300));

        verifyNever(() => repository.syncRemoteEntries(any()));

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
        await tester.pump(const Duration(milliseconds: 300));

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
        verify(() => repository.syncRemoteEntries(any())).called(2);

        settingsBloc.close();
      },
    );
  });

  group('App theme modes', () {
    late AppSettingsBloc settingsBloc;

    setUp(() {
      settingsBloc = AppSettingsBloc();
    });

    tearDown(() {
      settingsBloc.close();
    });

    Future<void> pumpWithTheme(WidgetTester tester, AppThemeMode mode) async {
      settingsBloc.add(UpdateTheme(mode));
      await tester.pumpWidget(
        BlocProvider<AppSettingsBloc>.value(
          value: settingsBloc,
          child: App(repositoryOverride: repository),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('uses ThemeMode.light for AppThemeMode.light', (tester) async {
      await pumpWithTheme(tester, AppThemeMode.light);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.light);
    });

    testWidgets('uses ThemeMode.dark for AppThemeMode.dark', (tester) async {
      await pumpWithTheme(tester, AppThemeMode.dark);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
    });
  });

  group('App biometric shield', () {
    late AppSettingsBloc settingsBloc;

    tearDown(() {
      settingsBloc.close();
    });

    testWidgets('locks the app at startup when biometric lock is enabled', (
      tester,
    ) async {
      when(
        () => storage.read('AppSettingsBloc'),
      ).thenReturn({'isBiometricLockEnabled': true});
      settingsBloc = AppSettingsBloc();

      await tester.pumpWidget(
        BlocProvider<AppSettingsBloc>.value(
          value: settingsBloc,
          child: App(repositoryOverride: repository),
        ),
      );

      await pumpForInitialization(
        tester,
        () => !BiometricService.instance.isAuthenticating,
      );
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
      }
      settingsBloc.add(const SetLocked(false));
      await tester.pumpAndSettle();
      expect(find.byType(BiometricShieldScreen), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pumpAndSettle();
      expect(settingsBloc.state.isLocked, isTrue);
    });

    testWidgets('renders the shield on top when the app is locked', (
      tester,
    ) async {
      settingsBloc = AppSettingsBloc()..add(const SetLocked(true));

      await tester.pumpWidget(
        BlocProvider<AppSettingsBloc>.value(
          value: settingsBloc,
          child: App(repositoryOverride: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BiometricShieldScreen), findsOneWidget);

      settingsBloc.add(const SetLocked(false));
      await tester.pumpAndSettle();
      expect(find.byType(BiometricShieldScreen), findsNothing);
    });
  });

  group('App full initialization', () {
    late Directory tempDir;
    late FakePathProviderPlatform pathProvider;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('app_init_test_');
      pathProvider = FakePathProviderPlatform(tempDir.path);
      PathProviderPlatform.instance = pathProvider;
      FlutterSecureStorage.setMockInitialValues({});
    });

    tearDown(() {
      if (File(tempDir.path).existsSync()) {
        File(tempDir.path).deleteSync();
      } else if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    void closeOpenIsar() {
      final instance = Isar.getInstance(DatabaseModule.dbName);
      if (instance != null) {
        instance.close();
      }
    }

    testWidgets(
      'shows the error screen and retries when initialization fails',
      (tester) async {
        tempDir.deleteSync(recursive: true);
        File(tempDir.path).writeAsStringSync('not a directory');
        final settingsBloc = AppSettingsBloc();

        await tester.pumpWidget(
          BlocProvider<AppSettingsBloc>.value(
            value: settingsBloc,
            child: const App(),
          ),
        );
        await pumpForInitialization(
          tester,
          () =>
              find.byType(AppInitializationErrorContent).evaluate().isNotEmpty,
        );

        expect(find.byType(AppInitializationErrorContent), findsOneWidget);

        await tester.tap(find.byType(FilledButton));
        await pumpForInitialization(
          tester,
          () =>
              find.byType(AppInitializationErrorContent).evaluate().isNotEmpty,
        );
        expect(find.byType(AppInitializationErrorContent), findsOneWidget);

        settingsBloc.close();
      },
    );

    testWidgets(
      're-opens the database and re-subscribes when a closed instance is found on resume',
      (tester) async {
        final settingsBloc = AppSettingsBloc()..add(const CompleteOnboarding());

        await tester.pumpWidget(
          BlocProvider<AppSettingsBloc>.value(
            value: settingsBloc,
            child: App(repositoryOverride: repository),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(MainNavigationScreen), findsOneWidget);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await pumpForInitialization(
          tester,
          () => Isar.getInstance(DatabaseModule.dbName)?.isOpen ?? false,
        );

        expect(
          File('${tempDir.path}/${DatabaseModule.dbName}.isar').existsSync(),
          isTrue,
        );

        settingsBloc.close();
        closeOpenIsar();
      },
    );

    testWidgets('boots past the splash once initialization succeeds', (
      tester,
    ) async {
      final settingsBloc = AppSettingsBloc();

      await tester.pumpWidget(
        BlocProvider<AppSettingsBloc>.value(
          value: settingsBloc,
          child: const App(),
        ),
      );
      expect(find.byType(AppSplashScreen), findsOneWidget);

      await pumpForInitialization(
        tester,
        () => find.byType(AppSplashScreen).evaluate().isEmpty,
      );

      expect(find.byType(AppSplashScreen), findsNothing);
      expect(find.text('Welcome to Balance'), findsOneWidget);

      settingsBloc.close();
      closeOpenIsar();
    });
  });
}
