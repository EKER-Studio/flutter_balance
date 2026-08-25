import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/csv/csv_exporter.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
import 'package:balance/core/presentation/utils/picker_helpers.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/widgets/components/health_connect_install_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/components/theme_selection_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/components/unit_selection_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/components/height_sheet.dart';
import 'package:balance/features/settings/presentation/widgets/components/target_weight_sheet.dart';
import 'package:balance/features/settings/presentation/widgets/components/wipe_data_dialog.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_dialog.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Helper coordinator for dialogs and side-effects on the Settings screen.
class SettingsDataCoordinator {
  const SettingsDataCoordinator._();

  /// Shows the height configuration bottom sheet.
  static Future<void> showHeightSheet(BuildContext context) async {
    final settingsState = context.read<AppSettingsBloc>().state;
    AppAnalytics.logSettingsHeightDialogOpened(
      currentHeightCm: settingsState.height,
      unit: settingsState.measurementUnit.name,
    );
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => HeightSheet(
        currentValue: settingsState.height,
        measurementUnit: settingsState.measurementUnit,
      ),
    );

    if (result == null || !context.mounted) return;

    AppAnalytics.logSettingsHeightSaved(result);
    context.read<AppSettingsBloc>().add(UpdateHeight(result));
    context.read<WeightBloc>().add(UpdateUserHeight(result));
  }

  /// Shows the target weight configuration bottom sheet.
  static Future<void> showTargetWeightSheet(BuildContext context) async {
    final settingsBloc = context.read<AppSettingsBloc>();
    final settingsState = settingsBloc.state;
    AppAnalytics.logSettingsTargetWeightDialogOpened(
      currentTargetKg: settingsState.targetWeight,
      unit: settingsState.measurementUnit.name,
    );

    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => TargetWeightSheet(
        currentValueKg: settingsState.targetWeight,
        measurementUnit: settingsState.measurementUnit,
      ),
    );

    if (!context.mounted || result == null) return;

    if (result == 'clear') {
      AppAnalytics.logSettingsTargetWeightCleared();
      context.read<AppSettingsBloc>().add(const TargetWeightChanged(null));
    } else if (result is double) {
      final targetKg = settingsState.measurementUnit == MeasurementUnit.imperial
          ? lbsToKg(result)
          : result;
      AppAnalytics.logSettingsTargetWeightSaved(targetKg);
      context.read<AppSettingsBloc>().add(TargetWeightChanged(targetKg));
    }
  }

  /// Shows the theme mode selection dialog.
  static void showThemeSelection(BuildContext context) {
    final state = context.read<AppSettingsBloc>().state;
    ThemeSelectionDialog.show(
      context,
      currentMode: state.themeMode,
      onSelected: (mode) {
        AppAnalytics.logSettingsThemeChanged(mode.name);
        context.read<AppSettingsBloc>().add(UpdateTheme(mode));
      },
    );
  }

  /// Shows the measurement unit selection dialog.
  static void showUnitSelection(BuildContext context) {
    final state = context.read<AppSettingsBloc>().state;
    UnitSelectionDialog.show(
      context,
      currentUnit: state.measurementUnit,
      onSelected: (unit) {
        AppAnalytics.logSettingsUnitChanged(unit.name);
        context.read<AppSettingsBloc>().add(UpdateMeasurementUnit(unit));
      },
    );
  }

  /// Shows the Health Connect install dialog on Android.
  static void showHealthConnectInstall(BuildContext context) {
    HealthConnectInstallDialog.show(context);
  }

  /// Shows the system file picker to select a CSV file.
  static Future<void> handleImportCsv(BuildContext context) async {
    AppAnalytics.logSettingsCsvImportClicked();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) {
      AppAnalytics.logSettingsCsvImportPickerCancelled();
      return;
    }
    if (!context.mounted) return;

    context.read<WeightBloc>().add(
      AnalyzeCsvFile(filePath: result.files.single.path!),
    );
  }

  /// Confirms and executes database wipe.
  static Future<void> showWipeConfirmation(BuildContext context) async {
    AppAnalytics.logDialogWipeDataOpened();
    final confirmed = await WipeDataDialog.show(context);
    if (confirmed && context.mounted) {
      AppAnalytics.logSettingsWipeDataConfirmed();
      await wipeDatabase(context);
    }
  }

  /// Clears all weight entries and resets every app setting.
  static Future<void> wipeDatabase(BuildContext context) async {
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

      if (!context.mounted) return;
      final isError = outcome is WeightError;
      if (isError) {
        AppAnalytics.logSettingsWipeFailed(outcome.errorType.name);
      } else {
        AppAnalytics.logSettingsWipeSuccess();
      }
      AppSnackBar.show(
        context,
        message: isError
            ? WeightErrorType.wipeFailed.localizedMessage(l10n)
            : l10n.dataWipedSuccess,
        type: isError ? SnackBarType.error : SnackBarType.success,
      );
    } catch (e, stack) {
      AppAnalytics.logSettingsWipeFailed(e.toString());
      AppCrashReporter.recordError(
        e,
        stack,
        reason: 'Wiping data failed in Settings',
        fatal: false,
      );
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.errorWipingData(e.toString()),
        type: SnackBarType.error,
      );
    }
  }

  /// Exports weight entries to CSV and shares the file.
  static Future<void> exportCsv(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    AppAnalytics.logSettingsCsvExportClicked();
    try {
      final weightState = context.read<WeightBloc>().state;
      final entries = switch (weightState) {
        WeightLoaded() => weightState.entries,
        WeightError() => weightState.entries,
        _ => <WeightEntry>[],
      };

      if (entries.isEmpty) {
        AppAnalytics.logSettingsCsvExportNoDataAlert();
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.exportNoData,
            type: SnackBarType.warning,
          );
        }
        return;
      }

      final exportedFile = await CsvExporter.exportToFile(List.of(entries));
      AppAnalytics.logSettingsCsvExportSuccess(entries.length);

      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        final originRect = box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null;

        await Share.shareXFiles(
          [XFile(exportedFile.path)],
          subject: AppLocalizations.of(context).csvExportShareSubject,
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
    } catch (e, stack) {
      AppAnalytics.logSettingsCsvExportFailed(e.toString());
      AppCrashReporter.recordError(
        e,
        stack,
        reason: 'Exporting CSV failed in Settings',
        fatal: false,
      );
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: l10n.exportError(e.toString()),
          type: SnackBarType.error,
        );
      }
    }
  }

  /// Opens the Privacy Policy URL in an in-app browser view.
  static Future<void> openPrivacyPolicy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    AppAnalytics.logSettingsPrivacyPolicyClicked();
    final uri = Uri.parse(
      'https://piotrekert90.github.io/eker-studio/privacy-policy',
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: 'Failed to launch privacy policy URL',
        fatal: false,
      );
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: l10n.privacyPolicyOpenError,
          type: SnackBarType.error,
        );
      }
    }
  }

  /// Handles biometric lock switch toggle.
  static Future<void> handleBiometricToggle(
    BuildContext context,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AppSettingsBloc>();
    AppAnalytics.logSettingsBiometricsToggled(enabled);

    if (enabled) {
      final available = await BiometricService.instance.canAuthenticate();
      if (!available) {
        AppAnalytics.logSettingsBiometricsUnavailableAlert();
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.biometricsNotAvailable,
            type: SnackBarType.error,
          );
        }
        return;
      }

      AppAnalytics.logSettingsBiometricsAuthStarted();
      final result = await BiometricService.instance.authenticate(
        localizedReason: l10n.biometricAuthReason,
        authMessages: BiometricService.createAuthMessages(l10n),
      );
      if (result == BiometricAuthResult.success) {
        AppAnalytics.logSettingsBiometricsAuthSuccess();
        bloc.add(const UpdateBiometricLock(true));
      } else if (BiometricService.isTerminalFailure(result)) {
        AppAnalytics.logSettingsBiometricsAuthFailed(result.name);
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.biometricsNotAvailable,
            type: SnackBarType.error,
          );
        }
      } else {
        AppAnalytics.logSettingsBiometricsAuthFailed(result.name);
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

  /// Opens safe time picker to adjust notification reminder time.
  static Future<void> selectNotificationTime(
    BuildContext context,
    ({int hour, int minute}) initialTimeRecord,
  ) async {
    final initialTime = TimeOfDay(
      hour: initialTimeRecord.hour,
      minute: initialTimeRecord.minute,
    );
    AppAnalytics.logSettingsReminderTimePickerOpened(
      hour: initialTimeRecord.hour,
      minute: initialTimeRecord.minute,
    );
    final newTime = await showSafeTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (newTime != null && context.mounted) {
      AppAnalytics.logSettingsReminderTimeChanged(
        hour: newTime.hour,
        minute: newTime.minute,
      );
      context.read<AppSettingsBloc>().add(
        UpdateNotificationTime((hour: newTime.hour, minute: newTime.minute)),
      );
    } else {
      AppAnalytics.logSettingsReminderTimePickerCancelled();
    }
  }

  /// Shows the standard Flutter open-source licenses page.
  static Future<void> showLicenses(BuildContext context) async {
    AppAnalytics.logSettingsOpenSourceLicensesClicked();
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;

    showLicensePage(
      context: context,
      applicationName: 'Balance',
      applicationVersion: packageInfo.version,
      applicationIcon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Icon(
          Icons.monitor_weight_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      applicationLegalese: '© 2026 EKER Studio',
    );
  }

  /// Shows the BMI category legend and reference ranges dialog.
  static void showBmiLegendDialog(BuildContext context) {
    AppAnalytics.logDialogBmiLegendOpened();
    WeightState? weightState;
    try {
      weightState = context.read<WeightBloc>().state;
    } catch (_) {}

    AppSettingsState? settingsState;
    try {
      settingsState = context.read<AppSettingsBloc>().state;
    } catch (_) {}

    final entries = weightState?.entries ?? const [];
    final latestWeightKg = entries.isNotEmpty
        ? (entries.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime)))
              .first
              .weightKg
        : null;

    showDialog<void>(
      context: context,
      builder: (context) => BmiLegendDialog(
        latestWeightKg: latestWeightKg,
        heightCm: settingsState?.height,
      ),
    );
  }
}
