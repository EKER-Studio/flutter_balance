import 'package:flutter/material.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational text field for entering height in centimeters with validation and bounds helper.
class MetricHeightInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  const MetricHeightInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextField(
      key: const Key('height_cm_input'),
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: l10n.heightCmLabel,
        hintText: l10n.heightHint,
        errorText: errorText,
        helperText: l10n.heightRangeHint(
          AppSettingsState.minHeightCm.toStringAsFixed(0),
          AppSettingsState.maxHeightCm.toStringAsFixed(0),
        ),
      ),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
    );
  }
}
