import 'dart:math';

import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

/// Hardcoded 3-month dataset of weight measurements for initial app startup.
///
/// Contains daily weight entries spanning the last 90 days with multiple
/// measurements on selected days at different hours (morning, afternoon, evening),
/// realistic weight loss trends, and sample notes.
List<WeightEntry> getInitial3MonthsWeightEntries({DateTime? referenceDate}) {
  final now = referenceDate ?? DateTime.now();
  final List<WeightEntry> entries = [];

  // Seeded random to ensure deterministic, smooth, and realistic daily weight curves
  final random = Random(42);

  const startWeightKg = 83.8;
  const targetWeightKg = 77.9;
  const totalDays = 90;
  const totalWeightChange = targetWeightKg - startWeightKg;

  final sampleNotes = [
    'Rano na czczo',
    'Po treningu siłowym',
    'Po 5km biegu',
    'Wieczorny pomiar po kolacji',
    'Cheat day',
    'Po obfitym posiłku',
    'Na czczo po kardio',
    'Przed senem',
    'Po nawodnieniu',
    'Dzień regeneracyjny',
  ];

  for (int dayOffset = totalDays; dayOffset >= 0; dayOffset--) {
    final date = now.subtract(Duration(days: dayOffset));
    final progressFraction = (totalDays - dayOffset) / totalDays;

    // Linear progress trend + sine wave (water weight cycles) + pseudo-random daily fluctuation
    final baseTrend = startWeightKg + (totalWeightChange * progressFraction);
    final cyclicFluctuation = sin(dayOffset * 0.28) * 0.35;
    final randomNoise = (random.nextDouble() - 0.5) * 0.5;
    final baseDayWeight = baseTrend + cyclicFluctuation + randomNoise;

    // Determine intraday measurements: ~65% single morning entry, ~25% morning+evening, ~10% morning+afternoon+evening
    final roll = random.nextDouble();
    final times = <DateTime>[];

    // 1. Morning measurement (07:00 - 08:30)
    times.add(
      DateTime(
        date.year,
        date.month,
        date.day,
        7 + random.nextInt(2),
        random.nextInt(60),
      ),
    );

    if (roll > 0.65) {
      // 2. Evening measurement (19:30 - 21:30)
      times.add(
        DateTime(
          date.year,
          date.month,
          date.day,
          19 + random.nextInt(3),
          random.nextInt(60),
        ),
      );
    }

    if (roll > 0.90) {
      // 3. Afternoon measurement (13:00 - 15:30)
      times.add(
        DateTime(
          date.year,
          date.month,
          date.day,
          13 + random.nextInt(3),
          random.nextInt(60),
        ),
      );
    }

    times.sort();

    for (int i = 0; i < times.length; i++) {
      final measurementTime = times[i];

      // Afternoon/evening measurements reflect normal intraday weight gain (+0.3kg to +0.8kg)
      double weight = baseDayWeight;
      if (measurementTime.hour >= 12) {
        weight += 0.3 + (random.nextDouble() * 0.5);
      }

      String? note;
      if (random.nextDouble() < 0.25) {
        note = sampleNotes[random.nextInt(sampleNotes.length)];
      } else if (i == 0 && random.nextDouble() < 0.4) {
        note = 'Rano na czczo';
      }

      entries.add(
        WeightEntry(
          weightKg: double.parse(weight.toStringAsFixed(1)),
          dateTime: measurementTime,
          note: note,
        ),
      );
    }
  }

  return entries;
}
