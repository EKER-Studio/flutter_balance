import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              'Add Weight',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Waga nie może być pusta';
                }
                final weight = double.tryParse(
                  value.trim().replaceAll(',', '.'),
                );
                if (weight == null) {
                  return 'Wprowadź poprawną liczbę';
                }
                if (weight < 20 || weight > 300) {
                  return 'Waga musi być z zakresu od 20 do 300 kg';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _onSave, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text);
      final note = _noteController.text.isEmpty ? null : _noteController.text;
      context.read<WeightBloc>().add(AddWeight(weightKg: weight, note: note));
      Navigator.of(context).pop();
    }
  }
}
