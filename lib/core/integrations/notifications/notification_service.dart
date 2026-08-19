import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Manages local notification scheduling for the daily weight reminder.
///
/// Must be initialized via [initialize] during app startup before invoking
/// any scheduling APIs.
class NotificationService {
  /// A private constructor to enforce the singleton pattern.
  NotificationService._();

  /// The single shared instance of [NotificationService].
  static final NotificationService instance = NotificationService._();

  /// The unique identifier for the daily weight reminder notification.
  static const int _dailyReminderId = 0;

  /// The Android notification channel ID for daily weight reminders.
  static const String _channelId = 'daily_weight_reminders_v2';

  /// The underlying plugin instance for local notifications.
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Whether the notification service has been initialized.
  bool _initialized = false;

  /// The display name for the Android notification channel.
  String _channelName = 'Daily Weight Reminders';

  /// The description for the Android notification channel.
  String _channelDescription =
      'Reminds you to record your daily weight measurement.';

  /// The title text for the daily weight reminder notification.
  String _title = 'Time to weigh in!';

  /// The body text for the daily weight reminder notification.
  String _body = "Don't forget to log your weight today.";

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

    if (_initialized) {
      _updateAndroidChannel();
    }
  }

  /// Updates the Android notification channel with the current localized texts.
  ///
  /// Creates or updates the notification channel on Android devices
  /// using [_channelId], [_channelName], and [_channelDescription].
  /// Safe to call multiple times; the channel is recreated each invocation.
  Future<void> _updateAndroidChannel() async {
    final androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  /// Initializes the local notification plugin and timezone database.
  ///
  /// Must be called after `WidgetsFlutterBinding.ensureInitialized()`.
  /// Safe to call multiple times; subsequent invocations are no-ops if already initialized.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();

      // Fetch the device's actual local timezone string (e.g. "Europe/Warsaw")
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // Create the Android notification channel explicitly.
      final androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(androidChannel);

      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_notification',
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
      await androidPlugin?.requestNotificationsPermission();

      _initialized = true;
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[NotificationService] initialize failed',
        fatal: false,
      );
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

      final granted =
          (androidGranted ?? true) && (iosGranted ?? macosGranted ?? true);
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] requestPermissions -> '
          'android=$androidGranted ios=$iosGranted macOS=$macosGranted '
          'granted=$granted',
        );
      }
      return granted;
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[NotificationService] requestPermissions failed',
        fatal: false,
      );
      return false;
    }
  }

  /// Returns whether exact alarm scheduling is currently permitted.
  ///
  /// Reflects the `SCHEDULE_EXACT_ALARM` permission on Android 12+, which the
  /// user can revoke at any time in system settings; always `true` on other
  /// platforms or when the platform check itself fails.
  Future<bool> canScheduleExactNotifications() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.canScheduleExactNotifications() ?? true;
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[NotificationService] canScheduleExactNotifications failed',
        fatal: false,
      );
      return true;
    }
  }

  /// Requests the exact alarm permission and returns whether it is granted.
  ///
  /// On Android 14+ a revoked `SCHEDULE_EXACT_ALARM` permission triggers the
  /// system permission prompt; on older versions the permission is granted by
  /// default and this is a no-op returning `true`.
  Future<bool> requestExactAlarmsPermission() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.requestExactAlarmsPermission() ?? true;
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[NotificationService] requestExactAlarmsPermission failed',
        fatal: false,
      );
      return false;
    }
  }

  /// Schedules (or replaces) a repeating daily reminder at [time].
  ///
  /// The notification fires every day at [time] in the device's local time zone
  /// using the localized texts configured via [setLocalizedTexts]. Any
  /// previously scheduled reminder is cancelled first.
  /// Returns `true` when scheduled with exact timing, `false` when exact
  /// alarm permission is missing (Android 12+ revocation) or scheduling failed.
  Future<bool> scheduleDailyReminder(({int hour, int minute}) time) async {
    if (!_initialized) return false;
    try {
      await _plugin.cancel(id: _dailyReminderId);

      var scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      var exactScheduling = await canScheduleExactNotifications();
      if (!exactScheduling) {
        // The SCHEDULE_EXACT_ALARM permission was revoked on Android 12+:
        // prompt the user to re-grant it once, then fall back to inexact
        // scheduling so the reminder still fires (possibly a few minutes late)
        // instead of being lost entirely.
        await requestExactAlarmsPermission();
        exactScheduling = await canScheduleExactNotifications();
        if (!exactScheduling) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: _dailyReminderId,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: scheduleMode,
        title: _title,
        body: _body,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      AppAnalytics.logNotificationScheduled(
        hour: time.hour,
        minute: time.minute,
        isExact: exactScheduling,
      );
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] scheduled daily reminder for $scheduledDate '
          '(main isolate: ${Isolate.current.debugName == 'main'})',
        );
      }
      return exactScheduling;
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[NotificationService] scheduleDailyReminder failed',
        fatal: false,
      );
      return false;
    }
  }

  /// Cancels the active daily weight reminder notification, if any.
  Future<void> cancelDailyReminder() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _dailyReminderId);
      AppAnalytics.logNotificationCancelled();
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[NotificationService] cancelDailyReminder failed',
        fatal: false,
      );
    }
  }
}
