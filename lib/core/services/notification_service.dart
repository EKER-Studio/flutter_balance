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

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  String _channelName = 'Daily Weight Reminders';
  String _channelDescription =
      'Reminds you to record your daily weight measurement.';
  String _title = 'Time to weigh yourself!';
  String _body = 'Log your weight today and stay on track with PureWeight.';

  /// Updates the localized texts used for scheduled reminder notifications.
  ///
  /// Must be invoked whenever the app locale changes so scheduled reminders
  /// display in the active language.
  void setLocalizedTexts({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) {
    _title = title;
    _body = body;
    _channelName = channelName;
    _channelDescription = channelDescription;
  }

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

  /// Requests notification permissions on iOS, macOS, and Android 13+.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> requestPermissions() async {
    if (!_initialized) {
      await initialize();
    }
    try {
      final androidGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      final iosGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      final macosGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      return (androidGranted ?? true) && (iosGranted ?? macosGranted ?? true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService.requestPermissions error: $e');
      }
      return false;
    }
  }

  /// Schedules (or replaces) a repeating daily reminder at [time].
  ///
  /// Takes a mandatory [TimeOfDay] [time] specifying when the daily reminder should fire.
  /// The notification fires every day at [time] in the device's local time zone
  /// using the localized texts configured via [setLocalizedTexts].
  /// Any previously scheduled reminder is cancelled first.
  /// Catches and logs non-fatal notification scheduling errors.
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
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
        title: _title,
        body: _body,
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
