import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/features/weight/data/models/weight_entry_model.dart';

/// Initializes and provides the [Isar] database instance.
class DatabaseModule {
  /// Opens and returns an [Isar] instance with all registered schemas.
  static Future<Isar> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open([WeightEntryModelSchema], directory: dir.path);
  }
}
