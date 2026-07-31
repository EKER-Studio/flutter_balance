import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:pure_weight/core/services/biometric_service.dart';
import 'package:pure_weight/core/utils/csv_importer.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pure_weight/presentation/widgets/target_weight_dialog.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';
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

class SettingsScreen extends StatefulWidget {
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
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          return SingleChildScrollView(
            child: ClampedLayout(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(context, l10n),
                  const SizedBox(height: 24),
                  _SectionHeader(label: l10n.profileSection),
                  const SizedBox(height: 8),
                  _ProfileSection(
                    state: state,
                    l10n: l10n,
                    onHeightTap: () => _showHeightDialog(context),
                    onTargetWeightTap: () => _showTargetWeightDialog(context),
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
                    onNotificationTimeTap: () => _selectNotificationTime(
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
                    biometricsNotAvailableLabel: l10n.biometricsNotAvailable,
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(label: l10n.dataSection),
                  const SizedBox(height: 8),
                  _DataSection(
                    l10n: l10n,
                    onImportTap: () => _importCsv(context),
                    onWipeTap: () => _showWipeConfirmation(context),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.monitor_weight, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).settingsTitle,
            style: textTheme.titleLarge,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              AppLocalizations.of(context).appTitle.characters.first,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsTitle, style: textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text(
          l10n.settingsSubtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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
    } else {
      context.read<AppSettingsBloc>().add(const TargetWeightChanged(null));
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
      await HydratedBloc.storage.clear();

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
    context.read<AppSettingsBloc>().add(UpdateBiometricLock(enabled));
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
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isError;
  final bool showChevron;
  const _CustomSettingsTile({
    required this.icon,
    required this.title,
    this.valueText,
    this.trailing,
    this.onTap,
    this.isError = false,
    this.showChevron = true,
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

    final iconColor = widget.isError
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    final leading = ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        foregroundDecoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(widget.icon, color: iconColor, size: 20),
      ),
    );

    final titleWidget = Text(
      widget.title,
      style: textTheme.bodyLarge?.copyWith(
        color: widget.isError ? colorScheme.error : null,
      ),
    );

    Widget? trailingWidget;
    if (widget.trailing != null) {
      trailingWidget = widget.trailing;
    } else if (widget.valueText != null) {
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
        child: ListTile(
          shape: shape,
          onTap: widget.onTap,
          leading: leading,
          title: titleWidget,
          trailing: trailingWidget,
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

  const _CustomSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
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
        decoration: const BoxDecoration(shape: BoxShape.circle),
        foregroundDecoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(widget.icon, color: colorScheme.onSurfaceVariant, size: 20),
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
          title: Text(widget.title, style: textTheme.bodyLarge),
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
    final textTheme = Theme.of(context).textTheme;

    final heightValue = state.height > 0
        ? formatHeight(state.height, state.measurementUnit)
        : l10n.heightNotSetLabel;

    final targetWeightValue = state.targetWeight != null
        ? formatWeight(state.targetWeight!, state.measurementUnit)
        : l10n.notSet;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _CustomSettingsTile(
            icon: Icons.height,
            title: l10n.height,
            valueText: heightValue,
            onTap: onHeightTap,
          ),
          _CustomSettingsTile(
            icon: Icons.flag,
            title: l10n.targetWeight,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    targetWeightValue,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
    final themeLabel = state.themeMode.localizedName(l10n);

    final unitLabel = state.measurementUnit.localizedName(l10n);

    final notificationTimeText = state.notificationTime.format(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _CustomSettingsTile(
            icon: Icons.palette,
            title: l10n.theme,
            valueText: themeLabel,
            onTap: onThemeTap,
          ),
          _CustomSettingsTile(
            icon: Icons.straighten,
            title: l10n.measurementUnit,
            valueText: unitLabel,
            onTap: onUnitTap,
          ),
          _CustomSwitchTile(
            icon: Icons.notifications_outlined,
            title: l10n.dailyReminder,
            subtitle: l10n.dailyReminderDesc,
            value: state.notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),
          if (state.notificationsEnabled)
            _CustomSettingsTile(
              icon: Icons.access_time,
              title: l10n.reminderTime,
              valueText: notificationTimeText,
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
    return Card(
      margin: EdgeInsets.zero,
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
  final VoidCallback onWipeTap;

  const _DataSection({
    required this.l10n,
    required this.onImportTap,
    required this.onWipeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _CustomSettingsTile(
            icon: Icons.import_export,
            title: l10n.importCsv,
            onTap: onImportTap,
          ),
          _CustomSettingsTile(
            icon: Icons.delete_forever,
            title: l10n.wipeData,
            isError: true,
            showChevron: false,
            onTap: onWipeTap,
          ),
        ],
      ),
    );
  }
}
