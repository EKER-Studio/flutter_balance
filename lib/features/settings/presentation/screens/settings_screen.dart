import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/utils/crash_log.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:balance/core/services/biometric_service.dart';
import 'package:balance/core/services/health_service.dart';
import 'package:balance/core/utils/csv_exporter.dart';
import 'package:balance/core/utils/csv_importer.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/utils/measurement_unit_localizer.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/presentation/utils/app_theme_mode_localizer.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:balance/presentation/widgets/app_top_bar.dart';
import 'package:balance/features/settings/presentation/widgets/target_weight_dialog.dart';
import 'dart:io';

/// Dialog for entering the user's height in centimeters.
class _HeightDialog extends StatefulWidget {
  /// The currently stored height in cm, or `null` if not set yet.
  final double? currentValue;

  /// Creates a [_HeightDialog] pre-filled with [currentValue].
  const _HeightDialog({required this.currentValue});

  @override
  State<_HeightDialog> createState() => _HeightDialogState();
}

class _HeightDialogState extends State<_HeightDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.currentValue != null && widget.currentValue! > 0)
          ? widget.currentValue!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Validates the entered height and pops it as a result on success.
  void _handleSave() {
    FocusScope.of(context).unfocus();
    final text = _controller.text.trim().replaceAll(',', '.');
    final height = double.tryParse(text);

    if (text.isEmpty ||
        height == null ||
        height < AppSettingsState.minHeightCm ||
        height > AppSettingsState.maxHeightCm) {
      setState(() {
        _errorText = AppLocalizations.of(context).heightRangeError;
      });
      return;
    }

    Navigator.of(context).pop(height);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isError = _errorText != null;

    return AlertDialog(
      title: Text(l10n.heightDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
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
                enabledBorder: isError
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                          width: 2,
                        ),
                      )
                    : null,
                focusedBorder: isError
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                          width: 2,
                        ),
                      )
                    : null,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 8),
            Text(
              isError ? _errorText! : '50 – 250 cm',
              style: TextStyle(
                color: isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isError ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
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

/// Screen for managing profile, application, security, and data settings.
///
/// Provides height, target weight, theme, measurement unit, daily reminder,
/// biometric lock, and CSV import/export/wipe controls. On wide layouts the
/// sections are arranged in a two-column grid.
class SettingsScreen extends StatefulWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// State owning the settings screen dialogs and CSV import/export/wipe flows.
class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<bool> _isBiometricAvailable;

  @override
  void initState() {
    super.initState();
    _isBiometricAvailable = BiometricService.instance.canAuthenticate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,

      body: BlocListener<AppSettingsBloc, AppSettingsState>(
        listenWhen: (previous, current) =>
            !previous.isHealthSyncEnabled && current.isHealthSyncEnabled,
        listener: (context, state) {
          // Health sync was just activated: pull the weight history recorded
          // in Apple Health / Health Connect (e.g. by a smart scale) into the
          // local database. The transition only fires when the permission
          // request succeeded, because [AppSettingsState.isHealthSyncEnabled]
          // is set to true exclusively after a granted grant.
          context.read<WeightBloc>().add(const SyncHealthEntries());
        },
        child: BlocListener<AppSettingsBloc, AppSettingsState>(
          listenWhen: (previous, current) =>
              !previous.healthPermissionDenied &&
              current.healthPermissionDenied,
          listener: (context, state) {
            // Health permission denied: show a snackbar whose action redirects
            // the user to the OS health permissions page, where the grant can be
            // made from the system settings.
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(l10n.healthPermissionDenied),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: l10n.openSettings,
                    onPressed: NativeHealthService.instance.openSystemSettings,
                  ),
                ),
              );
          },
          child: BlocListener<AppSettingsBloc, AppSettingsState>(
            listenWhen: (previous, current) =>
                !previous.notificationPermissionDenied &&
                current.notificationPermissionDenied,
            listener: (context, state) {
              // Notification permission denied: show a snackbar whose action
              // redirects the user to the OS app settings page.
              final l10n = AppLocalizations.of(context);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l10n.notificationPermissionDenied),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: l10n.openSettings,
                      onPressed: openAppSettings,
                    ),
                  ),
                );
            },
            child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
              builder: (context, state) {
                final l10n = AppLocalizations.of(context);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    final maxContentWidth = isWide ? 900.0 : 600.0;
                    final horizontalPadding = isWide ? 24.0 : 16.0;

                    return CustomScrollView(
                      slivers: [
                        AppTopBar(title: l10n.settingsTitle),
                        SliverSafeArea(
                          top: false,
                          sliver: SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxContentWidth,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.settingsSubtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (isWide)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _SectionHeader(
                                                    label: l10n.profileSection,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _ProfileSection(
                                                    state: state,
                                                    l10n: l10n,
                                                    onHeightTap: () =>
                                                        _showHeightDialog(
                                                          context,
                                                        ),
                                                    onTargetWeightTap: () =>
                                                        _showTargetWeightDialog(
                                                          context,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  _SectionHeader(
                                                    label:
                                                        l10n.applicationSection,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _ApplicationSection(
                                                    state: state,
                                                    l10n: l10n,
                                                    onThemeTap: () =>
                                                        _showThemeSelection(
                                                          context,
                                                        ),
                                                    onUnitTap: () =>
                                                        _showUnitSelection(
                                                          context,
                                                        ),
                                                    onNotificationsChanged: (v) =>
                                                        _handleNotificationToggle(
                                                          context,
                                                          v,
                                                        ),
                                                    onNotificationTimeTap: () =>
                                                        _selectNotificationTime(
                                                          context,
                                                          state
                                                              .notificationTime,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  _SectionHeader(
                                                    label: l10n
                                                        .integrationsSection,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _IntegrationsSection(
                                                    state: state,
                                                    l10n: l10n,
                                                    onHealthSyncChanged: (v) =>
                                                        _handleHealthSyncToggle(
                                                          context,
                                                          v,
                                                        ),
                                                    onInstallHealthConnect: () =>
                                                        _showHealthConnectInstallDialog(
                                                          context,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 24),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (state
                                                      .isBiometricSupported) ...[
                                                    _SectionHeader(
                                                      label:
                                                          l10n.securitySection,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _SecuritySection(
                                                      state: state,
                                                      l10n: l10n,
                                                      isBiometricAvailable:
                                                          _isBiometricAvailable,
                                                      onBiometricChanged: (v) =>
                                                          _handleBiometricToggle(
                                                            context,
                                                            v,
                                                          ),
                                                      biometricsAvailableLabel:
                                                          l10n.biometricDesc,
                                                      biometricsNotAvailableLabel:
                                                          l10n.biometricsNotAvailable,
                                                    ),
                                                    const SizedBox(height: 24),
                                                  ],
                                                  _SectionHeader(
                                                    label: l10n.dataSection,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _DataSection(
                                                    l10n: l10n,
                                                    onImportTap: () =>
                                                        _importCsv(context),
                                                    onExportTap: () =>
                                                        _exportCsv(context),
                                                    onWipeTap: () =>
                                                        _showWipeConfirmation(
                                                          context,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  _SectionHeader(
                                                    label: l10n.helpSection,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _HelpSection(
                                                    l10n: l10n,
                                                    onCrashLogTap: () =>
                                                        _sendCrashLog(context),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _SectionHeader(
                                              label: l10n.profileSection,
                                            ),
                                            const SizedBox(height: 8),
                                            _ProfileSection(
                                              state: state,
                                              l10n: l10n,
                                              onHeightTap: () =>
                                                  _showHeightDialog(context),
                                              onTargetWeightTap: () =>
                                                  _showTargetWeightDialog(
                                                    context,
                                                  ),
                                            ),
                                            const SizedBox(height: 16),
                                            _SectionHeader(
                                              label: l10n.applicationSection,
                                            ),
                                            const SizedBox(height: 8),
                                            _ApplicationSection(
                                              state: state,
                                              l10n: l10n,
                                              onThemeTap: () =>
                                                  _showThemeSelection(context),
                                              onUnitTap: () =>
                                                  _showUnitSelection(context),
                                              onNotificationsChanged: (v) =>
                                                  _handleNotificationToggle(
                                                    context,
                                                    v,
                                                  ),
                                              onNotificationTimeTap: () =>
                                                  _selectNotificationTime(
                                                    context,
                                                    state.notificationTime,
                                                  ),
                                            ),
                                            const SizedBox(height: 16),
                                            _SectionHeader(
                                              label: l10n.integrationsSection,
                                            ),
                                            const SizedBox(height: 8),
                                            _IntegrationsSection(
                                              state: state,
                                              l10n: l10n,
                                              onHealthSyncChanged: (v) =>
                                                  _handleHealthSyncToggle(
                                                    context,
                                                    v,
                                                  ),
                                              onInstallHealthConnect: () =>
                                                  _showHealthConnectInstallDialog(
                                                    context,
                                                  ),
                                            ),
                                            const SizedBox(height: 16),
                                            if (state.isBiometricSupported) ...[
                                              _SectionHeader(
                                                label: l10n.securitySection,
                                              ),
                                              const SizedBox(height: 8),
                                              _SecuritySection(
                                                state: state,
                                                l10n: l10n,
                                                isBiometricAvailable:
                                                    _isBiometricAvailable,
                                                onBiometricChanged: (v) =>
                                                    _handleBiometricToggle(
                                                      context,
                                                      v,
                                                    ),
                                                biometricsAvailableLabel:
                                                    l10n.biometricDesc,
                                                biometricsNotAvailableLabel:
                                                    l10n.biometricsNotAvailable,
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            _SectionHeader(
                                              label: l10n.dataSection,
                                            ),
                                            const SizedBox(height: 8),
                                            _DataSection(
                                              l10n: l10n,
                                              onImportTap: () =>
                                                  _importCsv(context),
                                              onExportTap: () =>
                                                  _exportCsv(context),
                                              onWipeTap: () =>
                                                  _showWipeConfirmation(
                                                    context,
                                                  ),
                                            ),
                                            const SizedBox(height: 16),
                                            _SectionHeader(
                                              label: l10n.helpSection,
                                            ),
                                            const SizedBox(height: 8),
                                            _HelpSection(
                                              l10n: l10n,
                                              onCrashLogTap: () =>
                                                  _sendCrashLog(context),
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 32),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the height dialog and persists the entered value to both the
  /// [AppSettingsBloc] and [WeightBloc].
  void _showHeightDialog(BuildContext dialogContext) async {
    final currentHeight = dialogContext.read<AppSettingsBloc>().state.height;

    final result = await showDialog<double>(
      context: dialogContext,
      builder: (ctx) => _HeightDialog(currentValue: currentHeight),
    );

    if (result == null || !mounted) return;

    context.read<AppSettingsBloc>().add(UpdateHeight(result));
    context.read<WeightBloc>().add(UpdateUserHeight(result));
  }

  /// Shows the target weight dialog and persists the result on confirm.
  void _showTargetWeightDialog(BuildContext dialogContext) async {
    final currentTarget = dialogContext
        .read<AppSettingsBloc>()
        .state
        .targetWeight;
    final unit = dialogContext.read<AppSettingsBloc>().state.measurementUnit;

    final result = await showDialog<dynamic>(
      context: dialogContext,
      builder: (ctx) =>
          TargetWeightDialog(currentValue: currentTarget, unit: unit),
    );

    if (!mounted) return;

    if (result != null) {
      if (result == 'clear') {
        context.read<AppSettingsBloc>().add(const TargetWeightChanged(null));
      } else if (result is double) {
        context.read<AppSettingsBloc>().add(TargetWeightChanged(result));
      }
    }
  }

  /// Shows the theme mode selection dialog and applies the chosen mode.
  void _showThemeSelection(BuildContext dialogContext) {
    final state = dialogContext.read<AppSettingsBloc>().state;
    final l10n = AppLocalizations.of(dialogContext);
    showDialog(
      context: dialogContext,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.theme),
        children: [
          RadioGroup<AppThemeMode>(
            groupValue: state.themeMode,
            onChanged: (value) {
              if (value == null) return;
              ctx.read<AppSettingsBloc>().add(UpdateTheme(value));
              Navigator.pop(ctx);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in AppThemeMode.values)
                  RadioListTile<AppThemeMode>(
                    title: Text(_themeLabel(mode, l10n)),
                    value: mode,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the measurement unit selection dialog and applies the chosen unit.
  void _showUnitSelection(BuildContext dialogContext) {
    final state = dialogContext.read<AppSettingsBloc>().state;
    final l10n = AppLocalizations.of(dialogContext);
    showDialog(
      context: dialogContext,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.measurementUnit),
        children: [
          RadioGroup<MeasurementUnit>(
            groupValue: state.measurementUnit,
            onChanged: (value) {
              if (value == null) return;
              ctx.read<AppSettingsBloc>().add(UpdateMeasurementUnit(value));
              Navigator.pop(ctx);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final unit in MeasurementUnit.values)
                  RadioListTile<MeasurementUnit>(
                    title: Text(_unitLabel(unit, l10n)),
                    value: unit,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppThemeMode mode, AppLocalizations l10n) =>
      mode.localizedName(l10n);

  String _unitLabel(MeasurementUnit unit, AppLocalizations l10n) =>
      unit.localizedName(l10n);

  /// Asks for confirmation before wiping all stored weight data.
  void _showWipeConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

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
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _wipeDatabase();
            },
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text(l10n.wipeDataButton),
          ),
        ],
      ),
    );
  }

  /// Clears all weight entries and resets every app setting.
  Future<void> _wipeDatabase() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final weightBloc = context.read<WeightBloc>();
    final appSettingsBloc = context.read<AppSettingsBloc>();

    try {
      weightBloc.add(const ClearAllWeightData());
      appSettingsBloc.add(const ResetAppSettings());
      weightBloc.add(const RefreshWeightData());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.dataWipedSuccess),
          backgroundColor: theme.colorScheme.tertiary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorWipingData(e.toString())),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  /// Picks a CSV file, parses it via [CsvImporter], and bulk-imports the
  /// resulting entries into [WeightBloc].
  Future<void> _importCsv(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final fileContent = await File(filePath).readAsString();

      final csvResult = await CsvImporter.parse(fileContent);
      final entries = csvResult.entries;
      final skippedRows = csvResult.skippedRows;

      if (entries.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).importNoDataFound),
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        context.read<WeightBloc>().add(ImportWeightEntries(entries));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).importSuccess(entries.length),
            ),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );

        if (skippedRows > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).skippedRows(skippedRows),
              ),
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

  /// Exports the current weight entries via [CsvExporter] and shares the file.
  Future<void> _exportCsv(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final weightState = context.read<WeightBloc>().state;
      final entries = weightState is WeightLoaded
          ? weightState.entries
          : <WeightEntry>[];

      if (entries.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.exportNoData)));
        }
        return;
      }

      final exportedFile = await CsvExporter.exportToFile(entries);

      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        final originRect = box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null;

        await Share.shareXFiles(
          [XFile(exportedFile.path)],
          subject: 'Balance Export CSV',
          sharePositionOrigin: originRect,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.exportSuccess),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportError(e.toString()))));
      }
    }
  }

  /// Shares the on-device crash log via the system share sheet, or informs
  /// the user when no crash log has been recorded yet.
  Future<void> _sendCrashLog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$crashLogFileName');
      if (!await file.exists() || await file.length() == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.crashLogEmpty)));
        }
        return;
      }

      if (!context.mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      final originRect = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: l10n.sendCrashLog,
        sharePositionOrigin: originRect,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.shareCrashLogError(e.toString()))),
          );
      }
    }
  }

  /// Toggles the daily reminder via the [AppSettingsBloc], which requests OS
  /// notification permission and schedules or cancels the reminder.
  void _handleNotificationToggle(BuildContext context, bool enabled) {
    context.read<AppSettingsBloc>().add(ToggleNotifications(enabled));
  }

  /// Toggles health sync via the [AppSettingsBloc], which requests native
  /// health permissions when enabling. When the user disables the sync, a
  /// brief informational message explains how to fully revoke access.
  ///
  /// A denied permission request is surfaced separately via a snackbar whose
  /// "Open Settings" action redirects to the OS health permissions page.
  void _handleHealthSyncToggle(BuildContext context, bool enabled) {
    context.read<AppSettingsBloc>().add(ToggleHealthSync(enabled));
    if (!enabled) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).healthSyncDisabledInfo),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  /// Shows a dialog explaining that Health Connect must be installed before
  /// sync can be enabled, with an action opening its Play Store listing.
  void _showHealthConnectInstallDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.healthConnectRequiredTitle),
        content: Text(l10n.healthConnectRequiredSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              NativeHealthService.instance.installHealthConnect();
            },
            child: Text(l10n.installFromPlayStore),
          ),
        ],
      ),
    );
  }

  /// Toggles the biometric lock, authenticating the user before enabling it.
  Future<void> _handleBiometricToggle(
    BuildContext context,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AppSettingsBloc>();

    if (enabled) {
      // Guard: verify a device credential (biometric or OS PIN/pattern/
      // password) is available before prompting.
      final available = await BiometricService.instance.canAuthenticate();
      if (!available) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.biometricsNotAvailable)));
        }
        return;
      }

      final result = await BiometricService.instance.authenticate(
        localizedReason: l10n.biometricAuthReason,
        authMessages: BiometricService.createAuthMessages(l10n),
      );
      if (result == BiometricAuthResult.success) {
        bloc.add(const UpdateBiometricLock(true));
      } else if (BiometricService.isTerminalFailure(result)) {
        // Biometrics became unavailable between the availability check and
        // the authentication call (e.g. user deleted fingerprints mid-flow).
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.biometricsNotAvailable)));
        }
      } else {
        // User canceled or failed — do not enable the lock.
        bloc.add(const UpdateBiometricLock(false));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.biometricAuthFailed)));
        }
      }
    } else {
      bloc.add(const UpdateBiometricLock(false));
    }
  }

  /// Shows the time picker and persists the chosen reminder time, confirming
  /// the new schedule with a [SnackBar].
  Future<void> _selectNotificationTime(
    BuildContext context,
    TimeOfDay initialTime,
  ) async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (newTime != null && context.mounted) {
      final l10n = AppLocalizations.of(context);
      context.read<AppSettingsBloc>().add(UpdateNotificationTime(newTime));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.reminderTimeSet(newTime.format(context))),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

