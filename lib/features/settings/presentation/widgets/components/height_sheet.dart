import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A widget that provides a modal bottom sheet for entering the user's height.
///
/// Pops the entered height as a `double` (in cm) on save, or `null` when
/// canceled. Input is trimmed, `,` is accepted as a decimal separator, and the
/// value must lie within the inclusive [AppSettingsState.minHeightCm]–
/// [AppSettingsState.maxHeightCm] range. Validates automatically and enables/disables the Save button.
class HeightSheet extends StatefulWidget {
  /// The currently stored height in cm, or `null` if not set yet.
  final double? currentValue;
  final MeasurementUnit measurementUnit;

  const HeightSheet({
    super.key,
    required this.currentValue,
    required this.measurementUnit,
  });

  @override
  State<HeightSheet> createState() => _HeightSheetState();
}

/// State for [HeightSheet] owning text input controllers and conversion/validation logic.
class _HeightSheetState extends State<HeightSheet> {
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
      AppAnalytics.logSettingsHeightValidationError('range_error');
      setState(() {
        _errorText = AppLocalizations.of(context).heightRangeError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMetric = widget.measurementUnit == MeasurementUnit.metric;

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
                l10n.heightDialogTitle,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              if (isMetric)
                TextField(
                  controller: _cmController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  textInputAction: TextInputAction.done,
                  autofocus: false,
                  decoration: InputDecoration(
                    labelText: l10n.heightCmLabel,
                    hintText: l10n.heightHint,
                    border: const OutlineInputBorder(),
                    errorText: _errorText != null ? "" : null,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                    helperText: l10n.heightRangeHint(
                      AppSettingsState.minHeightCm.toStringAsFixed(0),
                      AppSettingsState.maxHeightCm.toStringAsFixed(0),
                    ),
                    helperMaxLines: 2,
                    suffixIcon: _cmController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: l10n.clearField,
                            onPressed: () {
                              setState(() {
                                _cmController.clear();
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
                    setState(() => _errorText = null);
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
                        textInputAction: TextInputAction.next,
                        autofocus: false,
                        decoration: InputDecoration(
                          labelText: l10n.feetLabel,
                          suffixText: 'ft',
                          border: const OutlineInputBorder(),
                          errorText: _errorText != null ? "" : null,
                          errorStyle: const TextStyle(height: 0, fontSize: 0),
                          suffixIcon: _feetController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: l10n.clearField,
                                  onPressed: () {
                                    setState(() {
                                      _feetController.clear();
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
                          setState(() => _errorText = null);
                        },
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: TextField(
                        controller: _inchesController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.inchesLabel,
                          suffixText: 'in',
                          border: const OutlineInputBorder(),
                          errorText: _errorText != null ? "" : null,
                          errorStyle: const TextStyle(height: 0, fontSize: 0),
                          suffixIcon: _inchesController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: l10n.clearField,
                                  onPressed: () {
                                    setState(() {
                                      _inchesController.clear();
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
                          setState(() => _errorText = null);
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      AppAnalytics.logSettingsHeightDialogCancelled();
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
