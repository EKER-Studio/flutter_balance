// Main settings screen composing profile, application, integrations, security,
// data and help sections.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/csv/csv_exporter.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
import 'package:balance/core/presentation/utils/app_theme_mode_localizer.dart';
import 'package:balance/core/presentation/utils/picker_helpers.dart';
import 'package:balance/core/presentation/widgets/app_top_bar.dart';
import 'package:balance/core/presentation/widgets/pill_segmented_control.dart';
import 'package:balance/core/utils/crash_log.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/l10n/app_localizations.dart';

import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/utils/measurement_unit_localizer.dart';
import 'package:balance/features/weight/presentation/utils/weight_error_localizer.dart';

import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/settings/presentation/widgets/application_section.dart';
import 'package:balance/features/settings/presentation/widgets/csv_import_preview_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/data_section.dart';
import 'package:balance/features/settings/presentation/widgets/height_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/help_section.dart';
import 'package:balance/features/settings/presentation/widgets/integrations_section.dart';
import 'package:balance/features/settings/presentation/widgets/profile_section.dart';
import 'package:balance/features/settings/presentation/widgets/section_header.dart';
import 'package:balance/features/settings/presentation/widgets/security_section.dart';
import 'package:balance/features/settings/presentation/widgets/target_weight_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/wipe_data_dialog.dart';

