import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational row with dual text fields for entering height in feet and inches.
class ImperialHeightInput extends StatelessWidget {
  final TextEditingController feetController;
  final FocusNode feetFocusNode;
  final TextEditingController inchesController;
  final FocusNode inchesFocusNode;
  final String? errorText;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  const ImperialHeightInput({
    super.key,
    required this.feetController,
    required this.feetFocusNode,
    required this.inchesController,
    required this.inchesFocusNode,
    required this.errorText,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('height_feet_input'),
                controller: feetController,
                focusNode: feetFocusNode,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.feetLabel,
                  suffixText: 'ft',
                  errorText: errorText != null ? "" : null,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onSubmitted(),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: TextField(
                key: const Key('height_inches_input'),
                controller: inchesController,
                focusNode: inchesFocusNode,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.inchesLabel,
                  suffixText: 'in',
                  errorText: errorText != null ? "" : null,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onSubmitted(),
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
