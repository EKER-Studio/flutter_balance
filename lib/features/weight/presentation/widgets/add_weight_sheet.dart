import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';

/// Modal bottom sheet form for adding a new weight measurement.
class AddWeightSheet extends StatefulWidget {
  /// Creates [AddWeightSheet].
  const AddWeightSheet({super.key});

  @override
  State<AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends State<AddWeightSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.addWeight,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: l10n.weightInKgLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.weightCannotBeEmpty;
                }
                final weight = double.tryParse(
                  value.trim().replaceAll(',', '.'),
                );
                if (weight == null) {
                  return l10n.enterValidNumber;
                }
                if (weight < 20 || weight > 300) {
                  return l10n.weightRangeError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.noteLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _onSave,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final weight = double.tryParse(
        _weightController.text.trim().replaceAll(',', '.'),
      );
      if (weight == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).enterValidNumber),
          ),
        );
        return;
      }
      final note = _noteController.text.isEmpty ? null : _noteController.text;
      context.read<WeightBloc>().add(AddWeight(weightKg: weight, note: note));
      Navigator.of(context).pop();
    }
  }
}
