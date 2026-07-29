import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:pure_weight/core/services/biometric_service.dart';
import 'package:pure_weight/core/utils/csv_importer.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'dart:io';

/// Dialog for setting the height.
class _HeightDialog extends StatefulWidget {
  final double currentValue;

  const _HeightDialog({required this.currentValue});

  @override
  State<_HeightDialog> createState() => _HeightDialogState();
}

class _HeightDialogState extends State<_HeightDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue > 0
          ? widget.currentValue.toStringAsFixed(0)
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
    final text = _controller.text.trim();
    final height = double.tryParse(text);

    if (text.isEmpty || height == null || height <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).invalidPositiveNumber),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).pop(height);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.heightDialogTitle),
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
                labelText: l10n.heightCmLabel,
                hintText: l10n.heightHint,
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

/// Dialog for setting the target weight with proper lifecycle management.
class _TargetWeightDialog extends StatefulWidget {
  final double? currentValue;
  final MeasurementUnit unit;

  const _TargetWeightDialog({required this.currentValue, required this.unit});

  @override
  State<_TargetWeightDialog> createState() => _TargetWeightDialogState();
}

class _TargetWeightDialogState extends State<_TargetWeightDialog> {
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
    final text = _controller.text.trim();
    final weight = double.tryParse(text);

    if (text.isEmpty) {
      Navigator.of(context).pop(null);
      return;
    }

    if (weight != null && weight > 0) {
      Navigator.of(context).pop(weight);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).invalidPositiveNumber),
          backgroundColor: Colors.orange,
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

/// Settings screen for theme, measurement unit, and database management.
class SettingsScreen extends StatefulWidget {
  /// Creates [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).settingsTitle)),
      body: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                context,
                title: l10n.theme,
                children: AppThemeMode.values
                    .map(
                      (mode) => _buildRadioTile(
                        context,
                        value: mode,
                        groupValue: state.themeMode,
                        onChanged: (value) {
                          context.read<AppSettingsBloc>().add(
                            UpdateTheme(value!),
                          );
                        },
                        label: _themeLabel(mode, l10n),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: l10n.measurementUnit,
                children: MeasurementUnit.values
                    .map(
                      (unit) => _buildRadioTile(
                        context,
                        value: unit,
                        groupValue: state.measurementUnit,
                        onChanged: (value) {
                          context.read<AppSettingsBloc>().add(
                            UpdateMeasurementUnit(value!),
                          );
                        },
                        label: _unitLabel(unit, l10n),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: l10n.height,
                children: [
                  ListTile(
                    leading: const Icon(Icons.height, color: Colors.blue),
                    title: Text(l10n.height),
                    subtitle: Text(
                      state.height > 0
                          ? '${state.height.toStringAsFixed(0)} cm'
                          : l10n.notSet,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showHeightDialog(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: l10n.goal,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.flag_outlined,
                      color: Colors.green,
                    ),
                    title: Text(l10n.targetWeight),
                    subtitle: Text(
                      state.targetWeight != null
                          ? formatWeight(
                              state.targetWeight!,
                              state.measurementUnit,
                            )
                          : l10n.notSet,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showTargetWeightDialog(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: l10n.security,
                children: [
                  FutureBuilder<bool>(
                    future: BiometricService.instance.isAvailable(),
                    builder: (context, snapshot) {
                      final isAvailable = snapshot.data ?? false;
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting;
                      return SwitchListTile(
                        title: Text(l10n.biometricLock),
                        subtitle: Text(
                          isAvailable
                              ? l10n.biometricDesc
                              : l10n.biometricsNotAvailable,
                        ),
                        value: isAvailable
                            ? state.isBiometricLockEnabled
                            : false,
                        onChanged: isLoading
                            ? null
                            : (value) async {
                                if (isAvailable) {
                                  context.read<AppSettingsBloc>().add(
                                    UpdateBiometricLock(value),
                                  );
                                }
                              },
                        secondary: const Icon(Icons.fingerprint),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: l10n.database,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.file_upload_outlined,
                      color: Colors.blue,
                    ),
                    title: Text(l10n.importCsv),
                    subtitle: Text(l10n.importCsvDesc),
                    onTap: () => _importCsv(context),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: Text(l10n.wipeData),
                    subtitle: Text(l10n.wipeDataDesc),
                    onTap: () => _showWipeConfirmation(context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildRadioTile<T>(
    BuildContext context, {
    required T value,
    required T? groupValue,
    required ValueChanged<T?> onChanged,
    required String label,
  }) {
    return ListTile(
      leading: RadioGroup<T>(
        groupValue: groupValue,
        onChanged: onChanged,
        child: Radio<T>(value: value),
      ),
      title: Text(label),
    );
  }

  String _themeLabel(AppThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      AppThemeMode.system => l10n.system,
      AppThemeMode.light => l10n.light,
      AppThemeMode.dark => l10n.dark,
    };
  }

  String _unitLabel(MeasurementUnit unit, AppLocalizations l10n) {
    return switch (unit) {
      MeasurementUnit.metric => l10n.metricUnit,
      MeasurementUnit.imperial => l10n.imperialUnit,
    };
  }

  void _showHeightDialog(BuildContext context) async {
    final currentHeight = context.read<AppSettingsBloc>().state.height;

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => _HeightDialog(currentValue: currentHeight),
    );

    if (result == null || !mounted) return;

    // ignore: use_build_context_synchronously
    context.read<AppSettingsBloc>().add(UpdateHeight(result));
    // ignore: use_build_context_synchronously
    context.read<WeightBloc>().add(UpdateUserHeight(result));
  }

  void _showTargetWeightDialog(BuildContext context) async {
    final currentTarget = context.read<AppSettingsBloc>().state.targetWeight;
    final unit = context.read<AppSettingsBloc>().state.measurementUnit;

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) =>
          _TargetWeightDialog(currentValue: currentTarget, unit: unit),
    );

    if (!mounted) return;

    if (result != null) {
      // ignore: use_build_context_synchronously
      context.read<AppSettingsBloc>().add(TargetWeightChanged(result));
    } else {
      // ignore: use_build_context_synchronously
      context.read<AppSettingsBloc>().add(const TargetWeightChanged(null));
    }
  }

  void _showWipeConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.wipeData),
        content: Text(l10n.wipeDataContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _wipeDatabase(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.wipeDataButton),
          ),
        ],
      ),
    );
  }

  Future<void> _wipeDatabase(BuildContext context) async {
    try {
      await context.read<WeightRepository>().clearAllData();
      await HydratedBloc.storage.clear();

      if (context.mounted) {
        context.read<WeightBloc>().add(const RefreshWeightData());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).dataWipedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).errorWipingData(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _importCsv(BuildContext context) async {
    final repository = context.read<WeightRepository>();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final filePath = result.files.single.path!;
      final fileContent = await File(filePath).readAsString();

      // Parse CSV and obtain both entries and skipped rows count.
      final csvResult = await CsvImporter.parse(fileContent);
      final entries = csvResult.entries;
      final skippedRows = csvResult.skippedRows;

      if (entries.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).importNoDataFound),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final importedCount = await repository.bulkImportEntries(entries);

      if (context.mounted) {
        if (importedCount > 0) {
          context.read<WeightBloc>().add(const RefreshWeightData());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).importSuccess(importedCount),
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Inform user about any rows that were skipped due to validation errors.
          if (skippedRows > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Skipped $skippedRows rows'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).importFailed),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).importError(e.toString()),
            ),
          ),
        );
      }
    }
  }
}
