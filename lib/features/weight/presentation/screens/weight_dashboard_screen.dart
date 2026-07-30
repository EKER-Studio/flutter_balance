import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/core/utils/csv_exporter.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';
import 'package:pure_weight/presentation/screens/settings_screen.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/features/weight/presentation/widgets/health_summary_card.dart';
import 'package:pure_weight/presentation/widgets/weight_chart.dart';
import 'package:intl/intl.dart';

/// Main dashboard screen showing weight summary, history, and height config.
class WeightDashboardScreen extends StatefulWidget {
  /// Creates [WeightDashboardScreen].
  const WeightDashboardScreen({super.key});

  @override
  State<WeightDashboardScreen> createState() => _WeightDashboardScreenState();
}

class _WeightDashboardScreenState extends State<WeightDashboardScreen> {
  final _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  String _getErrorMessage(BuildContext context, WeightErrorType errorType) {
    final l10n = AppLocalizations.of(context);
    return switch (errorType) {
      WeightErrorType.streamError => l10n.errorStream,
      WeightErrorType.heightNotSet => l10n.errorHeightNotSet,
      WeightErrorType.addEntryFailed => l10n.errorAddEntryFailed,
      WeightErrorType.deleteEntryFailed => l10n.errorDeleteEntryFailed,
      WeightErrorType.readFailed => l10n.errorReadFailed,
      WeightErrorType.writeFailed => l10n.errorWriteFailed,
      WeightErrorType.wipeFailed => l10n.errorWipeFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WeightBloc, WeightState>(
      listenWhen: (previous, current) => current is WeightError,
      listener: (context, state) {
        if (state is WeightError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(context, state.errorType)),
              action: SnackBarAction(
                label: AppLocalizations.of(context).retry,
                onPressed: () {
                  context.read<WeightBloc>().add(
                    const SubscribeToWeightChanges(),
                  );
                },
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).appTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: AppLocalizations.of(context).settingsTitle,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              if (_hasEntries(state))
                IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: AppLocalizations.of(context).exportCsv,
                  onPressed: () => CsvExporter.exportAndShare(
                    _getEntries(state),
                    context.read<AppSettingsBloc>().state.height,
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: ClampedLayout(
              padding: const EdgeInsets.all(16),
              child: _buildBody(context, state),
            ),
          ),
          floatingActionButton: _showFab(state)
              ? FloatingActionButton(
                  onPressed: () => _showAddWeightSheet(context),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  bool _showFab(WeightState state) =>
      state is WeightLoaded || state is WeightError;

  bool _hasEntries(WeightState state) {
    if (state is WeightLoaded) return state.entries.isNotEmpty;
    if (state is WeightError) return state.entries.isNotEmpty;
    return false;
  }

  List<WeightEntry> _getEntries(WeightState state) {
    if (state is WeightLoaded) return state.entries;
    if (state is WeightError) return state.entries;
    return const [];
  }

  Widget _buildBody(BuildContext context, WeightState state) {
    return switch (state) {
      WeightInitial() => const Center(child: CircularProgressIndicator()),
      WeightLoading() => const Center(child: CircularProgressIndicator()),
      WeightLoaded(
        :final entries,
        :final filteredEntries,
        :final timePeriod,
        :final heightCm,
      ) =>
        _buildContent(context, entries, filteredEntries, timePeriod, heightCm),
      WeightError(
        :final errorType,
        :final entries,
        :final filteredEntries,
        :final timePeriod,
        :final heightCm,
      ) =>
        _buildError(
          context,
          errorType,
          entries,
          filteredEntries,
          timePeriod,
          heightCm,
        ),
    };
  }

  Widget _buildContent(
    BuildContext context,
    List<WeightEntry> entries,
    List<WeightEntry> filteredEntries,
    TimePeriod timePeriod,
    double? heightCm,
  ) {
    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return OrientationBuilder(
      builder: (context, orientation) {
        final chartHeight = orientation == Orientation.landscape
            ? 160.0
            : 280.0;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (heightCm == null) _buildHeightConfig(),
              if (sorted.isNotEmpty) ...[
                HealthSummaryCard(latestWeightKg: sorted.first.weightKg),
                const SizedBox(height: 16),
                BlocSelector<AppSettingsBloc, AppSettingsState, double?>(
                  selector: (state) => state.targetWeight,
                  builder: (context, targetWeight) => Column(
                    children: [
                      WeightChart(
                        entries: filteredEntries,
                        period: timePeriod,
                        chartHeight: chartHeight,
                        onPeriodChanged: (period) => context
                            .read<WeightBloc>()
                            .add(ChangeChartFilter(period)),
                        targetWeight: targetWeight,
                      ),
                      const SizedBox(height: 16),
                      _buildStatsSection(sorted, targetWeight),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildHistorySection(sorted, heightCm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError(
    BuildContext context,
    WeightErrorType errorType,
    List<WeightEntry> entries,
    List<WeightEntry> filteredEntries,
    TimePeriod timePeriod,
    double? heightCm,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<WeightBloc>().add(const SubscribeToWeightChanges());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_getErrorMessage(context, errorType))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (heightCm == null)
              _buildHeightConfig()
            else ...[
              BlocSelector<AppSettingsBloc, AppSettingsState, double?>(
                selector: (state) => state.targetWeight,
                builder: (context, targetWeight) => WeightChart(
                  entries: filteredEntries,
                  period: timePeriod,
                  onPeriodChanged: (period) =>
                      context.read<WeightBloc>().add(ChangeChartFilter(period)),
                  targetWeight: targetWeight,
                ),
              ),
              const SizedBox(height: 16),
              _buildHistorySection(entries, heightCm),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeightConfig() {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.setYourHeightTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: l10n.heightCmLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final text = _heightController.text.trim();
                final height = double.tryParse(text);
                if (height != null && height > 0) {
                  context.read<WeightBloc>().add(UpdateUserHeight(height));
                  context.read<AppSettingsBloc>().add(UpdateHeight(height));
                  _heightController.clear();
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(List<WeightEntry> entries, double? heightCm) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.monitor_weight_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).emptyState,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, settingsState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).history,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...entries.map((entry) => _buildEntryTile(entry, settingsState)),
          ],
        );
      },
    );
  }

  Widget _buildEntryTile(WeightEntry entry, AppSettingsState settingsState) {
    final dateStr = DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).add_jm().format(entry.dateTime);
    final dynamicBmi = settingsState.calculateBmi(entry.weightKg);

    return Card(
      child: MergeSemantics(
        child: ListTile(
          title: Text('${entry.weightKg.toStringAsFixed(1)} kg'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr),
              Text(
                AppLocalizations.of(
                  context,
                ).bmiValue(dynamicBmi.toStringAsFixed(1)),
              ),
              if (entry.note != null && entry.note!.isNotEmpty)
                Text(entry.note!),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: AppLocalizations.of(context).deleteEntryTooltip,
            onPressed: () {
              context.read<WeightBloc>().add(DeleteWeight(entry.id));
            },
          ),
        ),
      ),
    );
  }

  void _showAddWeightSheet(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddWeightSheet());
  }

  Widget _buildStatsSection(List<WeightEntry> entries, double? targetWeight) {
    final weights = entries.map((e) => e.weightKg).toList();
    final minWeight = weights.isEmpty
        ? null
        : weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.isEmpty
        ? null
        : weights.reduce((a, b) => a > b ? a : b);
    final lastWeight = entries.isEmpty ? null : entries.first.weightKg;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).stats,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    label: AppLocalizations.of(context).lowest,
                    value: minWeight != null
                        ? '${minWeight.toStringAsFixed(1)} kg'
                        : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatTile(
                    label: AppLocalizations.of(context).highest,
                    value: maxWeight != null
                        ? '${maxWeight.toStringAsFixed(1)} kg'
                        : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatTile(
                    label: AppLocalizations.of(context).toGoal,
                    value: _formatToGoal(
                      lastWeight,
                      targetWeight,
                      AppLocalizations.of(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatToGoal(
    double? lastWeight,
    double? targetWeight,
    AppLocalizations l10n,
  ) {
    if (lastWeight == null || targetWeight == null) return '—';
    final diff = lastWeight - targetWeight;
    if (diff.abs() < 0.05) return l10n.reached;
    final sign = diff > 0 ? '+' : '-';
    return '$sign${diff.abs().toStringAsFixed(1)} kg';
  }

  Widget _buildStatTile({required String label, required String value}) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
