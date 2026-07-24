import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/app.dart';
import 'package:pure_weight/core/database/database_module.dart';
import 'package:pure_weight/core/services/notification_service.dart';
import 'package:pure_weight/features/weight/data/repositories/isar_weight_repository.dart';

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

  runApp(App(repository: repository));
}
