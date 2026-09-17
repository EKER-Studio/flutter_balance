import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Result record returned by CSV import analysis, carrying parsed entries and
/// audit statistics for the preview dialog and import confirmation flow.
typedef CsvImportAnalysis = ({
  List<WeightEntry> validEntries,
  int skippedRowCount,
  DateTime? earliestDate,
  DateTime? latestDate,
});
