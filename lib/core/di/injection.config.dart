// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:isar_community/isar.dart' as _i214;

import '../../features/settings/presentation/bloc/app_settings_bloc.dart'
    as _i388;
import '../../features/weight/domain/repositories/weight_repository.dart'
    as _i627;
import '../../features/weight/domain/services/csv_weight_importer.dart' as _i98;
import '../../features/weight/domain/services/health_sync_coordinator.dart'
    as _i491;
import '../../features/weight/presentation/bloc/weight_bloc.dart' as _i524;
import '../integrations/biometrics/biometric_service.dart' as _i957;
import '../integrations/csv/csv_import_service.dart' as _i808;
import '../integrations/health/health_service.dart' as _i330;
import '../integrations/notifications/notification_service.dart' as _i141;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i214.Isar>(
      () => registerModule.isar,
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i957.BiometricService>(
      () => registerModule.biometricService,
    );
    gh.lazySingleton<_i141.NotificationService>(
      () => registerModule.notificationService,
    );
    gh.lazySingleton<_i808.CsvImportService>(
      () => registerModule.csvImportService,
    );
    gh.lazySingleton<_i388.AppSettingsBloc>(
      () => _i388.AppSettingsBloc(
        notificationService: gh<_i141.NotificationService>(),
        healthService: gh<_i330.HealthService>(),
      ),
    );
    gh.lazySingleton<_i330.HealthService>(() => registerModule.healthService);
    gh.lazySingleton<_i627.WeightRepository>(
      () => registerModule.weightRepository(
        gh<_i214.Isar>(),
        gh<_i957.BiometricService>(),
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.factory<_i524.WeightBloc>(
      () => _i524.WeightBloc(
        repository: gh<_i627.WeightRepository>(),
        appSettingsBloc: gh<_i388.AppSettingsBloc>(),
        healthService: gh<_i330.HealthService>(),
        healthSyncCoordinator: gh<_i491.HealthSyncCoordinator>(),
        csvWeightImporter: gh<_i98.CsvWeightImporter>(),
      ),
    );
    gh.lazySingleton<_i491.HealthSyncCoordinator>(
      () => registerModule.healthSyncCoordinator(
        gh<_i330.HealthService>(),
        gh<_i627.WeightRepository>(),
      ),
    );
    gh.lazySingleton<_i98.CsvWeightImporter>(
      () => registerModule.csvWeightImporter(gh<_i627.WeightRepository>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
