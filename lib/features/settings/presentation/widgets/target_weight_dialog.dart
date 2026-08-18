// lib/features/settings/presentation/widgets/target_weight_dialog.dart

import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A widget that provides a dialog for setting or updating the target weight.
class TargetWeightDialog extends StatefulWidget {
  /// The currently stored target weight in kg, or `null` if not set yet.
  final double? currentValueKg;

  /// The active measurement unit used for labels and field values.
  final MeasurementUnit measurementUnit;

  const TargetWeightDialog({
    super.key,
    required this.currentValueKg,
    required this.measurementUnit,
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
    final initialValue = widget.currentValueKg != null
        ? (widget.measurementUnit == MeasurementUnit.imperial
              ? kgToLbs(widget.currentValueKg!)
              : widget.currentValueKg!)
        : null;

    _controller = TextEditingController(
      text: initialValue != null
          ? initialValue.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')
          : '',
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
      Navigator.of(context).pop('clear');
      return;
    }

    final parsedWeight = double.tryParse(text);
    if (parsedWeight == null || parsedWeight <= 0) {
      setState(() {
        _errorText = AppLocalizations.of(context).invalidPositiveNumber;
      });
      return;
    }

    final weightKg = widget.measurementUnit == MeasurementUnit.imperial
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

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.targetWeightDialogTitle),
      content: SizedBox(
        width: 320,
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
                labelText: widget.measurementUnit == MeasurementUnit.imperial
                    ? l10n.weightInLbLabel
                    : l10n.weightInKgLabel,
                hintText: l10n.weightHint,
                errorText: _errorText,
                errorMaxLines: 2,
                contentPadding: const EdgeInsetsDirectional.fromSTEB(
                  12,
                  16,
                  12,
                  12,
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
      actions: [
        if (widget.currentValueKg != null)
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
        TextButton(onPressed: _handleSave, child: Text(l10n.save)),
      ],
    );
  }
}