/// Section header label rendered above each settings group.
class _SectionHeader extends StatelessWidget {
  /// The section title text.
  final String label;

  /// Creates a [_SectionHeader] with the given [label].
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        label,
        style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}

/// Tappable settings list tile with icon, title, optional supporting text and
/// trailing value, error styling, and keyboard focus ring for accessibility.
class _CustomSettingsTile extends StatefulWidget {
  /// Leading icon rendered inside a circular container.
  final IconData icon;

  /// Tile title text.
  final String title;

  /// Optional supporting text shown below the title.
  final String? subtitle;

  /// Optional trailing value text shown before the chevron.
  final String? valueText;

  /// Callback invoked when the tile is tapped; `null` disables the tap.
  final VoidCallback? onTap;

  /// Whether the tile is rendered with error colors.
  final bool isError;

  /// Whether a trailing chevron icon is shown.
  final bool showChevron;

  /// Optional parent section label prepended to the accessibility label.
  final String? sectionLabel;

  /// Creates a [_CustomSettingsTile] with the given properties.
  const _CustomSettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.valueText,
    this.onTap,
    this.isError = false,
    this.showChevron = true,
    this.sectionLabel,
  });

  @override
  State<_CustomSettingsTile> createState() => _CustomSettingsTileState();
}

class _CustomSettingsTileState extends State<_CustomSettingsTile> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final leading = ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          widget.icon,
          size: 24,
          color: widget.isError
              ? colorScheme.error
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final titleWidget = Text(
      widget.title,
      style: textTheme.bodyLarge?.copyWith(
        color: widget.isError ? colorScheme.error : colorScheme.onSurface,
      ),
    );

    final subtitleWidget = widget.subtitle != null
        ? Text(
            widget.subtitle!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        : null;

    Widget? trailingWidget;
    if (widget.valueText != null) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.valueText!,
              style: textTheme.bodyMedium?.copyWith(
                color: widget.isError
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.showChevron)
            ExcludeSemantics(
              child: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    } else if (widget.showChevron) {
      trailingWidget = ExcludeSemantics(
        child: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      );
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    final labelParts = <String>[
      if (widget.sectionLabel != null) widget.sectionLabel!,
      widget.title,
      if (widget.subtitle != null) widget.subtitle!,
    ];

    final tile = Semantics(
      button: true,
      label: labelParts.length > 1 ? labelParts.join(', ') : null,
      child: Focus(
        focusNode: _focusNode,
        child: Theme(
          data: Theme.of(context).copyWith(
            highlightColor: widget.isError
                ? colorScheme.error.withValues(alpha: 0.12)
                : colorScheme.primary.withValues(alpha: 0.08),
            splashColor: widget.isError
                ? colorScheme.error.withValues(alpha: 0.12)
                : colorScheme.primary.withValues(alpha: 0.12),
          ),
          child: ListTile(
            shape: shape,
            hoverColor: widget.isError
                ? colorScheme.error.withValues(alpha: 0.08)
                : colorScheme.onSurface.withValues(alpha: 0.08),
            focusColor: widget.isError
                ? colorScheme.error.withValues(alpha: 0.12)
                : colorScheme.onSurface.withValues(alpha: 0.12),
            minLeadingWidth: 40,
            minVerticalPadding: 8,
            onTap: widget.onTap,
            leading: leading,
            title: titleWidget,
            subtitle: subtitleWidget,
            trailing: trailingWidget,
          ),
        ),
      ),
    );

    if (_isFocused) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary, width: 2),
        ),
        child: tile,
      );
    }

    return tile;
  }
}

