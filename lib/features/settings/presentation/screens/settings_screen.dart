import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:balance/core/presentation/widgets/app_top_bar.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/l10n/app_localizations.dart';

import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';

import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/widgets/components/csv_import_preview_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/sections/settings_data_coordinator.dart';
import 'package:balance/features/settings/presentation/widgets/sections/settings_sections_layout.dart';

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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocListener<AppSettingsBloc, AppSettingsState>(
        listenWhen: (previous, current) =>
            !previous.isHealthSyncEnabled && current.isHealthSyncEnabled,
        listener: (context, state) {
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

                  return CustomScrollView(
                    slivers: [
                      AppTopBar(title: l10n.settingsTitle),
                      SliverSafeArea(
                        top: false,
                        sliver: SliverToBoxAdapter(
                          child: ClampedLayout(
                            maxWidth: context.standardContentMaxWidth,
                            padding: EdgeInsets.fromLTRB(
                              context.contentHorizontalPadding,
                              12,
                              context.contentHorizontalPadding,
                              32,
                            ),
                            child: SettingsSectionsLayout(
                              state: state,
                              isBiometricAvailable: _isBiometricAvailable,
                              onHeightTap: () =>
                                  SettingsDataCoordinator.showHeightSheet(
                                    context,
                                  ),
                              onTargetWeightTap: () =>
                                  SettingsDataCoordinator.showTargetWeightSheet(
                                    context,
                                  ),
                              onThemeTap: () =>
                                  SettingsDataCoordinator.showThemeSelection(
                                    context,
                                  ),
                              onUnitTap: () =>
                                  SettingsDataCoordinator.showUnitSelection(
                                    context,
                                  ),
                              onNotificationsChanged: (v) {
                                AppAnalytics.logSettingsReminderToggled(
                                  enabled: v,
                                );
                                context.read<AppSettingsBloc>().add(
                                  ToggleNotifications(v),
                                );
                              },
                              onNotificationTimeTap: () =>
                                  SettingsDataCoordinator.selectNotificationTime(
                                    context,
                                    state.notificationTime,
                                  ),
                              onHealthSyncChanged: (v) {
                                AppAnalytics.logSettingsHealthSyncToggled(v);
                                context.read<AppSettingsBloc>().add(
                                  ToggleHealthSync(v),
                                );
                              },
                              onInstallHealthConnect: () {
                                AppAnalytics.logSettingsHealthConnectInstallClicked();
                                SettingsDataCoordinator.showHealthConnectInstall(
                                  context,
                                );
                              },
                              onBiometricChanged: (v) =>
                                  SettingsDataCoordinator.handleBiometricToggle(
                                    context,
                                    v,
                                  ),
                              onImportTap: () =>
                                  SettingsDataCoordinator.handleImportCsv(
                                    context,
                                  ),
                              onExportTap: () =>
                                  SettingsDataCoordinator.exportCsv(context),
                              onWipeTap: () =>
                                  SettingsDataCoordinator.showWipeConfirmation(
                                    context,
                                  ),
                              onBmiCategoriesTap: () =>
                                  SettingsDataCoordinator.showBmiLegendDialog(
                                    context,
                                  ),
                              onPrivacyPolicyTap: () =>
                                  SettingsDataCoordinator.openPrivacyPolicy(
                                    context,
                                  ),
                              onLicensesTap: () =>
                                  SettingsDataCoordinator.showLicenses(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onWeightStateChange(BuildContext context, WeightState state) async {
    if (state is CsvAnalysisError) {
      AppAnalytics.logDialogCsvAnalysisError(state.errorType.name);
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
      AppAnalytics.logSettingsCsvImportCompleted(state.importedCount);
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
}
