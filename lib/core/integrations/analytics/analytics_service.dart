import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Contract for telemetry event and screen view dispatching.
abstract interface class AnalyticsService {
  /// Sets whether Firebase Analytics is available and operational.
  void setAvailable(bool available);

  /// Enables or disables analytics collection (e.g. for debug or privacy preference).
  Future<void> setAnalyticsCollectionEnabled(bool enabled);

  /// Sets the unique identifier for the current user.
  ///
  /// @param id The user identifier string, or `null` to clear.
  Future<void> setUserId(String? id);

  /// Sets a custom user property.
  ///
  /// @param value The value of the property, or `null` to clear.
  Future<void> setUserProperty({required String name, required String? value});

  /// Logs a custom screen view event.
  Future<void> logScreenView({required String screenName, String? screenClass});

  /// Logs a generic custom telemetry event with optional parameters.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });
}

/// Default implementation of [AnalyticsService] delegating to [FirebaseAnalytics].
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService._();

  /// Shared singleton instance of [FirebaseAnalyticsService].
  static final FirebaseAnalyticsService instance = FirebaseAnalyticsService._();

  bool _isFirebaseAvailable = false;
  FirebaseAnalytics? _analyticsInstance;

  /// Returns the underlying [FirebaseAnalytics] instance when available.
  FirebaseAnalytics? get rawInstance {
    if (!_isFirebaseAvailable) return null;
    return _analyticsInstance ??= FirebaseAnalytics.instance;
  }

  @override
  void setAvailable(bool available) {
    _isFirebaseAvailable = available;
    if (!available) {
      _analyticsInstance = null;
    }
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (!_isFirebaseAvailable) return;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {}
  }

  @override
  Future<void> setUserId(String? id) async {
    if (!_isFirebaseAvailable) return;
    try {
      await FirebaseAnalytics.instance.setUserId(id: id);
    } catch (_) {}
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_isFirebaseAvailable) return;
    try {
      await FirebaseAnalytics.instance.setUserProperty(
        name: name,
        value: value,
      );
    } catch (_) {}
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[AnalyticsService] ScreenView: $screenName (class: $screenClass)',
      );
    }
    if (!_isFirebaseAvailable) return;
    try {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (_) {}
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (kDebugMode) {
      debugPrint('[AnalyticsService] Event: $name | Params: $parameters');
    }
    if (!_isFirebaseAvailable) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (_) {}
  }
}
