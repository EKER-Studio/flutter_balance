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
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';

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

  await NotificationService.instance.initialize();

  final settingsBloc = AppSettingsBloc();

  // BiometricLockObserver registers itself with WidgetsBinding Observer in constructor
  BiometricLockObserver(
    isBiometricLockEnabled: () => settingsBloc.state.isBiometricLockEnabled,
    lockEnabledStream: settingsBloc.stream.map((s) => s.isBiometricLockEnabled),
    onLockStateChanged: (locked) => settingsBloc.add(SetLocked(locked)),
  );

  runApp(
    BlocProvider(
      create: (_) => settingsBloc,
      child: App(repository: repository),
    ),
  );
}