/// Settings list tile with a trailing switch, used for boolean preferences.
class _CustomSwitchTile extends StatefulWidget {
  /// Leading icon rendered inside a circular container.
  final IconData icon;

  /// Tile title text.
  final String title;

  /// Optional supporting text below the title.
  final String? subtitle;

  /// The current switch state.
  final bool value;

  /// Callback invoked when the switch is toggled; `null` disables it.
  final ValueChanged<bool>? onChanged;

  /// Optional parent section label prepended to the accessibility label.
  final String? sectionLabel;

  /// Creates a [_CustomSwitchTile] with the given properties.
  const _CustomSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.sectionLabel,
  });

  @override
  State<_CustomSwitchTile> createState() => _CustomSwitchTileState();
}

class _CustomSwitchTileState extends State<_CustomSwitchTile> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final leading = ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(widget.icon, size: 24, color: colorScheme.onSurfaceVariant),
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    final tile = Semantics(
      toggled: widget.value,
      label: widget.sectionLabel != null
          ? '${widget.sectionLabel}, ${widget.title}'
          : widget.title,
      child: Focus(
        focusNode: _focusNode,
        child: SwitchListTile.adaptive(
          shape: shape,
          tileColor: Colors.transparent,
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
          minVerticalPadding: 8,
          title: Text(
            widget.title,
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          ),
          subtitle: widget.subtitle != null
              ? Text(
                  widget.subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          secondary: leading,
          value: widget.value,
          onChanged: widget.onChanged,
        ),
      ),
    );

    if (_isFocused) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary, width: 2),
        ),
        child: tile,
      );
    }

    return tile;
  }
}

