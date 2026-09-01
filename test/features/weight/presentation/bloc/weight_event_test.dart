import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

void main() {
  group('WeightEvent Tests', () {
    test('instantiates all event variants with expected payload fields', () {
      const subscribe = SubscribeToWeightChanges();
      expect(subscribe, isA<WeightEvent>());

      const updateHeight = UpdateUserHeight(180.0);
      expect(updateHeight.heightCm, 180.0);

      final addWeight = AddWeight(
        weightKg: 75.5,
        note: 'Morning',
        dateTime: DateTime(2026, 6, 1, 8, 0),
      );
      expect(addWeight.weightKg, 75.5);
      expect(addWeight.note, 'Morning');

      final entry = WeightEntry(
        id: 1,
        weightKg: 75.0,
        dateTime: DateTime(2026, 6, 1),
      );
      final updateWeight = UpdateWeight(entry);
      expect(updateWeight.entry, entry);

      const deleteWeight = DeleteWeight(1);
      expect(deleteWeight.id, 1);

      const changeFilter = ChangeChartFilter(TimePeriod.month);
      expect(changeFilter.period, TimePeriod.month);

      const refresh = RefreshWeightData();
      expect(refresh, isA<WeightEvent>());

      const clearAll = ClearAllWeightData();
      expect(clearAll, isA<WeightEvent>());

      final importEntries = ImportWeightEntries([entry]);
      expect(importEntries.entries, [entry]);

      final syncHealth = SyncHealthEntries(startDate: DateTime(2026, 1, 1));
      expect(syncHealth.startDate, DateTime(2026, 1, 1));

      const analyzeCsv = AnalyzeCsvFile(filePath: '/path/to/file.csv');
      expect(analyzeCsv.filePath, '/path/to/file.csv');

      final confirmCsv = ConfirmCsvImport(validEntries: [entry]);
      expect(confirmCsv.validEntries, [entry]);
    });
  });
}
