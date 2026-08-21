// The Today tab: daily weight summary, trend chart, tips, and quick add-weight flow.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
import 'package:balance/core/presentation/widgets/app_top_bar.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/dashboard/presentation/widgets/sections/today_view_body.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:balance/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A screen displaying the daily summary, BMI, goal progress, and weight trend.
class TodayScreen extends StatelessWidget {
  /// An optional callback to navigate to settings when the profile icon is pressed.
  final VoidCallback? onNavigateToSettings;

  const TodayScreen({super.key, this.onNavigateToSettings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      body: BlocConsumer<WeightBloc, WeightState>(
        listenWhen: (previous, current) => current is WeightError,
        listener: (context, state) {
          if (state is WeightError && state.entries.isNotEmpty) {
            _showErrorSnackBar(context, state.errorType, l10n);
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => _refreshWeightData(context),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                AppTopBar(title: l10n.todayTabTitle),
                SliverSafeArea(
                  top: false,
                  sliver: SliverToBoxAdapter(
                    child: ClampedLayout(
                      maxWidth: isLandscape ? 1200 : 600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: TodayViewBody(
                        state: state,
                        onAddFirstMeasurement: () {
                          AppAnalytics.logTodayFirstWeightButtonClicked();
                          _showAddWeightSheet(context, source: 'empty_state');
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : BlocBuilder<WeightBloc, WeightState>(
              builder: (context, state) {
                final entries = _entriesFromState(state);
                if (entries.isEmpty ||
                    state is WeightInitial ||
                    state is WeightLoading) {
                  return const SizedBox.shrink();
                }
                return FloatingActionButton(
                  onPressed: () {
                    AppAnalytics.logTodayAddWeightFabClicked();
                    _showAddWeightSheet(context, source: 'fab');
                  },
                  child: const Icon(Icons.add),
                );
              },
            ),
    );
  }

  static List<WeightEntry> _entriesFromState(WeightState state) =>
      state.entries;

  Future<void> _refreshWeightData(BuildContext context) async {
    AppAnalytics.logTodayPullToRefresh();
    final bloc = context.read<WeightBloc>();
    bloc.add(const RefreshWeightData());
    await bloc.stream
        .firstWhere((state) => state is WeightLoaded || state is WeightError)
        .timeout(const Duration(seconds: 2), onTimeout: () => bloc.state);
  }

  void _showErrorSnackBar(
    BuildContext context,
    WeightErrorType errorType,
    AppLocalizations l10n,
  ) {
    final message = errorType.localizedMessage(l10n);
    AppSnackBar.show(
      context,
      message: message,
      type: SnackBarType.error,
      action: SnackBarAction(
        label: l10n.retry,
        onPressed: () {
          AppAnalytics.logTodayErrorRetryClicked();
          context.read<WeightBloc>().add(const SubscribeToWeightChanges());
        },
      ),
    );
  }

  void _showAddWeightSheet(BuildContext context, {String source = 'fab'}) {
    AppAnalytics.logDialogAddWeightOpened(source);
    final weightBloc = context.read<WeightBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) =>
          BlocProvider.value(value: weightBloc, child: const AddWeightSheet()),
    );
  }
}
