import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Extension to provide localized names for [FirstDayOfWeek].
extension FirstDayOfWeekLocalizer on FirstDayOfWeek {
  /// Returns the localized string for this first day of week setting.
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case FirstDayOfWeek.system:
        return l10n.firstDayOfWeekSystem;
      case FirstDayOfWeek.monday:
        return l10n.firstDayOfWeekMonday;
      case FirstDayOfWeek.sunday:
        return l10n.firstDayOfWeekSunday;
    }
  }
}
