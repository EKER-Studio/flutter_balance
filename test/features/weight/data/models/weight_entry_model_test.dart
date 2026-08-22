import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:balance/features/weight/data/models/weight_entry_model.dart';

void main() {
  group('WeightEntryModel', () {
    test('initializes with default autoIncrement id and empty weight', () {
      final model = WeightEntryModel();

      expect(model.id, equals(Isar.autoIncrement));
      expect(model.encryptedWeight, isEmpty);
      expect(model.encryptedNote, isNull);
    });

    test('sets and gets properties correctly', () {
      final now = DateTime(2026, 8, 24, 12, 0);
      final model = WeightEntryModel()
        ..id = 42
        ..encryptedWeight = 'enc_weight_base64_payload'
        ..dateTime = now
        ..encryptedNote = 'enc_note_base64_payload';

      expect(model.id, equals(42));
      expect(model.encryptedWeight, equals('enc_weight_base64_payload'));
      expect(model.dateTime, equals(now));
      expect(model.encryptedNote, equals('enc_note_base64_payload'));
    });

    test('supports nullable encryptedNote', () {
      final now = DateTime(2026, 8, 24, 15, 30);
      final model = WeightEntryModel()
        ..encryptedWeight = 'enc_weight'
        ..dateTime = now
        ..encryptedNote = null;

      expect(model.encryptedNote, isNull);
      expect(model.encryptedWeight, equals('enc_weight'));
      expect(model.dateTime, equals(now));
    });
  });
}
