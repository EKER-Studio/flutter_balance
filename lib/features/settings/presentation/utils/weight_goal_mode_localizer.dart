import 'package:flutter/widgets.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Extension providing localized display names and descriptions for [WeightGoalMode].
extension WeightGoalModeLocalizer on WeightGoalMode {
  /// Returns the localized title of the goal mode.
  String localizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case WeightGoalMode.lose:
        return l10n.goalModeLose;
      case WeightGoalMode.maintain:
        return l10n.goalModeMaintain;
      case WeightGoalMode.gain:
        return l10n.goalModeGain;
    }
  }

  /// Returns the localized description of the goal mode.
  String localizedDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case WeightGoalMode.lose:
        return l10n.goalModeLoseDesc;
      case WeightGoalMode.maintain:
        return l10n.goalModeMaintainDesc;
      case WeightGoalMode.gain:
        return l10n.goalModeGainDesc;
    }
  }
}
