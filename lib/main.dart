import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/app.dart';
import 'package:pure_weight/core/database/database_module.dart';
import 'package:pure_weight/core/services/notification_service.dart';
import 'package:isar_community/isar.dart';
import 'package:pure_weight/features/weight/data/datasources/initial_weight_data.dart';
import 'package:pure_weight/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exception}\n${details.stack}');
    }
  };

  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('Unhandled async error: $error\n$stack');
    }
    return true;
  };

  final storageDirectory = HydratedStorageDirectory(
    (await getApplicationDocumentsDirectory()).path,
  );
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: storageDirectory,
  );

  final isar = await DatabaseModule.initialize();
  final repository = _createWeightRepository(isar);

  // Demo/dev-only seed data — never runs in release builds. If QA needs
  // this on a release build, gate it behind an explicit flag instead of
  // kDebugMode.
  if (kDebugMode) {
    final existingEntries = await repository.getAllEntries();
    if (existingEntries.isEmpty) {
      await repository.bulkImportEntries(getInitial3MonthsWeightEntries());
    }
  }

  await NotificationService.instance.initialize();

  final settingsBloc = AppSettingsBloc();
  if (settingsBloc.state.height <= 0) {
    settingsBloc.add(const UpdateHeight(178));
  }

  runApp(
    BlocProvider(
      create: (_) => settingsBloc,
      child: App(repository: repository),
    ),
  );
}

/// Creates the [WeightRepository] implementation backed by Isar.
///
/// Kept in [main.dart] as the composition root where the concrete type
/// is resolved, while the rest of the app only depends on the domain interface.
WeightRepository _createWeightRepository(Isar isar) {
  return IsarWeightRepository(isar: isar);
}
