import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/utils/crash_log.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/integrations/csv/csv_exporter.dart';
import 'package:balance/core/integrations/csv/csv_importer.dart';
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
import 'package:balance/presentation/utils/app_theme_mode_localizer.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:balance/presentation/widgets/app_top_bar.dart';
import 'package:balance/features/settings/presentation/widgets/target_weight_dialog.dart';
import 'dart:io';

import 'package:balance/features/settings/presentation/widgets/height_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/section_header.dart';
import 'package:balance/features/settings/presentation/widgets/profile_section.dart';
import 'package:balance/features/settings/presentation/widgets/application_section.dart';
import 'package:balance/features/settings/presentation/widgets/integrations_section.dart';
import 'package:balance/features/settings/presentation/widgets/security_section.dart';
import 'package:balance/features/settings/presentation/widgets/data_section.dart';
import 'package:balance/features/settings/presentation/widgets/help_section.dart';

/// A widget that provides a screen for managing profile, application, security, and data settings.
///
/// It provides controls for adjusting the user's height and target weight, as well as changing the theme, measurement unit, daily reminder, biometric lock, and managing CSV import/export/wipe functionality. On wide layouts, the sections are arranged in a two-column grid.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// The state for [SettingsScreen] that manages dialogs and CSV import/export/wipe flows.
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
          // is set to true only after the OS permission is granted.
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
                                                  SectionHeader(
                                                    label: l10n.profileSection,
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
                                                    label:
                                                        l10n.applicationSection,
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
                                                      label:
                                                          l10n.securitySection,
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
                                                    const SizedBox(height: 24),
                                                  ],
                                                  SectionHeader(
                                                    label: l10n.dataSection,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  DataSection(
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
                                            if (state.isBiometricSupported) ...[
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
                                                  _importCsv(context),
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
    );
  }

  /// Shows the height dialog and persists the entered value to both the [AppSettingsBloc] and [WeightBloc].
  ///
  /// This ensures that BMI calculations and user profile data remain synchronized.
  void _showHeightDialog(BuildContext dialogContext) async {
    final currentHeight = dialogContext.read<AppSettingsBloc>().state.height;

    final result = await showDialog<double>(
      context: dialogContext,
      builder: (ctx) => HeightDialog(currentValue: currentHeight),
    );

    if (result == null || !mounted) return;

    context.read<AppSettingsBloc>().add(UpdateHeight(result));
    context.read<WeightBloc>().add(UpdateUserHeight(result));
  }

  /// Shows the target weight dialog and persists the result on confirm.
  ///
  /// The value is updated in the [AppSettingsBloc] so that progress calculations reflect the new target.
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
  ///
  /// The selected mode is saved to the [AppSettingsBloc] to immediately update the visual style of the application.
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
  ///
  /// The selected unit is persisted via the [AppSettingsBloc] so that all weight values are formatted correctly.
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
  ///
  /// This prevents accidental deletion of all user records by requiring explicit intent before calling [_wipeDatabase].
  void _showWipeConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_forever_outlined, size: 28, color: errorColor),
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
              await _wipeDatabase();
            },
            style: FilledButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: Text(l10n.wipeDataButton),
          ),
        ],
      ),
    );
  }

  /// Clears all weight entries and resets every app setting.
  ///
  /// The outcome snackbar is shown only once the wipe has actually completed, because BLoC events are processed asynchronously and a failing clear surfaces as a [WeightError] state instead of a thrown exception.
  Future<void> _wipeDatabase() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isError
                ? WeightErrorType.wipeFailed.localizedMessage(l10n)
                : l10n.dataWipedSuccess,
          ),
          backgroundColor: isError
              ? theme.colorScheme.error
              : theme.colorScheme.tertiary,
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

  /// Picks a CSV file, parses it via [CsvImporter], and bulk-imports the resulting entries into [WeightBloc].
  ///
  /// It uses a file picker to select the file, reads its contents, and provides visual feedback via snackbars upon success or failure.
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
  ///
  /// Generates a CSV file containing all records and invokes the native share sheet so the user can save or distribute the data.
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

  /// Shares the on-device crash log via the system share sheet.
  ///
  /// Reads the log file from the application documents directory and invokes the share sheet, or informs the user if no crash log has been recorded yet.
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

  /// Toggles the daily reminder via the [AppSettingsBloc].
  ///
  /// This requests OS notification permission and schedules or cancels the reminder based on the [enabled] state.
  void _handleNotificationToggle(BuildContext context, bool enabled) {
    context.read<AppSettingsBloc>().add(ToggleNotifications(enabled));
  }

  /// Toggles health sync via the [AppSettingsBloc].
  ///
  /// This requests native health permissions when enabling. When the user disables the sync, a brief informational message explains how to fully revoke access. A denied permission request is surfaced separately via a snackbar whose "Open Settings" action redirects to the OS health permissions page.
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

  /// Shows a dialog explaining that Health Connect must be installed before sync can be enabled.
  ///
  /// Provides an action button that redirects the user to the Play Store listing for Health Connect.
  void _showHealthConnectInstallDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.monitor_heart_outlined,
          size: 28,
          color: Theme.of(context).colorScheme.primary,
        ),
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
  ///
  /// Checks for hardware availability and prompts the user for authentication. The lock is only enabled if the authentication is successful.
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

  /// Shows the time picker and persists the chosen reminder time.
  ///
  /// The new schedule is confirmed with a `SnackBar` and updated in the [AppSettingsBloc].
  Future<void> _selectNotificationTime(
    BuildContext context,
    ({int hour, int minute}) initialTimeRecord,
  ) async {
    final initialTime = TimeOfDay(
      hour: initialTimeRecord.hour,
      minute: initialTimeRecord.minute,
    );
    final newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (newTime != null && context.mounted) {
      final l10n = AppLocalizations.of(context);
      context.read<AppSettingsBloc>().add(
        UpdateNotificationTime((hour: newTime.hour, minute: newTime.minute)),
      );
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
