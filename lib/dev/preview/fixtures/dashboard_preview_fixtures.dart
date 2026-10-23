import 'package:balance/core/models/time_period.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';

/// Provides representative account settings shared by dashboard previews.
const dashboardPreviewSettingsState = AppSettingsState(
  height: 173,
  targetWeight: 72,
);

/// Creates the sample weight entries used by dashboard previews.
List<WeightEntry> dashboardPreviewEntries({DateTime? referenceDate}) {
  final now = referenceDate ?? DateTime.now();
  return List.generate(14, (index) {
    final date = now.subtract(Duration(days: index));
    return WeightEntry(
      id: index + 1,
      weightKg: 76.4 - index * 0.12 + (index.isOdd ? 0.03 : 0),
      dateTime: DateTime(date.year, date.month, date.day, 7, 30),
      note: index == 0 ? 'Morning check-in' : null,
    );
  });
}

/// Creates a loaded weight state from the shared dashboard sample entries.
WeightState dashboardPreviewLoadedWeightState({DateTime? referenceDate}) {
  final entries = dashboardPreviewEntries(referenceDate: referenceDate);
  return WeightLoaded(
    heightCm: 173,
    timePeriod: TimePeriod.week,
    entries: entries,
    filteredEntries: entries.take(7).toList(),
  );
}
