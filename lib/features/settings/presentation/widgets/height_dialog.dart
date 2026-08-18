// Dialog for entering the user's height.

import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';

/// A widget that provides a dialog for entering the user's height.
///
/// Pops the entered height as a `double` (in cm) on save, or `null` when
/// canceled. Input is trimmed, `,` is accepted as a decimal separator, and the
/// value must lie within the inclusive [AppSettingsState.minHeightCm]–
/// [AppSettingsState.maxHeightCm] range. Validates automatically and enables/disables the Save button.
class HeightDialog extends StatefulWidget {
  /// The currently stored height in cm, or `null` if not set yet.
  final double? currentValue;
  final MeasurementUnit measurementUnit;

  /// Creates a [HeightDialog] pre-filled with [currentValue].
  const HeightDialog({
    super.key,
    required this.currentValue,
    required this.measurementUnit,
  });

  @override
  State<HeightDialog> createState() => HeightDialogState();
}

class HeightDialogState extends State<HeightDialog> {
  late final TextEditingController _cmController;
  late final TextEditingController _feetController;
  late final TextEditingController _inchesController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final hasHeight = widget.currentValue != null && widget.currentValue! > 0;

    _cmController = TextEditingController(
      text: hasHeight && widget.measurementUnit == MeasurementUnit.metric
          ? widget.currentValue!.toStringAsFixed(0)
          : '',
    );

    final ftIn = cmToFeetInches(hasHeight ? widget.currentValue! : 0.0);
    _feetController = TextEditingController(
      text: hasHeight && widget.measurementUnit == MeasurementUnit.imperial
          ? ftIn[0].toInt().toString()
          : '',
    );
    _inchesController = TextEditingController(
      text: hasHeight && widget.measurementUnit == MeasurementUnit.imperial
          ? ftIn[1].round().toString()
          : '',
    );
  }

  @override
  void dispose() {
    _cmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  double? _calculateHeightCm() {
    if (widget.measurementUnit == MeasurementUnit.metric) {
      final cm = double.tryParse(
        _cmController.text.trim().replaceAll(',', '.'),
      );
      if (cm != null &&
          cm >= AppSettingsState.minHeightCm &&
          cm <= AppSettingsState.maxHeightCm) {
        return cm;
      }
      return null;
    } else {
      final feet = double.tryParse(
        _feetController.text.trim().replaceAll(',', '.'),
      );
      final inchesText = _inchesController.text.trim().replaceAll(',', '.');
      final inches = inchesText.isEmpty ? 0.0 : double.tryParse(inchesText);
      if (feet != null && inches != null && feet >= 0 && inches >= 0) {
        final cm = ((feet * 12) + inches) * 2.54;
        if (cm >= AppSettingsState.minHeightCm &&
            cm <= AppSettingsState.maxHeightCm) {
          return cm;
        }
      }
      return null;
    }
  }

  void _handleSave() {
    final height = _calculateHeightCm();
    if (height != null) {
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(height);
    } else {
      setState(() {
        _errorText = AppLocalizations.of(context).heightRangeError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMetric = widget.measurementUnit == MeasurementUnit.metric;

    return AlertDialog(
      title: Text(l10n.heightDialogTitle),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              if (isMetric)
                TextField(
                  controller: _cmController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.heightCmLabel,
                    hintText: l10n.heightHint,
                    errorText: _errorText != null ? "" : null,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                    helperText: l10n.heightRangeHint(
                      AppSettingsState.minHeightCm.toStringAsFixed(0),
                      AppSettingsState.maxHeightCm.toStringAsFixed(0),
                    ),
                    helperMaxLines: 2,
                    contentPadding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      16,
                      12,
                      12,
                    ),
                  ),
                  onChanged: (_) {
                    if (_errorText != null) setState(() => _errorText = null);
                  },
                  onSubmitted: (_) => _handleSave(),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _feetController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: l10n.feetLabel,
                          suffixText: 'ft',
                          errorText: _errorText != null ? "" : null,
                          errorStyle: const TextStyle(height: 0, fontSize: 0),
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
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: TextField(
                        controller: _inchesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.inchesLabel,
                          suffixText: 'in',
                          errorText: _errorText != null ? "" : null,
                          errorStyle: const TextStyle(height: 0, fontSize: 0),
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
                    ),
                  ],
                ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    _errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12.0,
                    ),
                  ),
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
        TextButton(onPressed: _handleSave, child: Text(l10n.save)),
      ],
    );
  }
}
