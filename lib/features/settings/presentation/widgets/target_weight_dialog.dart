// Dialog for setting, updating or removing the target weight.


import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A widget that provides a dialog for setting or updating the target weight.
///
/// Pops the entered weight as a `double` (in the active measurement unit) on
/// save, the string `'clear'` when the field is emptied or the remove action
/// is used, and `null` when canceled. Input is trimmed, `,` is accepted as a
/// decimal separator, and the converted value in kg must lie within the
/// inclusive [WeightEntry.minWeightKg]–[WeightEntry.maxWeightKg] range;
///// invalid input shows an inline error instead.
class TargetWeightDialog extends StatefulWidget {
  /// The current target weight [currentValue] in the current measurement unit.
  final double? currentValue;

  /// The active measurement [unit] (metric or imperial).
  final MeasurementUnit unit;

  /// Creates a [TargetWeightDialog] with the given [currentValue] and [unit].
  const TargetWeightDialog({
    super.key,
    required this.currentValue,
    required this.unit,
  });

  @override
  State<TargetWeightDialog> createState() => _TargetWeightDialogState();
}

class _TargetWeightDialogState extends State<TargetWeightDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Validates the input and pops the dialog with the result.
  ///
  /// Pops the entered weight (a `double`, in the active unit) on success, the
  /// string `'clear'` when the field is empty, or shows an inline error for
  /// invalid or out-of-range values.
  void _handleSave() {
    FocusScope.of(context).unfocus();
    final text = _controller.text.trim().replaceAll(',', '.');

    if (text.isEmpty) {
      Navigator.of(context).pop('clear');
      return;
    }

    final parsedWeight = double.tryParse(text);
    if (parsedWeight == null) {
      setState(() {
        _errorText = AppLocalizations.of(context).invalidPositiveNumber;
      });
      return;
    }

    final weightKg = widget.unit == MeasurementUnit.imperial
        ? lbsToKg(parsedWeight)
        : parsedWeight;

    if (weightKg < WeightEntry.minWeightKg ||
        weightKg > WeightEntry.maxWeightKg) {
      setState(() {
        _errorText = AppLocalizations.of(context).weightRangeError;
      });
      return;
    }

    Navigator.of(context).pop(parsedWeight);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isError = _errorText != null;

    return AlertDialog(
      icon: Icon(
        Icons.flag_outlined,
        size: 28,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(l10n.targetWeightDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: widget.unit == MeasurementUnit.imperial
                    ? l10n.weightInLbLabel
                    : l10n.weightInKgLabel,
                hintText: l10n.weightHint,
                enabledBorder: isError
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                          width: 2,
                        ),
                      )
                    : null,
                focusedBorder: isError
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                          width: 2,
                        ),
                      )
                    : null,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 8),
            if (isError)
              Text(
                _errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        if (widget.currentValue != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop('clear'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.removeTargetWeight),
          )
        else
          const SizedBox.shrink(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _handleSave,
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.save),
            ),
          ],
        ),
      ],
    );
  }
}
