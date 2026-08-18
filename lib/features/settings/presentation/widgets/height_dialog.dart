// Dialog for entering the user's height in centimeters.

import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';

/// A widget that provides a dialog for entering the user's height in centimeters.
///
/// Pops the entered height as a `double` (in cm) on save, or `null` when
/// canceled. Input is trimmed, `,` is accepted as a decimal separator, and the
/// value must lie within the inclusive [AppSettingsState.minHeightCm]–
/// [AppSettingsState.maxHeightCm] range; invalid input shows an inline error
/// instead.
class HeightDialog extends StatefulWidget {
  /// The currently stored height in cm, or `null` if not set yet.
  final double? currentValue;

  /// Creates a [HeightDialog] pre-filled with [currentValue].
  const HeightDialog({super.key, required this.currentValue});

  @override
  State<HeightDialog> createState() => HeightDialogState();
}

class HeightDialogState extends State<HeightDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.currentValue != null && widget.currentValue! > 0)
          ? widget.currentValue!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Validates the entered height and pops it as a `double` on success.
  ///
  /// Empty, non-numeric, or out-of-range input shows an inline error instead
  /// of popping the dialog.
  void _handleSave() {
    FocusScope.of(context).unfocus();
    final text = _controller.text.trim().replaceAll(',', '.');
    final height = double.tryParse(text);

    if (text.isEmpty ||
        height == null ||
        height < AppSettingsState.minHeightCm ||
        height > AppSettingsState.maxHeightCm) {
      setState(() {
        _errorText = AppLocalizations.of(context).heightRangeError;
      });
      return;
    }

    Navigator.of(context).pop(height);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.height,
        size: 28,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(l10n.heightDialogTitle),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.heightCmLabel,
                  hintText: l10n.heightHint,
                  errorText: _errorText,
                  helperText: l10n.heightRangeHint(
                    AppSettingsState.minHeightCm.toStringAsFixed(0),
                    AppSettingsState.maxHeightCm.toStringAsFixed(0),
                  ),
                  helperMaxLines: 2,
                  errorMaxLines: 2,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                      width: 2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
                onSubmitted: (_) => _handleSave(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _handleSave,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
