// Profile settings group with height and target weight tiles.


import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'custom_settings_tile.dart';

///// A widget that displays the profile settings group with height and target weight tiles.
class ProfileSection extends StatelessWidget {
  /// The current app settings [state] driving the displayed values.
  final AppSettingsState state;

  /// Localized strings for the [ProfileSection] widget.
  final AppLocalizations l10n;

  /// Callback invoked when the height tile is tapped, allowing the user to update their height.
  final VoidCallback onHeightTap;

  /// Callback invoked when the target weight tile is tapped, allowing the user to update their target weight.
  final VoidCallback onTargetWeightTap;

  /// Creates a [ProfileSection] with the given dependencies.
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          CustomSettingsTile(
            icon: Icons.height,
            title: l10n.height,
            valueText: heightValue,
            sectionLabel: l10n.profileSection,
            onTap: onHeightTap,
          ),
          CustomSettingsTile(
            icon: Icons.flag_outlined,
            title: l10n.targetWeight,
            valueText: targetWeightValue,
            sectionLabel: l10n.profileSection,
            onTap: onTargetWeightTap,
          ),
        ],
      ),
    );
  }
}
