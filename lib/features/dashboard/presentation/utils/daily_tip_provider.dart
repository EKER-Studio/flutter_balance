import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';

class DailyTip {
  final String title;
  final String text;

  const DailyTip(this.title, this.text);
}

class DailyTipProvider {
  static DailyTip getDailyTip(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tips = _getAllTips(l10n);

    // Choose a tip based on the current day of the year
    final now = DateTime.now();
    // A simple deterministic hash based on year and day of year
    final dayOfYear = now.year * 10000 + now.month * 100 + now.day;

    final index = dayOfYear % tips.length;
    return tips[index];
  }

  static List<DailyTip> _getAllTips(AppLocalizations l10n) {
    return [
      DailyTip(l10n.tip01Title, l10n.tip01Text),
      DailyTip(l10n.tip02Title, l10n.tip02Text),
      DailyTip(l10n.tip03Title, l10n.tip03Text),
      DailyTip(l10n.tip04Title, l10n.tip04Text),
      DailyTip(l10n.tip05Title, l10n.tip05Text),
      DailyTip(l10n.tip06Title, l10n.tip06Text),
      DailyTip(l10n.tip07Title, l10n.tip07Text),
      DailyTip(l10n.tip08Title, l10n.tip08Text),
      DailyTip(l10n.tip09Title, l10n.tip09Text),
      DailyTip(l10n.tip10Title, l10n.tip10Text),
      DailyTip(l10n.tip11Title, l10n.tip11Text),
      DailyTip(l10n.tip12Title, l10n.tip12Text),
      DailyTip(l10n.tip13Title, l10n.tip13Text),
      DailyTip(l10n.tip14Title, l10n.tip14Text),
      DailyTip(l10n.tip15Title, l10n.tip15Text),
      DailyTip(l10n.tip16Title, l10n.tip16Text),
      DailyTip(l10n.tip17Title, l10n.tip17Text),
      DailyTip(l10n.tip18Title, l10n.tip18Text),
      DailyTip(l10n.tip19Title, l10n.tip19Text),
      DailyTip(l10n.tip20Title, l10n.tip20Text),
      DailyTip(l10n.tip21Title, l10n.tip21Text),
      DailyTip(l10n.tip22Title, l10n.tip22Text),
      DailyTip(l10n.tip23Title, l10n.tip23Text),
      DailyTip(l10n.tip24Title, l10n.tip24Text),
      DailyTip(l10n.tip25Title, l10n.tip25Text),
      DailyTip(l10n.tip26Title, l10n.tip26Text),
      DailyTip(l10n.tip27Title, l10n.tip27Text),
      DailyTip(l10n.tip28Title, l10n.tip28Text),
      DailyTip(l10n.tip29Title, l10n.tip29Text),
      DailyTip(l10n.tip30Title, l10n.tip30Text),
    ];
  }
}
