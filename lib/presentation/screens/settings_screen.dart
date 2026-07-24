import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/core/database/database_module.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:pure_weight/presentation/bloc/settings/measurement_unit.dart';
import 'dart:io';

/// Settings screen for theme, measurement unit, and database management.
class SettingsScreen extends StatelessWidget {
  /// Creates [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                context,
                title: 'Theme',
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
                        label: _themeLabel(mode),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'Measurement Unit',
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
                        label: _unitLabel(unit),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'Database',
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text('Wipe All Data'),
                    subtitle: const Text(
                      'This will permanently delete all your weight entries and reset app settings.',
                    ),
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

  String _themeLabel(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
  }

  String _unitLabel(MeasurementUnit unit) {
    return switch (unit) {
      MeasurementUnit.metric => 'Metric (kg, cm)',
      MeasurementUnit.imperial => 'Imperial (lb, ft/in)',
    };
  }

  void _showWipeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wipe All Data'),
        content: const Text(
          'This will permanently delete all your weight entries and reset app settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _wipeDatabase(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Wipe Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _wipeDatabase(BuildContext context) async {
    try {
      // Delete the Isar database file from disk.
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/${DatabaseModule.dbName}';

      // Delete all Isar-related files (main file, indexes, etc.).
      for (final suffix in ['', '.index', '.wal', '.shm']) {
        final file = File('$dbPath$suffix');
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Reset HydratedBloc storage to clear persisted settings.
      await HydratedBloc.storage.clear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been wiped. Restart the app.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error wiping data: $e')));
      }
    }
  }
}
