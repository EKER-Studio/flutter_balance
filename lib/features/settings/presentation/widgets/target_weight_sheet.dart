import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A widget that provides a modal bottom sheet for setting or updating the
/// target weight.
///
/// Validates the value against [WeightEntry.minWeightKg] and
/// [WeightEntry.maxWeightKg], converts imperial input to kilograms, and pops
/// the parsed weight (or the string `clear` to remove the target) on save.
class TargetWeightSheet extends StatefulWidget {
  /// The currently stored target weight in kg, or `null` if not set yet.
  final double? currentValueKg;
  final MeasurementUnit measurementUnit;

  const TargetWeightSheet({
    super.key,
    required this.currentValueKg,
    required this.measurementUnit,
  });

  @override
  State<TargetWeightSheet> createState() => _TargetWeightSheetState();
}

/// The state owning the target weight controller and save flow.
class _TargetWeightSheetState extends State<TargetWeightSheet> {
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
      AppAnalytics.logSettingsTargetWeightValidationError('invalid_number');
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
      AppAnalytics.logSettingsTargetWeightValidationError('range_error');
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.targetWeightDialogTitle,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: false,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: widget.measurementUnit == MeasurementUnit.imperial
                      ? l10n.weightInLbLabel
                      : l10n.weightInKgLabel,
                  hintText: l10n.weightHint,
                  border: const OutlineInputBorder(),
                  errorText: _errorText,
                  errorMaxLines: 2,
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: l10n.clearField,
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _errorText = null;
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    12,
                    16,
                    12,
                    12,
                  ),
                ),
                onChanged: (_) {
                  setState(() {
                    _errorText = null;
                  });
                },
                onSubmitted: (_) => _handleSave(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      AppAnalytics.logSettingsTargetWeightDialogCancelled();
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _handleSave, child: Text(l10n.save)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
