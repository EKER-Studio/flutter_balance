import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational input field for weight measurements with localized unit labels and error messaging.
class WeightInputField extends StatelessWidget {
  final TextEditingController controller;
  final MeasurementUnit unit;
  final String? weightError;
  final ValueChanged<String> onChanged;

  const WeightInputField({
    super.key,
    required this.controller,
    required this.unit,
    required this.weightError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          autofocus: false,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: unit == MeasurementUnit.imperial
                ? l10n.weightInLbLabel
                : l10n.weightInKgLabel,
            hintText: l10n.weightHint,
            border: const OutlineInputBorder(),
            errorText: weightError != null ? "" : null,
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: l10n.clearField,
                    onPressed: () {
                      controller.clear();
                      onChanged('');
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
          onChanged: onChanged,
        ),
        if (weightError != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8.0, start: 12.0),
            child: Text(
              weightError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12.0,
              ),
            ),
          ),
      ],
    );
  }
}
