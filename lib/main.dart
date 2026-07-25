import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/app.dart';
import 'package:pure_weight/core/database/database_module.dart';
import 'package:pure_weight/core/services/biometric_lock_observer.dart';
import 'package:pure_weight/core/services/notification_service.dart';
import 'package:pure_weight/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageDirectory = HydratedStorageDirectory(
    (await getApplicationDocumentsDirectory()).path,
  );
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: storageDirectory,
  );

  final isar = await DatabaseModule.initialize();
  final repository = IsarWeightRepository(isar: isar);

  // Run one-time migration to remove stored BMI values from DB entries.
  // This rewrites all entries without the `bmi` field so old stored values
  // are purged. It's safe to call on each startup; it simply re-inserts
  // records using the current schema.
  await repository.removeStoredBmiFromDb();

  await NotificationService.instance.initialize();

  final settingsBloc = AppSettingsBloc();

  final biometricLockObserver = BiometricLockObserver(
    settingsBloc: settingsBloc,
  );
  WidgetsBinding.instance.addObserver(biometricLockObserver);

  runApp(
    BlocProvider(
      create: (_) => settingsBloc,
      child: App(repository: repository),
    ),
  );
}
