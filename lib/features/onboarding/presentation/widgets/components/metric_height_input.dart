import 'package:flutter/material.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational text field for entering height in centimeters with validation and bounds helper.
class MetricHeightInput extends StatelessWidget {
  /// Controller managing the cm string text.
  final TextEditingController controller;

  /// Focus node for the cm text field.
  final FocusNode focusNode;

  /// Optional error text to display.
  final String? errorText;

  /// Callback when text changes.
  final ValueChanged<String> onChanged;

  /// Callback when submitted from keyboard.
  final VoidCallback onSubmitted;

  /// Creates a [MetricHeightInput] widget.
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
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
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
