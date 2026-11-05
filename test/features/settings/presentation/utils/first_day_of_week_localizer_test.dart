import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/features/settings/presentation/utils/first_day_of_week_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/l10n/app_localizations_en.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  group('FirstDayOfWeekLocalizer.localizedName', () {
    test('maps FirstDayOfWeek.system to localized system label', () {
      expect(
        FirstDayOfWeek.system.localizedName(l10n),
        l10n.firstDayOfWeekSystem,
      );
    });

    test('maps FirstDayOfWeek.monday to localized monday label', () {
      expect(
        FirstDayOfWeek.monday.localizedName(l10n),
        l10n.firstDayOfWeekMonday,
      );
    });

    test('maps FirstDayOfWeek.sunday to localized sunday label', () {
      expect(
        FirstDayOfWeek.sunday.localizedName(l10n),
        l10n.firstDayOfWeekSunday,
      );
    });

    test('returns distinct non-empty labels for all enum values', () {
      final labels = FirstDayOfWeek.values
          .map((v) => v.localizedName(l10n))
          .toSet();
      expect(labels.length, FirstDayOfWeek.values.length);
      for (final label in labels) {
        expect(label.isNotEmpty, isTrue);
      }
    });
  });
}