/// Profile settings group with height and target weight tiles.
class _ProfileSection extends StatelessWidget {
  /// The current app settings state driving the displayed values.
  final AppSettingsState state;

  /// Localized strings for this section.
  final AppLocalizations l10n;

  /// Callback invoked when the height tile is tapped.
  final VoidCallback onHeightTap;

  /// Callback invoked when the target weight tile is tapped.
  final VoidCallback onTargetWeightTap;

  /// Creates a [_ProfileSection] with the given dependencies.
  const _ProfileSection({
    required this.state,
    required this.l10n,
    required this.onHeightTap,
    required this.onTargetWeightTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final heightValue = (state.height != null && state.height! > 0)
        ? formatHeight(state.height!, state.measurementUnit)
        : l10n.heightNotSetLabel;

    final targetWeightValue = state.targetWeight != null
        ? formatWeight(state.targetWeight!, state.measurementUnit)
        : l10n.notSet;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          _CustomSettingsTile(
            icon: Icons.height,
            title: l10n.height,
            valueText: heightValue,
            sectionLabel: l10n.profileSection,
            onTap: onHeightTap,
          ),
          _CustomSettingsTile(
            icon: Icons.flag_outlined,
            title: l10n.targetWeight,
            valueText: targetWeightValue,
            sectionLabel: l10n.profileSection,
            onTap: onTargetWeightTap,
          ),
        ],
      ),
    );
  }
}

