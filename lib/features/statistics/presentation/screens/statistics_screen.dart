import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:balance/core/presentation/widgets/app_top_bar.dart';
import 'package:balance/core/presentation/widgets/state_message_card.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/statistics_content_section.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/statistics_shimmer_skeleton.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/widgets/components/add_weight_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A consolidated statistics screen combining all health metrics into data-dense composite cards.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          AppAnalytics.logStatisticsPullToRefresh();
          context.read<WeightBloc>().add(const SubscribeToWeightChanges());
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppTopBar(title: l10n.tabStats),
            SliverSafeArea(
              top: false,
              sliver: SliverToBoxAdapter(
                child: BlocBuilder<WeightBloc, WeightState>(
                  builder: (context, weightState) {
                    if (weightState is WeightInitial ||
                        weightState is WeightLoading) {
                      return ClampedLayout(
                        maxWidth: context.standardContentMaxWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: const StatisticsShimmerSkeleton(),
                      );
                    }

                    final entries = _entriesFromState(weightState);
                    final filteredEntries = _filteredEntriesFromState(
                      weightState,
                    );

                    if (entries.isEmpty) {
                      return ClampedLayout(
                        maxWidth: context.standardContentMaxWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 32,
                        ),
                        child: StateMessageCard(
                          icon: Icons.bar_chart,
                          iconColor: Theme.of(context).colorScheme.primary,
                          iconContainerColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          title: l10n.noDataToAnalyze,
                          subtitle: l10n.noDataToAnalyzeSubtitle,
                          buttonLabel: l10n.addFirstMeasurement,
                          buttonIcon: Icons.add,
                          onButtonPressed: () => _showAddWeightSheet(context),
                        ),
                      );
                    }

                    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
                      builder: (context, settingsState) {
                        return ClampedLayout(
                          maxWidth: context.standardContentMaxWidth,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: StatisticsContentSection(
                            entries: entries,
                            filteredEntries: filteredEntries,
                            timePeriod: weightState.timePeriod,
                            heightCm: settingsState.height,
                            targetWeight: settingsState.targetWeight,
                            unit: settingsState.measurementUnit,
                            onPeriodChanged: (period) {
                              AppAnalytics.logStatisticsFilterChanged(
                                period.name,
                              );
                              context.read<WeightBloc>().add(
                                ChangeChartFilter(period),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<WeightEntry> _entriesFromState(WeightState state) =>
      state.entries;

  static List<WeightEntry> _filteredEntriesFromState(WeightState state) =>
      state.filteredEntries;

  void _showAddWeightSheet(BuildContext context) {
    AppAnalytics.logStatisticsAddFirstMeasurementClicked();
    AppAnalytics.logDialogAddWeightOpened('statistics_empty_state');
    final weightBloc = context.read<WeightBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) =>
          BlocProvider.value(value: weightBloc, child: const AddWeightSheet()),
    );
  }
}
