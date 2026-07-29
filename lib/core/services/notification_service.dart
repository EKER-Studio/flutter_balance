import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service for managing local scheduled notifications.
///
/// Must be initialized via [initialize] during app startup before invoking scheduling APIs.
class NotificationService {
  NotificationService._();

  /// The single shared instance of [NotificationService].
  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 0;
  static const String _channelId = 'pure_weight_reminders';
  static const String _channelName = 'Daily Weight Reminders';
  static const String _channelDescription =
      'Reminds you to record your daily weight measurement.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initializes the local notification plugin and timezone database.
  ///
  /// Must be called after `WidgetsFlutterBinding.ensureInitialized()`.
  /// Safe to call multiple times; subsequent invocations no-op if already initialized.
  /// Catches and logs non-fatal setup exceptions.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        ),
      );

      // Request permission on Android 13+.
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService.initialize error: $e');
      }
    }
  }

  /// Schedules (or replaces) a repeating daily reminder at [time].
  ///
  /// Takes a mandatory [TimeOfDay] [time] specifying when the daily reminder should fire.
  /// Takes optional [title] and [body] strings for notification display.
  /// The notification fires every day at [time] in the device's local time zone.
  /// Any previously scheduled reminder is cancelled first.
  /// Catches and logs non-fatal notification scheduling errors.
  Future<void> scheduleDailyReminder(
    TimeOfDay time, {
    String title = 'Time to weigh yourself! ⚖️',
    String body = 'Log your weight today and stay on track with PureWeight.',
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _dailyReminderId);
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
      await _plugin.zonedSchedule(
        id: _dailyReminderId,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService.scheduleDailyReminder error: $e');
      }
    }
  }

  /// Cancels the active daily weight reminder notification, if any.
  ///
  /// Returns a [Future] that completes when cancellation is registered.
  /// Catches and logs non-fatal cancellation errors.
  Future<void> cancelDailyReminder() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _dailyReminderId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService.cancelDailyReminder error: $e');
      }
    }
  }

  /// Computes the next [tz.TZDateTime] that matches [time] in the local zone.
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