/// Application settings group with unit, theme, and reminder controls.
class _ApplicationSection extends StatelessWidget {
  /// The current app settings state driving the displayed values.
  final AppSettingsState state;

  /// Localized strings for this section.
  final AppLocalizations l10n;

  /// Callback invoked when the theme tile is tapped.
  final VoidCallback onThemeTap;

  /// Callback invoked when the measurement unit tile is tapped.
  final VoidCallback onUnitTap;

  /// Callback invoked when the notifications switch is toggled.
  final ValueChanged<bool> onNotificationsChanged;

  /// Callback invoked when the reminder time tile is tapped.
  final VoidCallback onNotificationTimeTap;

  /// Creates an [_ApplicationSection] with the given dependencies.
  const _ApplicationSection({
    required this.state,
    required this.l10n,
    required this.onThemeTap,
    required this.onUnitTap,
    required this.onNotificationsChanged,
    required this.onNotificationTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeLabel = state.themeMode.localizedName(l10n);
    final unitLabel = state.measurementUnit.localizedName(l10n);
    final notificationTimeText = state.notificationTime.format(context);

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          _CustomSettingsTile(
            icon: Icons.straighten,
            title: l10n.measurementUnit,
            valueText: unitLabel,
            sectionLabel: l10n.applicationSection,
            onTap: onUnitTap,
          ),
          _CustomSettingsTile(
            icon: Icons.palette_outlined,
            title: l10n.theme,
            valueText: themeLabel,
            sectionLabel: l10n.applicationSection,
            onTap: onThemeTap,
          ),
          _CustomSwitchTile(
            icon: Icons.notifications_outlined,
            title: l10n.dailyReminder,
            subtitle: l10n.dailyReminderDesc,
            sectionLabel: l10n.applicationSection,
            value: state.notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),
          if (state.notificationsEnabled)
            _CustomSettingsTile(
              icon: Icons.access_time_outlined,
              title: l10n.reminderTime,
              valueText: notificationTimeText,
              sectionLabel: l10n.applicationSection,
              onTap: onNotificationTimeTap,
            ),
        ],
      ),
    );
  }
}