/// A widget that provides a screen for managing profile, application, security, and data settings.
///
/// It provides controls for adjusting the user's height and target weight, as well as changing the theme,
/// measurement unit, daily reminder, biometric lock, and managing CSV import/export/wipe functionality.
/// On wide layouts, the sections are arranged in a two-column grid.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// The state for [SettingsScreen] that manages dialogs and CSV import/export/wipe flows.
class _SettingsScreenState extends State<SettingsScreen> {
  /// Resolves once to whether device biometrics are available on this device;
  /// drives the security section's toggle.
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
          // in Apple Health / Health Connect into the local database.
          context.read<WeightBloc>().add(const SyncHealthEntries());
        },
        child: BlocListener<AppSettingsBloc, AppSettingsState>(
          listenWhen: (previous, current) =>
              !previous.healthPermissionDenied &&
              current.healthPermissionDenied,
          listener: (context, state) {
            final l10n = AppLocalizations.of(context);
            AppSnackBar.show(
              context,
              message: l10n.healthPermissionDenied,
              type: SnackBarType.error,
              action: SnackBarAction(
                label: l10n.openSettings,
                onPressed: NativeHealthService.instance.openSystemSettings,
              ),
            );
          },
          child: BlocListener<AppSettingsBloc, AppSettingsState>(
            listenWhen: (previous, current) =>
                !previous.notificationPermissionDenied &&
                current.notificationPermissionDenied,
            listener: (context, state) {
              final l10n = AppLocalizations.of(context);
              AppSnackBar.show(
                context,
                message: l10n.notificationPermissionDenied,
                type: SnackBarType.error,
                action: SnackBarAction(
                  label: l10n.openSettings,
                  onPressed: openAppSettings,
                ),
              );
            },
            child: BlocListener<WeightBloc, WeightState>(
              listener: _onWeightStateChange,
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
                                                    SectionHeader(
                                                      label:
                                                          l10n.profileSection,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    ProfileSection(
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
                                                    SectionHeader(
                                                      label: l10n
                                                          .applicationSection,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    ApplicationSection(
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
                                                    SectionHeader(
                                                      label: l10n
                                                          .integrationsSection,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    IntegrationsSection(
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
                                                      SectionHeader(
                                                        label: l10n
                                                            .securitySection,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      SecuritySection(
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
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                    ],
                                                    SectionHeader(
                                                      label: l10n.dataSection,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    DataSection(
                                                      l10n: l10n,
                                                      onImportTap: () =>
                                                          _handleImportCsv(),
                                                      onExportTap: () =>
                                                          _exportCsv(context),
                                                      onWipeTap: () =>
                                                          _showWipeConfirmation(
                                                            context,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 24),
                                                    SectionHeader(
                                                      label: l10n.helpSection,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    HelpSection(
                                                      l10n: l10n,
                                                      onCrashLogTap: () =>
                                                          _sendCrashLog(
                                                            context,
                                                          ),
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
                                              SectionHeader(
                                                label: l10n.profileSection,
                                              ),
                                              const SizedBox(height: 8),
                                              ProfileSection(
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
                                              SectionHeader(
                                                label: l10n.applicationSection,
                                              ),
                                              const SizedBox(height: 8),
                                              ApplicationSection(
                                                state: state,
                                                l10n: l10n,
                                                onThemeTap: () =>
                                                    _showThemeSelection(
                                                      context,
                                                    ),
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
                                              SectionHeader(
                                                label: l10n.integrationsSection,
                                              ),
                                              const SizedBox(height: 8),
                                              IntegrationsSection(
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
                                              if (state
                                                  .isBiometricSupported) ...[
                                                SectionHeader(
                                                  label: l10n.securitySection,
                                                ),
                                                const SizedBox(height: 8),
                                                SecuritySection(
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
                                              SectionHeader(
                                                label: l10n.dataSection,
                                              ),
                                              const SizedBox(height: 8),
                                              DataSection(
                                                l10n: l10n,
                                                onImportTap: () =>
                                                    _handleImportCsv(),
                                                onExportTap: () =>
                                                    _exportCsv(context),
                                                onWipeTap: () =>
                                                    _showWipeConfirmation(
                                                      context,
                                                    ),
                                              ),
                                              const SizedBox(height: 16),
                                              SectionHeader(
                                                label: l10n.helpSection,
                                              ),
                                              const SizedBox(height: 8),
                                              HelpSection(
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
      ),
    );
  }

  /// Shows the [HeightDialog] and persists the returned height (in cm).
  void _showHeightDialog(BuildContext dialogContext) async {
    final settingsState = dialogContext.read<AppSettingsBloc>().state;
    final currentHeight = settingsState.height;
    final currentUnit = settingsState.measurementUnit;

    final result = await showDialog<double>(
      context: dialogContext,
      builder: (ctx) => HeightDialog(
        currentValue: currentHeight,
        measurementUnit: currentUnit,
      ),
    );

    if (result == null || !mounted) return;

    context.read<AppSettingsBloc>().add(UpdateHeight(result));
    context.read<WeightBloc>().add(UpdateUserHeight(result));
  }

  /// Shows the system file picker to select a CSV file.
  Future<void> _handleImportCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    context.read<WeightBloc>().add(
      AnalyzeCsvFile(filePath: result.files.single.path!),
    );
  }

  void _onWeightStateChange(BuildContext context, WeightState state) async {
    if (state is CsvAnalysisError) {
      final l10n = AppLocalizations.of(context);
      String errorMessage;
      switch (state.errorType) {
        case CsvErrorType.fileTooLarge:
          errorMessage = l10n.csvImportFileTooLarge;
        case CsvErrorType.invalidFormat:
          errorMessage = l10n.csvImportInvalidFormat;
        case CsvErrorType.noEntries:
          errorMessage = l10n.csvImportNoEntries;
      }
      AppSnackBar.show(
        context,
        message: errorMessage,
        type: SnackBarType.error,
      );
    } else if (state is CsvAnalysisReady) {
      final confirmed = await CsvImportPreviewDialog.show(
        context,
        analysis: state.analysis,
      );
      if (confirmed && context.mounted) {
        context.read<WeightBloc>().add(
          ConfirmCsvImport(validEntries: state.analysis.validEntries),
        );
      }
    } else if (state is WeightImportSuccess) {
      final l10n = AppLocalizations.of(context);
      AppSnackBar.show(
        context,
        message: l10n.csvImportComplete(state.importedCount),
        type: state.importedCount == 0
            ? SnackBarType.info
            : SnackBarType.success,
      );
    }
  }

  /// Shows the [TargetWeightDialog] and applies the returned value.
  void _showTargetWeightDialog(BuildContext dialogContext) async {
    final settingsBloc = dialogContext.read<AppSettingsBloc>();
    final settingsState = settingsBloc.state;

    final result = await showDialog<dynamic>(
      context: dialogContext,
      builder: (ctx) => TargetWeightDialog(
        currentValueKg: settingsState.targetWeight,
        measurementUnit: settingsState.measurementUnit,
      ),
    );

    if (!mounted) return;

    if (result != null) {
      if (result == 'clear') {
        context.read<AppSettingsBloc>().add(const TargetWeightChanged(null));
      } else if (result is double) {
        final targetKg =
            settingsState.measurementUnit == MeasurementUnit.imperial
            ? lbsToKg(result)
            : result;
        context.read<AppSettingsBloc>().add(TargetWeightChanged(targetKg));
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
      builder: (ctx) => AlertDialog(
        title: Text(l10n.measurementUnit),
        content: PillSegmentedControl<MeasurementUnit>(
          selectedValue: state.measurementUnit,
          onValueChanged: (value) {
            ctx.read<AppSettingsBloc>().add(UpdateMeasurementUnit(value));
            Navigator.pop(ctx);
          },
          segments: [
            for (final unit in MeasurementUnit.values)
              PillSegment(value: unit, label: _unitLabel(unit, l10n)),
          ],
        ),
      ),
    );
  }

  String _themeLabel(AppThemeMode mode, AppLocalizations l10n) =>
      mode.localizedName(l10n);

  String _unitLabel(MeasurementUnit unit, AppLocalizations l10n) =>
      unit.localizedName(l10n);

  /// Asks for confirmation before wiping all stored weight data.
  Future<void> _showWipeConfirmation(BuildContext context) async {
    final confirmed = await WipeDataDialog.show(context);
    if (confirmed && mounted) {
      await _wipeDatabase();
    }
  }

  /// Clears all weight entries and resets every app setting.
  Future<void> _wipeDatabase() async {
    final l10n = AppLocalizations.of(context);
    final weightBloc = context.read<WeightBloc>();
    final appSettingsBloc = context.read<AppSettingsBloc>();

    try {
      weightBloc.add(const ClearAllWeightData());
      appSettingsBloc.add(const ResetAppSettings());
      weightBloc.add(const RefreshWeightData());

      final outcome = await weightBloc.stream
          .firstWhere(
            (state) =>
                (state is WeightLoaded && state.entries.isEmpty) ||
                (state is WeightError &&
                    state.errorType == WeightErrorType.wipeFailed),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      final isError = outcome is WeightError;
      AppSnackBar.show(
        context,
        message: isError
            ? WeightErrorType.wipeFailed.localizedMessage(l10n)
            : l10n.dataWipedSuccess,
        type: isError ? SnackBarType.error : SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.errorWipingData(e.toString()),
        type: SnackBarType.error,
      );
    }
  }

  /// Exports the current weight entries via [CsvExporter] and shares the file.
  Future<void> _exportCsv(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final weightState = context.read<WeightBloc>().state;
      final entries = switch (weightState) {
        WeightLoaded() => weightState.entries,
        WeightError() => weightState.entries,
        _ => <WeightEntry>[],
      };

      if (entries.isEmpty) {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.exportNoData,
            type: SnackBarType.warning,
          );
        }
        return;
      }

      // Kopia listy chroniąca stan BLoC przed bezpośrednią mutacją
      final exportedFile = await CsvExporter.exportToFile(List.of(entries));

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
          AppSnackBar.show(
            context,
            message: l10n.exportSuccess,
            type: SnackBarType.success,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: l10n.exportError(e.toString()),
          type: SnackBarType.error,
        );
      }
    }
  }

  /// Shares the on-device crash log via the system share sheet.
  Future<void> _sendCrashLog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$crashLogFileName');
      if (!await file.exists() || await file.length() == 0) {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.crashLogEmpty,
            type: SnackBarType.warning,
          );
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
        AppSnackBar.show(
          context,
          message: l10n.shareCrashLogError(e.toString()),
          type: SnackBarType.error,
        );
      }
    }
  }

  void _handleNotificationToggle(BuildContext context, bool enabled) {
    context.read<AppSettingsBloc>().add(ToggleNotifications(enabled));
  }

  void _handleHealthSyncToggle(BuildContext context, bool enabled) {
    context.read<AppSettingsBloc>().add(ToggleHealthSync(enabled));
  }

  void _showHealthConnectInstallDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(l10n.healthConnectRequiredTitle),
        content: SizedBox(
          width: 320,
          child: Text(l10n.healthConnectRequiredSubtitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
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

  Future<void> _handleBiometricToggle(
    BuildContext context,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AppSettingsBloc>();

    if (enabled) {
      final available = await BiometricService.instance.canAuthenticate();
      if (!available) {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.biometricsNotAvailable,
            type: SnackBarType.error,
          );
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
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.biometricsNotAvailable,
            type: SnackBarType.error,
          );
        }
      } else {
        bloc.add(const UpdateBiometricLock(false));
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.biometricAuthFailed,
            type: SnackBarType.error,
          );
        }
      }
    } else {
      bloc.add(const UpdateBiometricLock(false));
    }
  }

  Future<void> _selectNotificationTime(
    BuildContext context,
    ({int hour, int minute}) initialTimeRecord,
  ) async {
    final initialTime = TimeOfDay(
      hour: initialTimeRecord.hour,
      minute: initialTimeRecord.minute,
    );
    final newTime = await showSafeTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (newTime != null && context.mounted) {
      context.read<AppSettingsBloc>().add(
        UpdateNotificationTime((hour: newTime.hour, minute: newTime.minute)),
      );
    }
  }
}
