part of 'weight_bloc.dart';

/// Handles the health-platform synchronization event for [WeightBloc].
///
/// Dormant unless health sync is enabled in app settings; when enabled it pulls
/// remote history via the [HealthSyncCoordinator] and records analytics +
/// crash-reporting around the attempt.
class _HealthSyncDelegate {
  final _WeightBlocContext ctx;

  _HealthSyncDelegate(this.ctx);

  /// Pulls weight history from the health platform and merges records that do
  /// not already exist locally, emitting a refreshed [WeightLoaded] state.
  Future<void> onSync(
    SyncHealthEntries event,
    Emitter<WeightState> emit,
  ) async {
    final syncSettings = ctx.healthSyncSettings;
    if (!ctx.isHealthSyncEnabled || syncSettings == null) return;
    AppAnalytics.logHealthSyncStarted();
    try {
      final result = await ctx.healthSyncCoordinator.sync(
        startDate: event.startDate,
        lastSyncTime: syncSettings.lastHealthSyncTimestamp,
      );
      if (result != null) {
        AppAnalytics.logHealthSyncSuccess(
          remoteCount: result.remoteCount,
          pushedLocalCount: result.pushedLocalCount,
        );
        syncSettings.updateLastHealthSyncTimestamp(result.syncTimestamp);
      }
    } catch (e, stack) {
      AppAnalytics.logHealthSyncFailed(e.runtimeType.toString());
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Health synchronization failed',
        fatal: false,
      );
    }
  }
}
