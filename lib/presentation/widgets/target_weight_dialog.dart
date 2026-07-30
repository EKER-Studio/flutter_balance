import 'package:flutter/material.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
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

  void _handleSave() {
    FocusScope.of(context).unfocus();
    final text = _controller.text.trim().replaceAll(',', '.');

    if (text.isEmpty) {
      Navigator.of(context).pop(null);
      return;
    }

    final weight = double.tryParse(text);
    if (weight != null && weight > 0) {
      Navigator.of(context).pop(weight);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).invalidPositiveNumber),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.targetWeightDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              ),
              onSubmitted: (_) => _handleSave(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _handleSave, child: Text(l10n.save)),
      ],
    );
  }
}
