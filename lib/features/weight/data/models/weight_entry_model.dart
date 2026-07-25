import 'package:isar_community/isar.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

part 'weight_entry_model.g.dart';

/// Isar collection model mapped to [WeightEntry].
@collection
class WeightEntryModel {
  /// Creates an empty model with default values.
  WeightEntryModel();

  /// Isar auto-increment identifier.
  Id id = Isar.autoIncrement;

  /// Body weight in kilograms.
  double weightKg = 0.0;

  /// Timestamp of the measurement.
  late DateTime dateTime;

  /// Optional user-provided note.
  String? note;

  /// Maps this model to a domain [WeightEntry].
  WeightEntry toEntity() {
    return WeightEntry(
      id: id,
      weightKg: weightKg,
      bmi: null,
      dateTime: dateTime,
      note: note,
    );
  }

  /// Creates a model from a domain [WeightEntry].
  factory WeightEntryModel.fromEntity(WeightEntry entity) {
    return WeightEntryModel()
      ..id = entity.id
      ..weightKg = entity.weightKg
      ..dateTime = entity.dateTime
      ..note = entity.note;
  }
}
