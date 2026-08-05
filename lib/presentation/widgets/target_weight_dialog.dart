import 'package:flutter/material.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// Dialog for setting or updating the target weight.
class TargetWeightDialog extends StatefulWidget {
  /// The current target weight value in the current measurement unit.
  final double? currentValue;

  /// The active measurement unit (metric or imperial).
  final MeasurementUnit unit;

  /// Creates a [TargetWeightDialog] with [currentValue] and [unit].
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

  /// Pops the entered weight on success, `null` when cleared, or sets an
  /// error message for invalid input.
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
      actions: [
        if (widget.currentValue != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop('clear'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.removeTargetWeight),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _handleSave, child: Text(l10n.save)),
      ],
    );
  }
}