/// Integrations settings group with the health sync switch.
class _IntegrationsSection extends StatelessWidget {
  /// The current app settings state driving the displayed values.
  final AppSettingsState state;

  /// Localized strings for this section.
  final AppLocalizations l10n;

  /// Callback invoked when the health sync switch is toggled.
  final ValueChanged<bool> onHealthSyncChanged;

  /// Callback invoked when the tile asks to install Health Connect.
  ///
  /// Only invoked on Android when the health API is unavailable.
  final VoidCallback onInstallHealthConnect;

  /// Creates an [_IntegrationsSection] with the given dependencies.
  ///
  /// @param state The current app settings state driving the displayed values.
  /// @param l10n Localized strings for this section.
  /// @param onHealthSyncChanged Callback invoked when the health sync switch is toggled.
  /// @param onInstallHealthConnect Callback invoked when the tile asks to install Health Connect.
  const _IntegrationsSection({
    required this.state,
    required this.l10n,
    required this.onHealthSyncChanged,
    required this.onInstallHealthConnect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final apiAvailable = state.isHealthApiAvailable;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final showInstallAction = !apiAvailable && isAndroid;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: showInstallAction
          ? _CustomSettingsTile(
              icon: Icons.monitor_heart_outlined,
              title: l10n.healthSync,
              subtitle: l10n.healthSyncUnavailable,
              sectionLabel: l10n.integrationsSection,
              onTap: onInstallHealthConnect,
            )
          : _CustomSwitchTile(
              icon: Icons.monitor_heart_outlined,
              title: l10n.healthSync,
              subtitle: apiAvailable
                  ? l10n.healthSyncDesc
                  : l10n.healthSyncUnavailable,
              sectionLabel: l10n.integrationsSection,
              value: state.isHealthSyncEnabled,
              onChanged: apiAvailable ? onHealthSyncChanged : null,
            ),
    );
  }
}

