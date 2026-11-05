import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/utils/weight_goal_mode_localizer.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'WeightGoalModeLocalizer provides localized names and descriptions',
    (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final l10n = AppLocalizations.of(capturedContext);

      // Verify localizedName
      expect(
        WeightGoalMode.lose.localizedName(capturedContext),
        l10n.goalModeLose,
      );
      expect(
        WeightGoalMode.maintain.localizedName(capturedContext),
        l10n.goalModeMaintain,
      );
      expect(
        WeightGoalMode.gain.localizedName(capturedContext),
        l10n.goalModeGain,
      );

      // Verify localizedDescription
      expect(
        WeightGoalMode.lose.localizedDescription(capturedContext),
        l10n.goalModeLoseDesc,
      );
      expect(
        WeightGoalMode.maintain.localizedDescription(capturedContext),
        l10n.goalModeMaintainDesc,
      );
      expect(
        WeightGoalMode.gain.localizedDescription(capturedContext),
        l10n.goalModeGainDesc,
      );

      // Distinctness check
      final names = WeightGoalMode.values
          .map((m) => m.localizedName(capturedContext))
          .toSet();
      expect(names.length, WeightGoalMode.values.length);

      final descriptions = WeightGoalMode.values
          .map((m) => m.localizedDescription(capturedContext))
          .toSet();
      expect(descriptions.length, WeightGoalMode.values.length);
    },
  );
}
