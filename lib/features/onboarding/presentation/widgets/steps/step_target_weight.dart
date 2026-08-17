
import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';

/// Form widget for Step 4 of the onboarding wizard: setting an optional
/// target weight with a live view of the remaining delta to reach it.
///
/// Skipping is allowed: an empty field passes `null` through [onNext], which
/// the wizard screen forwards to `AppSettingsBloc` as a cleared target
/// weight. Valid input is non-empty and within 0-500 of the active unit (kg
/// or lbs, converted internally); invalid values disable the Next button and
/// show an inline error. When a valid target and the previous step's initial
/// weight are present, a delta line shows how far the target is, or a goal
///// achieved notice when it is already met.
class StepTargetWeight extends StatefulWidget {
  /// The user's active measurement unit system.
  final MeasurementUnit unit;

  /// Initial target weight in kg (if already set).
  final double? initialTargetWeightKg;

  /// Initial weight in kg logged in the previous step, used to display the
  /// remaining delta to the entered target (e.g. "-5.0 kg to target").
  final double? initialWeightKg;

  /// Callback invoked when the user submits or skips this step.
  ///
  /// Passes the target weight in kg, or `null` if no target weight is set.
  final void Function(double? targetWeightKg) onNext;

  /// Creates a [StepTargetWeight] widget.
  const StepTargetWeight({
    super.key,
    required this.unit,
    this.initialTargetWeightKg,
    this.initialWeightKg,
    required this.onNext,
  });

  @override
  State<StepTargetWeight> createState() => _StepTargetWeightState();
}

class _StepTargetWeightState extends State<StepTargetWeight> {
  late final TextEditingController _weightController;
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();

    // Request focus after the step's frame renders so the keyboard opens
    // exactly when the step becomes visible, never while it is offstage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });

    String initialText = '';
    if (widget.initialTargetWeightKg != null &&
        widget.initialTargetWeightKg! > 0) {
      if (widget.unit == MeasurementUnit.imperial) {
        final lbs = kgToLbs(widget.initialTargetWeightKg!);
        initialText = lbs.toStringAsFixed(1);
      } else {
        initialText = widget.initialTargetWeightKg!.toStringAsFixed(1);
      }
    }

    _weightController = TextEditingController(text: initialText);
    _weightController.addListener(_handleWeightInputChanged);
  }

  @override
  void dispose() {
    _weightController.removeListener(_handleWeightInputChanged);
    _weightController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Rebuilds the step on every keystroke so the live target delta stays in
  /// sync with the input.
  void _handleWeightInputChanged() {
    setState(() {});
  }

  /// Formats the remaining delta (initial weight minus target) in the active
  /// unit, or returns `null` when no initial weight or valid target is set.
  String? _buildDeltaText(AppLocalizations l10n) {
    final initialWeight = widget.initialWeightKg;
    if (initialWeight == null || initialWeight <= 0) return null;

    final targetKg = _parseTargetWeightKg();
    if (targetKg == null) return null;

    if (initialWeight <= targetKg) {
      return '🏆 ${l10n.goalAchieved}';
    }

    final distKg = initialWeight - targetKg;
    final formatted = widget.unit == MeasurementUnit.imperial
        ? kgToLbs(distKg).toStringAsFixed(1)
        : distKg.toStringAsFixed(1);
    final unitSuffix = widget.unit == MeasurementUnit.imperial ? 'lbs' : 'kg';
    return '$formatted $unitSuffix ${l10n.toTarget}';
  }

  /// Parses the target weight input into kilograms, or `null` when empty or
  /// invalid.
  double? _parseTargetWeightKg() {
    final text = _weightController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;

    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0 || parsed > 500) return null;

    if (widget.unit == MeasurementUnit.imperial) {
      return lbsToKg(parsed);
    }
    return parsed;
  }

  /// Validates [value] on every keystroke and updates the inline error text.
  void _validate(String value) {
    final trimmed = value.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) {
      if (_errorText != null) {
        setState(() => _errorText = null);
      }
      return;
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0 || parsed > 500) {
      if (_errorText == null) {
        setState(
          () => _errorText = AppLocalizations.of(context).invalidPositiveNumber,
        );
      }
    } else {
      if (_errorText != null) {
        setState(() => _errorText = null);
      }
    }
  }

  /// Invokes [StepTargetWeight.onNext] with the parsed target weight (or
  /// `null` when the field was left empty).
  void _handleNext() {
    final weightKg = _parseTargetWeightKg();
    widget.onNext(weightKg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isImperial = widget.unit == MeasurementUnit.imperial;
    final unitSuffix = isImperial ? 'lbs' : 'kg';

    final isError = _errorText != null;
    final isNextEnabled = !isError;
    final deltaText = _buildDeltaText(l10n);

    final errorOutline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
    );

    return ClampedLayout(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.targetWeightOptionalTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            l10n.targetWeightStepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24.0),
          TextField(
            key: const Key('target_weight_input'),
            controller: _weightController,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${l10n.targetWeightDialogTitle} ($unitSuffix)',
              suffixText: unitSuffix,
              enabledBorder: isError ? errorOutline : null,
              focusedBorder: isError ? errorOutline : null,
            ),
            onChanged: _validate,
            onSubmitted: (_) {
              if (isNextEnabled) _handleNext();
            },
          ),
          const SizedBox(height: 8),
          Text(
            isError ? _errorText! : l10n.targetWeightOptionalHint,
            style: TextStyle(
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: isError ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          if (deltaText != null) ...[
            const SizedBox(height: 8),
            Text(
              key: const Key('target_delta_text'),
              deltaText,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48.0),
            child: FilledButton(
              onPressed: isNextEnabled ? _handleNext : null,
              child: Text(l10n.next),
            ),
          ),
        ],
      ),
    );
  }
}
