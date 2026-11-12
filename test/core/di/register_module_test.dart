import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:balance/core/di/register_module.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/core/integrations/widgets/widget_sync_service.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:balance/features/weight/data/services/csv_weight_importer.dart';
import 'package:balance/features/weight/domain/repositories/health_sync_settings.dart';
import 'package:balance/features/weight/domain/services/health_sync_coordinator.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockIsar extends Mock implements Isar {}

/// A concrete subclass of the abstract [RegisterModule] used to exercise its
/// inherited factory getters and methods.
class _TestRegisterModule extends RegisterModule {}

/// Exercises the [RegisterModule] factory getters and methods to verify each
/// dependency is constructed with the correct type and that platform singletons
/// resolve to their shared instances.
///
/// The `isar` getter is intentionally not exercised here: it opens a real,
/// encrypted [Isar] database and provisions an encryption key through platform
/// secure storage, which is not available in a unit-test environment.
void main() {
  late MockHydratedStorage storage;
  late _TestRegisterModule module;

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.delete(any())).thenAnswer((_) async {});

    module = _TestRegisterModule();
  });

  group('RegisterModule platform singletons', () {
    test('secureStorage returns a FlutterSecureStorage instance', () {
      expect(module.secureStorage, isA<FlutterSecureStorage>());
    });

    test(
      'biometricService resolves to the shared BiometricService singleton',
      () {
        expect(module.biometricService, same(BiometricService.instance));
      },
    );

    test(
      'notificationService resolves to the shared NotificationService singleton',
      () {
        expect(module.notificationService, same(NotificationService.instance));
      },
    );

    test(
      'healthService resolves to the shared NativeHealthService singleton',
      () {
        final health = module.healthService;
        expect(health, isA<NativeHealthService>());
        expect(health, same(NativeHealthService.instance));
      },
    );

    test(
      'widgetSyncService resolves to the shared WidgetSyncService singleton',
      () {
        expect(module.widgetSyncService, same(WidgetSyncService.instance));
      },
    );

    test('csvImportService returns a fresh CsvImportService', () {
      expect(module.csvImportService, isA<CsvImportService>());
    });
  });

  group('RegisterModule composite dependencies', () {
    test(
      'weightRepository wraps the Isar repository with the unlock signal',
      () {
        final mockIsar = MockIsar();
        final biometric = module.biometricService;
        final secureStorage = module.secureStorage;

        final repository = module.weightRepository(
          mockIsar,
          biometric,
          secureStorage,
        );

        expect(repository, isA<IsarWeightRepository>());
        expect(repository.isar, same(mockIsar));
        expect(repository.secureStorage, same(secureStorage));
        expect(repository.unlockSignal, isA<Stream<void>>());
      },
    );

    test('healthSyncCoordinator wires the health service and repository', () {
      final repository = module.weightRepository(
        MockIsar(),
        module.biometricService,
        module.secureStorage,
      );
      final healthService = module.healthService;

      final coordinator = module.healthSyncCoordinator(
        healthService,
        repository,
      );

      expect(coordinator, isA<HealthSyncCoordinator>());
      expect(coordinator.healthService, same(healthService));
      expect(coordinator.repository, same(repository));
    });

    test(
      'csvWeightImporter wraps the CsvFileWeightImporter around a repository',
      () {
        final repository = module.weightRepository(
          MockIsar(),
          module.biometricService,
          module.secureStorage,
        );

        final importer = module.csvWeightImporter(repository);

        expect(importer, isA<CsvFileWeightImporter>());
        expect(importer, isA<CsvWeightImporter>());
        expect(importer.repository, same(repository));
      },
    );

    test(
      'healthSyncSettings exposes the AppSettingsBloc as a HealthSyncSettings',
      () {
        final settingsBloc = AppSettingsBloc(
          notificationService: module.notificationService,
          healthService: module.healthService,
        );

        final settings = module.healthSyncSettings(settingsBloc);

        expect(settings, isA<HealthSyncSettings>());
        expect(settings, same(settingsBloc));
      },
    );
  });
}
