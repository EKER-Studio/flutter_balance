import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:balance/core/utils/field_cipher.dart';
import 'package:balance/features/weight/data/models/weight_entry_model.dart';
import 'package:balance/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Encrypted Persistence E2E', () {
    late Isar isar;
    late IsarWeightRepository repository;
    final testKey = Uint8List.fromList(List.generate(32, (i) => i));

    setUpAll(() async {
      final dir = await getApplicationDocumentsDirectory();
      
      isar = await Isar.open(
        [WeightEntryModelSchema],
        directory: dir.path,
        name: 'isar_e2e_test',
        inspector: false,
      );

      repository = IsarWeightRepository(
        isar: isar,
        encryptionKey: testKey,
      );
      
      // Clean start
      await repository.clearAllData();
    });

    tearDownAll(() async {
      await isar.close(deleteFromDisk: true);
    });

    testWidgets('Full-Cycle E2E Test: Encrypt, Write, Raw Verify, Read, Delete', (tester) async {
      // Step A (Write): Add a WeightEntry
      final entry = WeightEntry(
        weightKg: 78.4,
        dateTime: DateTime(2026, 8, 10, 12, 0),
        note: "E2E Test Note",
      );

      await repository.addEntry(entry);

      // Step B (Raw Physical Verification): Query the raw Isar collection directly
      final rawModels = await isar.weightEntryModels.where().findAll();
      
      expect(rawModels.length, 1);
      final rawModel = rawModels.first;

      // Verify that the stored fields are encrypted Base64 strings and DO NOT contain plain text
      expect(rawModel.encryptedWeight, isNot(contains('78.4')));
      expect(rawModel.encryptedNote, isNot(contains('E2E Test Note')));
      
      // Ensure they are valid base64 strings containing the IV + MAC + Ciphertext
      expect(() => base64Decode(rawModel.encryptedWeight), returnsNormally);
      expect(() => base64Decode(rawModel.encryptedNote!), returnsNormally);

      // Verify that FieldCipher can decrypt the raw model using the test key
      final decryptedRawWeight = FieldCipher.decrypt(rawModel.encryptedWeight, testKey);
      final decryptedRawNote = FieldCipher.decrypt(rawModel.encryptedNote!, testKey);
      
      expect(decryptedRawWeight, '78.4');
      expect(decryptedRawNote, 'E2E Test Note');

      // Step C (Stream & Read): Fetch entries via repository stream / getAllEntries()
      final entries = await repository.getAllEntries();
      
      expect(entries.length, 1);
      final fetchedEntry = entries.first;

      // Assert that decrypted domain entity correctly restores values
      expect(fetchedEntry.weightKg, 78.4);
      expect(fetchedEntry.note, 'E2E Test Note');
      expect(fetchedEntry.dateTime, DateTime(2026, 8, 10, 12, 0));

      // Step D (Cleanup): Delete the entry
      await repository.deleteEntry(fetchedEntry.id);
      
      final finalModels = await repository.getAllEntries();
      expect(finalModels, isEmpty);
    });
  });
}