/// Security settings group with the biometric lock switch.
class _SecuritySection extends StatelessWidget {
  /// The current app settings state driving the displayed values.
  final AppSettingsState state;

  /// Localized strings for this section.
  final AppLocalizations l10n;

  /// Future resolving to whether biometric hardware is available.
  final Future<bool> isBiometricAvailable;

  /// Callback invoked when the biometric lock switch is toggled.
  final ValueChanged<bool> onBiometricChanged;

  /// Label shown when biometrics are available.
  final String biometricsAvailableLabel;

  /// Label shown when biometrics are not available.
  final String biometricsNotAvailableLabel;

  /// Creates a [_SecuritySection] with the given dependencies.
  const _SecuritySection({
    required this.state,
    required this.l10n,
    required this.isBiometricAvailable,
    required this.onBiometricChanged,
    required this.biometricsAvailableLabel,
    required this.biometricsNotAvailableLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: FutureBuilder<bool>(
        future: isBiometricAvailable,
        builder: (context, snapshot) {
          final available = snapshot.data ?? false;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return _CustomSwitchTile(
            icon: Icons.fingerprint,
            title: l10n.biometricLock,
            subtitle: available
                ? biometricsAvailableLabel
                : biometricsNotAvailableLabel,
            sectionLabel: l10n.securitySection,
            value: available ? state.isBiometricLockEnabled : false,
            onChanged: isLoading
                ? null
                : (available ? onBiometricChanged : null),
          );
        },
      ),
    );
  }
}

