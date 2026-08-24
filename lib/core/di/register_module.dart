import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:balance/core/database/database_module.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/domain/services/csv_weight_importer.dart';
import 'package:balance/features/weight/domain/services/health_sync_coordinator.dart';

/// Module registering third-party services, platform singletons, and asynchronous resources.
@module
abstract class RegisterModule {
  /// Asynchronously opens and initializes the encrypted [Isar] database instance.
  @preResolve
  Future<Isar> get isar => DatabaseModule.initialize();

  /// Secure storage instance for encryption keys.
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  /// Platform biometric authentication service.
  @lazySingleton
  BiometricService get biometricService => BiometricService.instance;

  /// Daily reminder notification service.
  @lazySingleton
  NotificationService get notificationService => NotificationService.instance;

  /// Native Apple Health and Google Health Connect integration.
  @LazySingleton(as: HealthService)
  NativeHealthService get healthService => NativeHealthService();

  /// CSV import file picker and parser service.
  @lazySingleton
  CsvImportService get csvImportService => CsvImportService();

  /// Concrete [WeightRepository] implementation backed by Isar.
  @LazySingleton(as: WeightRepository)
  IsarWeightRepository weightRepository(
    Isar isar,
    BiometricService biometricService,
    FlutterSecureStorage secureStorage,
  ) => IsarWeightRepository(
    isar: isar,
    secureStorage: secureStorage,
    unlockSignal: biometricService.authenticationSuccesses,
  );

  /// Coordinator for bidirectional Apple Health / Health Connect synchronization.
  @lazySingleton
  HealthSyncCoordinator healthSyncCoordinator(
    HealthService healthService,
    WeightRepository repository,
  ) => HealthSyncCoordinator(
    healthService: healthService,
    repository: repository,
  );

  /// Importer for analyzing and persisting CSV weight datasets.
  @lazySingleton
  CsvWeightImporter csvWeightImporter(WeightRepository repository) =>
      CsvWeightImporter(repository: repository);
}
