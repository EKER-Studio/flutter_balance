import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/widgets/pill_segmented_control.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/features/settings/presentation/utils/weight_goal_mode_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_step_layout.dart';

/// Form widget for Step 4 of the onboarding wizard: setting an optional
/// target weight with a goal mode (lose, maintain, gain) and a live view
/// of the remaining delta to reach it.
class StepTargetWeight extends StatefulWidget {
  final MeasurementUnit unit;

  final double? initialTargetWeightKg;

  final WeightGoalMode initialGoalMode;

  /// Initial weight in kg logged in the previous step, used to display the
  /// remaining delta to the entered target (e.g. "-5.0 kg to target").
  final double? initialWeightKg;

  /// Callback invoked when the user submits or skips this step.
  ///
  /// Passes the target weight in kg (or `null` if omitted) and the selected goal mode.
  final void Function(double? targetWeightKg, WeightGoalMode goalMode) onNext;

  const StepTargetWeight({
    super.key,
    required this.unit,
    this.initialTargetWeightKg,
    this.initialGoalMode = WeightGoalMode.lose,
    this.initialWeightKg,
    required this.onNext,
  });

  @override
  State<StepTargetWeight> createState() => _StepTargetWeightState();
}

class _StepTargetWeightState extends State<StepTargetWeight> {
  late final TextEditingController _weightController;
  final FocusNode _focusNode = FocusNode();
  late WeightGoalMode _selectedMode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialGoalMode;

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

  /// Formats the remaining delta in the active unit according to the selected
  /// goal mode, or returns `null` when no initial weight or valid target is set.
  String? _buildDeltaText(AppLocalizations l10n) {
    final initialWeight = widget.initialWeightKg;
    if (initialWeight == null || initialWeight <= 0) return null;

    final targetKg = _parseTargetWeightKg();
    if (targetKg == null) return null;

    final isImperial = widget.unit == MeasurementUnit.imperial;
    final unitSuffix = isImperial ? 'lbs' : 'kg';

    switch (_selectedMode) {
      case WeightGoalMode.lose:
        if (initialWeight <= targetKg) return null;
        final distKg = initialWeight - targetKg;
        final formatted = isImperial
            ? kgToLbs(distKg).toStringAsFixed(1)
            : distKg.toStringAsFixed(1);
        return '$formatted $unitSuffix ${l10n.toTarget}';

      case WeightGoalMode.gain:
        if (initialWeight >= targetKg) return null;
        final distKg = targetKg - initialWeight;
        final formatted = isImperial
            ? kgToLbs(distKg).toStringAsFixed(1)
            : distKg.toStringAsFixed(1);
        return '+$formatted $unitSuffix ${l10n.toTarget}';

      case WeightGoalMode.maintain:
        final distKg = (initialWeight - targetKg).abs();
        final thresholdKg = isImperial ? lbsToKg(2.2) : 1.0;
        if (distKg <= thresholdKg) {
          return l10n.goalModeMaintainDesc;
        }
        final formatted = isImperial
            ? kgToLbs(distKg).toStringAsFixed(1)
            : distKg.toStringAsFixed(1);
        final sign = initialWeight > targetKg ? '+' : '-';
        return '$sign$formatted $unitSuffix ${l10n.toTarget}';
    }
  }

  /// Parses the target weight input into kilograms, or `null` when empty or
  /// invalid.
  double? _parseTargetWeightKg() {
    final text = _weightController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;

    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) return null;

    final weightKg = widget.unit == MeasurementUnit.imperial
        ? lbsToKg(parsed)
        : parsed;

    if (weightKg > 500) return null;
    return weightKg;
  }

  void _validate(String value) {
    AppAnalytics.logOnboardingTargetWeightInputChanged(value.trim().isNotEmpty);
    final trimmed = value.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) {
      if (_errorText != null) {
        setState(() => _errorText = null);
      }
      return;
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      AppAnalytics.logOnboardingTargetWeightValidationError('invalid_number');
      if (_errorText == null) {
        setState(
          () => _errorText = AppLocalizations.of(context).invalidPositiveNumber,
        );
      }
    } else {
      final weightKg = widget.unit == MeasurementUnit.imperial
          ? lbsToKg(parsed)
          : parsed;
      if (weightKg > 500) {
        AppAnalytics.logOnboardingTargetWeightValidationError('range_error');
        if (_errorText == null) {
          setState(
            () =>
                _errorText = AppLocalizations.of(context).invalidPositiveNumber,
          );
        }
      } else {
        if (_errorText != null) {
          setState(() => _errorText = null);
        }
      }
    }
  }

  /// Invokes [StepTargetWeight.onNext] with the parsed target weight (or
  /// `null` when the field was left empty) and selected goal mode.
  void _handleNext() {
    final weightKg = _parseTargetWeightKg();
    widget.onNext(weightKg, _selectedMode);
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

    return OnboardingStepLayout(
      title: l10n.targetWeightOptionalTitle,
      subtitle: l10n.targetWeightStepSubtitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PillSegmentedControl<WeightGoalMode>(
            selectedValue: _selectedMode,
            onValueChanged: (mode) {
              setState(() {
                _selectedMode = mode;
              });
            },
            segments: [
              PillSegment(value: WeightGoalMode.lose, label: l10n.goalModeLose),
              PillSegment(
                value: WeightGoalMode.maintain,
                label: l10n.goalModeMaintain,
              ),
              PillSegment(value: WeightGoalMode.gain, label: l10n.goalModeGain),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _selectedMode.localizedDescription(context),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
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
        ],
      ),
      footer: FilledButton(
        onPressed: isNextEnabled ? _handleNext : null,
        child: Text(l10n.next),
      ),
    );
  }
}
