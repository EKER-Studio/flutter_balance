import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pure_weight/core/services/biometric_service.dart';
import 'package:pure_weight/core/utils/csv_exporter.dart';
import 'package:pure_weight/core/utils/csv_importer.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/utils/measurement_unit_localizer.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:pure_weight/presentation/utils/app_theme_mode_localizer.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pure_weight/presentation/widgets/app_top_bar.dart';
import 'package:pure_weight/presentation/widgets/target_weight_dialog.dart';
import 'dart:io';

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
    final text = _controller.text.trim().replaceAll(',', '.');
    final height = double.tryParse(text);

    if (text.isEmpty || height == null || height <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).invalidPositiveNumber),
          backgroundColor: Theme.of(context).colorScheme.error,
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

/// Screen for managing profile, application, security, and data settings.
class SettingsScreen extends StatefulWidget {
  /// Creates a settings screen.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<bool> _isBiometricAvailable;

  @override
  void initState() {
    super.initState();
    _isBiometricAvailable = BiometricService.instance.isAvailable();
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
      appBar: AppTopBar(title: AppLocalizations.of(context).settingsTitle),
      body: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final maxContentWidth = isWide ? 900.0 : 600.0;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          l10n.settingsSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionHeader(label: l10n.profileSection),
                                    const SizedBox(height: 8),
                                    _ProfileSection(
                                      state: state,
                                      l10n: l10n,
                                      onHeightTap: () =>
                                          _showHeightDialog(context),
                                      onTargetWeightTap: () =>
                                          _showTargetWeightDialog(context),
                                    ),
                                    const SizedBox(height: 24),
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
                                          _handleNotificationToggle(context, v),
                                      onNotificationTimeTap: () =>
                                          _selectNotificationTime(
                                            context,
                                            state.notificationTime,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionHeader(label: l10n.securitySection),
                                    const SizedBox(height: 8),
                                    _SecuritySection(
                                      state: state,
                                      l10n: l10n,
                                      isBiometricAvailable:
                                          _isBiometricAvailable,
                                      onBiometricChanged: (v) =>
                                          _handleBiometricToggle(context, v),
                                      biometricsAvailableLabel:
                                          l10n.biometricDesc,
                                      biometricsNotAvailableLabel:
                                          l10n.biometricsNotAvailable,
                                    ),
                                    const SizedBox(height: 24),
                                    _SectionHeader(label: l10n.dataSection),
                                    const SizedBox(height: 8),
                                    _DataSection(
                                      l10n: l10n,
                                      onImportTap: () => _importCsv(context),
                                      onExportTap: () => _exportCsv(context),
                                      onWipeTap: () =>
                                          _showWipeConfirmation(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(label: l10n.profileSection),
                              const SizedBox(height: 8),
                              _ProfileSection(
                                state: state,
                                l10n: l10n,
                                onHeightTap: () => _showHeightDialog(context),
                                onTargetWeightTap: () =>
                                    _showTargetWeightDialog(context),
                              ),
                              const SizedBox(height: 16),
                              _SectionHeader(label: l10n.applicationSection),
                              const SizedBox(height: 8),
                              _ApplicationSection(
                                state: state,
                                l10n: l10n,
                                onThemeTap: () => _showThemeSelection(context),
                                onUnitTap: () => _showUnitSelection(context),
                                onNotificationsChanged: (v) =>
                                    _handleNotificationToggle(context, v),
                                onNotificationTimeTap: () =>
                                    _selectNotificationTime(
                                      context,
                                      state.notificationTime,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              _SectionHeader(label: l10n.securitySection),
                              const SizedBox(height: 8),
                              _SecuritySection(
                                state: state,
                                l10n: l10n,
                                isBiometricAvailable: _isBiometricAvailable,
                                onBiometricChanged: (v) =>
                                    _handleBiometricToggle(context, v),
                                biometricsAvailableLabel: l10n.biometricDesc,
                                biometricsNotAvailableLabel:
                                    l10n.biometricsNotAvailable,
                              ),
                              const SizedBox(height: 16),
                              _SectionHeader(label: l10n.dataSection),
                              const SizedBox(height: 8),
                              _DataSection(
                                l10n: l10n,
                                onImportTap: () => _importCsv(context),
                                onExportTap: () => _exportCsv(context),
                                onWipeTap: () => _showWipeConfirmation(context),
                              ),
                            ],
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

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

  void _showTargetWeightDialog(BuildContext dialogContext) async {
    final currentTarget = dialogContext
        .read<AppSettingsBloc>()
        .state
        .targetWeight;
    final unit = dialogContext.read<AppSettingsBloc>().state.measurementUnit;

    final result = await showDialog<double>(
      context: dialogContext,
      builder: (ctx) =>
          TargetWeightDialog(currentValue: currentTarget, unit: unit),
    );

    if (!mounted) return;

    if (result != null) {
      context.read<AppSettingsBloc>().add(TargetWeightChanged(result));
    }
  }

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
      context.read<WeightBloc>().add(const ClearAllWeightData());
      context.read<AppSettingsBloc>().add(const ResetAppSettings());

      if (context.mounted) {
        context.read<WeightBloc>().add(const RefreshWeightData());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).dataWipedSuccess),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
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

  Future<void> _exportCsv(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final weightState = context.read<WeightBloc>().state;
      final entries = weightState is WeightLoaded
          ? weightState.entries
          : <WeightEntry>[];

      if (entries.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.exportNoData),
            ),
          );
        }
        return;
      }

      final exportedFile = await CsvExporter.exportToFile(entries);

      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        final originRect =
            box != null ? box.localToGlobal(Offset.zero) & box.size : null;

        await Share.shareXFiles(
          [XFile(exportedFile.path)],
          subject: 'PureWeight Export CSV',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportError(e.toString())),
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationToggle(
    BuildContext context,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AppSettingsBloc>();

    if (enabled) {
      final status = await Permission.notification.request();

      if (status.isDenied ||
          status.isPermanentlyDenied ||
          status.isRestricted) {
        bloc.add(const ToggleNotifications(false));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.notificationsDisabledOs),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: l10n.openSettings,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
    }

    bloc.add(ToggleNotifications(enabled));
  }

  Future<void> _handleBiometricToggle(
    BuildContext context,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AppSettingsBloc>();

    if (enabled) {
      // Guard: verify biometrics are enrolled before prompting.
      final available = await BiometricService.instance.isAvailable();
      if (!available) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.biometricsNotAvailable)),
          );
        }
        return;
      }

      final result = await BiometricService.instance.authenticate(
        localizedReason: l10n.biometricAuthReason,
      );
      if (result == BiometricAuthResult.success) {
        bloc.add(const UpdateBiometricLock(true));
      } else if (BiometricService.isTerminalFailure(result)) {
        // Biometrics became unavailable between the availability check and
        // the authentication call (e.g. user deleted fingerprints mid-flow).
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.biometricsNotAvailable)),
          );
        }
      } else {
        // User canceled or failed — do not enable the lock.
        bloc.add(const UpdateBiometricLock(false));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.biometricAuthFailed)),
          );
        }
      }
    } else {
      bloc.add(const UpdateBiometricLock(false));
    }
  }

  Future<void> _selectNotificationTime(
    BuildContext context,
    TimeOfDay initialTime,
  ) async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (newTime != null && context.mounted) {
      context.read<AppSettingsBloc>().add(UpdateNotificationTime(newTime));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

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

class _CustomSettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? valueText;
  final VoidCallback? onTap;
  final bool isError;
  final bool showChevron;
  final String? sectionLabel;
  const _CustomSettingsTile({
    required this.icon,
    required this.title,
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
      semanticsLabel: widget.sectionLabel != null
          ? '${widget.sectionLabel}, ${widget.title}'
          : null,
      style: textTheme.bodyLarge?.copyWith(
        color: widget.isError ? colorScheme.error : colorScheme.onSurface,
      ),
    );

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

    final tile = MergeSemantics(
      child: Focus(
        focusNode: _focusNode,
        child: Theme(
          data: Theme.of(context).copyWith(
            highlightColor: widget.isError
                ? colorScheme.errorContainer
                : colorScheme.surfaceContainerHighest,
            splashColor: widget.isError
                ? colorScheme.errorContainer
                : colorScheme.surfaceContainerHighest,
          ),
          child: ListTile(
            shape: shape,
            hoverColor: widget.isError
                ? colorScheme.errorContainer
                : colorScheme.surfaceContainerHighest,
            focusColor: widget.isError
                ? colorScheme.errorContainer
                : colorScheme.surfaceContainerHighest,
            minLeadingWidth: 40,
            minVerticalPadding: 8,
            onTap: widget.onTap,
            leading: leading,
            title: titleWidget,
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

class _CustomSwitchTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? sectionLabel;

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

    final tile = MergeSemantics(
      child: Focus(
        focusNode: _focusNode,
        child: SwitchListTile.adaptive(
          shape: shape,
          tileColor: Colors.transparent,
          hoverColor: colorScheme.surfaceContainerHighest,
          minVerticalPadding: 8,
          title: Text(
            widget.title,
            semanticsLabel: widget.sectionLabel != null
                ? '${widget.sectionLabel}, ${widget.title}'
                : null,
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

class _ProfileSection extends StatelessWidget {
  final AppSettingsState state;
  final AppLocalizations l10n;
  final VoidCallback onHeightTap;
  final VoidCallback onTargetWeightTap;

  const _ProfileSection({
    required this.state,
    required this.l10n,
    required this.onHeightTap,
    required this.onTargetWeightTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final heightValue = state.height > 0
        ? formatHeight(state.height, state.measurementUnit)
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

class _ApplicationSection extends StatelessWidget {
  final AppSettingsState state;
  final AppLocalizations l10n;
  final VoidCallback onThemeTap;
  final VoidCallback onUnitTap;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onNotificationTimeTap;

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

class _SecuritySection extends StatelessWidget {
  final AppSettingsState state;
  final AppLocalizations l10n;
  final Future<bool> isBiometricAvailable;
  final ValueChanged<bool> onBiometricChanged;
  final String biometricsAvailableLabel;
  final String biometricsNotAvailableLabel;

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

class _DataSection extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onImportTap;
  final VoidCallback onExportTap;
  final VoidCallback onWipeTap;

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