/// Data settings group with CSV import, export, and wipe controls.
class _DataSection extends StatelessWidget {
  /// Localized strings for this section.
  final AppLocalizations l10n;

  /// Callback invoked when the import tile is tapped.
  final VoidCallback onImportTap;

  /// Callback invoked when the export tile is tapped.
  final VoidCallback onExportTap;

  /// Callback invoked when the wipe data tile is tapped.
  final VoidCallback onWipeTap;

  /// Creates a [_DataSection] with the given dependencies.
  const _DataSection({
    required this.l10n,
    required this.onImportTap,
    required this.onExportTap,
    required this.onWipeTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          _CustomSettingsTile(
            icon: Icons.file_upload_outlined,
            title: l10n.importCsv,
            sectionLabel: l10n.dataSection,
            onTap: onImportTap,
          ),
          _CustomSettingsTile(
            icon: Icons.file_download_outlined,
            title: l10n.exportCsv,
            sectionLabel: l10n.dataSection,
            onTap: onExportTap,
          ),
          _CustomSettingsTile(
            icon: Icons.delete_forever_outlined,
            title: l10n.wipeData,
            isError: true,
            showChevron: false,
            sectionLabel: l10n.dataSection,
            onTap: onWipeTap,
          ),
        ],
      ),
    );
  }
}

/// Help settings group with the crash log sharing and app version tiles.
class _HelpSection extends StatefulWidget {
  /// Localized strings for this section.
  final AppLocalizations l10n;

  /// Callback invoked when the send crash log tile is tapped.
  final VoidCallback onCrashLogTap;

  /// Creates a [_HelpSection] with the given dependencies.
  const _HelpSection({required this.l10n, required this.onCrashLogTap});

  @override
  State<_HelpSection> createState() => _HelpSectionState();
}

class _HelpSectionState extends State<_HelpSection> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = widget.l10n;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '';
          return Column(
            children: [
              _CustomSettingsTile(
                icon: Icons.bug_report_outlined,
                title: l10n.sendCrashLog,
                sectionLabel: l10n.helpSection,
                onTap: widget.onCrashLogTap,
              ),
              _CustomSettingsTile(
                icon: Icons.info_outline,
                title: l10n.appVersion,
                subtitle: version,
                showChevron: false,
                sectionLabel: l10n.helpSection,
              ),
            ],
          );
        },
      ),
    );
  }
}
