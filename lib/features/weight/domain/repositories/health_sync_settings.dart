/// Provides the health-sync preferences needed by weight synchronization.
abstract interface class HealthSyncSettings {
  /// Whether synchronization with the platform health service is enabled.
  bool get isHealthSyncEnabled;

  /// The time of the last successful synchronization, if any.
  DateTime? get lastHealthSyncTimestamp;

  /// Persists the timestamp of a successful synchronization.
  ///
  /// [timestamp] is the UTC time reported by the synchronization operation.
  void updateLastHealthSyncTimestamp(DateTime timestamp);
}
