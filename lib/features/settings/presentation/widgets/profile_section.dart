import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'custom_settings_tile.dart';

/// A widget that displays the profile settings group with height and target weight tiles.
class ProfileSection extends StatelessWidget {
  final AppSettingsState state;
  final AppLocalizations l10n;
  final VoidCallback onHeightTap;
  final VoidCallback onTargetWeightTap;

  const ProfileSection({
    super.key,
    required this.state,
    required this.l10n,
    required this.onHeightTap,
    required this.onTargetWeightTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final heightValue = (state.height != null && state.height! > 0)
        ? formatHeight(state.height!, state.measurementUnit)
        : l10n.heightNotSetLabel;

    final targetWeightValue = state.targetWeight != null
        ? formatWeight(state.targetWeight!, state.measurementUnit)
        : l10n.notSet;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          CustomSettingsTile(
            icon: Icons.height,
            title: l10n.height,
            subtitle: heightValue,
            sectionLabel: l10n.profileSection,
            onTap: () {
              AppAnalytics.logSettingsHeightTileClicked(state.height);
              onHeightTap();
            },
          ),
          CustomSettingsTile(
            icon: Icons.flag_outlined,
            title: l10n.targetWeight,
            subtitle: targetWeightValue,
            sectionLabel: l10n.profileSection,
            onTap: () {
              AppAnalytics.logSettingsTargetWeightTileClicked(
                state.targetWeight,
              );
              onTargetWeightTap();
            },
          ),
        ],
      ),
    );
  }
}
