import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/features/weight/data/models/weight_entry_model.dart';

/// Initializes and provides the [Isar] database instance.
///
/// ## Schema Versioning Convention
/// Isar Community 3.x does not ship a built-in migration engine. To prepare
/// for future breaking schema changes without data loss:
/// 1. Keep the current instance name as `pure_weight_v1`.
/// 2. When a new collection field is added *without* removing/renaming existing
///    ones, Isar handles it transparently — no name change is needed.
/// 3. When a *breaking* change occurs (field removed / type changed), bump the
///    suffix to `pure_weight_v2`, open both instances in the migration helper,
///    copy the records, then close and delete the old file.
class DatabaseModule {
  /// The versioned database name. Increment suffix on breaking schema changes.
  static const String dbName = 'pure_weight_v1';

  /// Opens and returns an [Isar] instance with all registered schemas.
  ///
  /// [compactOnLaunch] reclaims wasted space whenever more than 10 MB or 25%
  /// of the file is unused, preventing unbounded file growth over time.
  static Future<Isar> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [WeightEntryModelSchema],
      directory: dir.path,
      name: dbName,
      compactOnLaunch: const CompactCondition(
        minFileSize: 10 * 1024 * 1024, // 10 MB
        minRatio: 1.25,
      ),
    );
  }
}
