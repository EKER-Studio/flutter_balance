import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/core/utils/csv_exporter.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';
import 'package:pure_weight/presentation/screens/settings_screen.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/features/weight/presentation/widgets/health_summary_card.dart';
import 'package:pure_weight/presentation/widgets/weight_chart.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WeightBloc, WeightState>(
      listenWhen: (previous, current) => current is WeightError,
      listener: (context, state) {
        if (state is WeightError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              action: SnackBarAction(
                label: 'Spróbuj ponownie',
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
            title: const Text('PureWeight'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              if (_hasEntries(state))
                IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: 'Export CSV',
                  onPressed: () =>
                      CsvExporter.exportAndShare(_getEntries(state)),
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
        :final message,
        :final entries,
        :final filteredEntries,
        :final timePeriod,
        :final heightCm,
      ) =>
        _buildError(
          context,
          message,
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

    final targetWeight = context.watch<AppSettingsBloc>().state.targetWeight;

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
                WeightChart(
                  entries: filteredEntries,
                  period: timePeriod,
                  chartHeight: chartHeight,
                  onPeriodChanged: (period) =>
                      context.read<WeightBloc>().add(ChangeChartFilter(period)),
                  targetWeight: targetWeight,
                ),
                const SizedBox(height: 16),
                _buildStatsSection(sorted, targetWeight),
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
    String message,
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
                    Expanded(child: Text(message)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (heightCm == null)
              _buildHeightConfig()
            else ...[
              WeightChart(
                entries: filteredEntries,
                period: timePeriod,
                onPeriodChanged: (period) =>
                    context.read<WeightBloc>().add(ChangeChartFilter(period)),
                targetWeight: context
                    .watch<AppSettingsBloc>()
                    .state
                    .targetWeight,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set Your Height',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
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
                  _heightController.clear();
                }
              },
              child: const Text('Save'),
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
              Icon(
                Icons.monitor_weight_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Brak wpisów. Dodaj swój pierwszy pomiar poniżej!',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...entries.map(_buildEntryTile),
      ],
    );
  }

  Widget _buildEntryTile(WeightEntry entry) {
    final dateStr =
        '${entry.dateTime.day}/${entry.dateTime.month}/${entry.dateTime.year} '
        '${entry.dateTime.hour.toString().padLeft(2, '0')}:'
        '${entry.dateTime.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        title: Text('${entry.weightKg.toStringAsFixed(1)} kg'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr),
            if (entry.bmi != null)
              Text('BMI: ${entry.bmi!.toStringAsFixed(1)}'),
            if (entry.note != null && entry.note!.isNotEmpty) Text(entry.note!),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            context.read<WeightBloc>().add(DeleteWeight(entry.id));
          },
        ),
      ),
    );
  }

  void _showAddWeightSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddWeightSheet(),
    );
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
            Text('Stats', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    label: 'Lowest',
                    value: minWeight != null
                        ? '${minWeight.toStringAsFixed(1)} kg'
                        : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatTile(
                    label: 'Highest',
                    value: maxWeight != null
                        ? '${maxWeight.toStringAsFixed(1)} kg'
                        : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatTile(
                    label: 'To Goal',
                    value: _formatToGoal(lastWeight, targetWeight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatToGoal(double? lastWeight, double? targetWeight) {
    if (lastWeight == null || targetWeight == null) return '—';
    final diff = lastWeight - targetWeight;
    if (diff.abs() < 0.05) return 'Reached!';
    final sign = diff > 0 ? '+' : '-';
    return '$sign${diff.abs().toStringAsFixed(1)} kg';
  }

  Widget _buildStatTile({required String label, required String value}) {
    return Column(
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
    );
  }
}

/// Card displaying the latest weight entry summary and BMI interpretation.
class WeightSummaryCard extends StatelessWidget {
  /// The latest [WeightEntry] to display.
  final WeightEntry entry;

  /// Creates [WeightSummaryCard] with the given [entry].
  const WeightSummaryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final bmi = entry.bmi;
    final interpretation = bmi != null ? _interpretBmi(bmi) : null;
    final bmiColor = bmi != null ? _bmiColor(bmi) : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.weightKg.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Latest measurement',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (bmi != null)
              Column(
                children: [
                  Text(
                    bmi.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: bmiColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    interpretation!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: bmiColor),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _interpretBmi(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    return Colors.red;
  }
}
