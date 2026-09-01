import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:balance/core/config/app_environment.dart';
import 'package:balance/core/presentation/navigation/app_routes.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Manages local notification scheduling for the daily weight reminder.
///
/// Must be initialized via [initialize] during app startup before invoking
/// any scheduling APIs.
class NotificationService {
  NotificationService._();

  /// The single shared instance of [NotificationService].
  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 0;

  /// Optional callback invoked when the user taps on a delivered local notification.
  void Function(String payload)? onNotificationTapped;

  /// The Android notification channel ID for daily weight reminders.
  String get _channelId => AppEnvironment.current.notificationChannelId;

  /// The Android notification channel ID for milestone achievements.
  static const String _achievementsChannelId = 'balance_achievements';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// The display name for the Android reminder notification channel.
  String _channelName = 'Daily Weight Reminders';

  /// The description for the Android reminder notification channel.
  String _channelDescription =
      'Reminds you to record your daily weight measurement.';

  /// The display name for the Android achievements notification channel.
  String _achievementsChannelName = 'Achievements & Milestones';

  /// The description for the Android achievements notification channel.
  String _achievementsChannelDescription =
      'Notifications when you unlock new health milestones and streaks.';

  String _title = 'Time to weigh in!';

  String _body = "Don't forget to log your weight today.";

  /// Updates the localized texts used for scheduled reminder notifications and achievements.
  ///
  /// Must be invoked whenever the app locale changes so notifications
  /// display in the active language.
  void setLocalizedTexts({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
    String? achievementsChannelName,
    String? achievementsChannelDescription,
  }) {
    _title = title;
    _body = body;
    _channelName = channelName;
    _channelDescription = channelDescription;
    if (achievementsChannelName != null) {
      _achievementsChannelName = achievementsChannelName;
    }
    if (achievementsChannelDescription != null) {
      _achievementsChannelDescription = achievementsChannelDescription;
    }

    if (_initialized) {
      _updateAndroidChannel();
    }
  }

  /// Updates the Android notification channels with the current localized texts.
  ///
  /// Creates or updates the notification channels on Android devices.
  /// Safe to call multiple times; the channels are recreated each invocation.
  Future<void> _updateAndroidChannel() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    final reminderChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );
    await androidPlugin.createNotificationChannel(reminderChannel);

    final achievementsChannel = AndroidNotificationChannel(
      _achievementsChannelId,
      _achievementsChannelName,
      description: _achievementsChannelDescription,
      importance: Importance.high,
    );
    await androidPlugin.createNotificationChannel(achievementsChannel);
  }

  /// Initializes the local notification plugin and timezone database.
  ///
  /// Must be called after `WidgetsFlutterBinding.ensureInitialized()`.
  /// Safe to call multiple times; subsequent invocations are no-ops if already initialized.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();

      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final reminderChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );
      await androidPlugin?.createNotificationChannel(reminderChannel);

      final achievementsChannel = AndroidNotificationChannel(
        _achievementsChannelId,
        _achievementsChannelName,
        description: _achievementsChannelDescription,
        importance: Importance.high,
      );
      await androidPlugin?.createNotificationChannel(achievementsChannel);

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
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onNotificationTapped?.call(payload);
          }
        },
      );

      // Request standard notification permission on Android 13+ (POST_NOTIFICATIONS).
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

  /// Schedules (or replaces) a repeating daily reminder at [time].
  ///
  /// Uses [AndroidScheduleMode.inexactAllowWhileIdle] to ensure delivery
  /// without requiring special exact alarm permissions on Android 12+.
  Future<bool> scheduleDailyReminder(({int hour, int minute}) time) async {
    if (!_initialized) return false;
    try {
      await _plugin.cancel(id: _dailyReminderId);

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
            color: AppTheme.primaryColor,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        // Inexact scheduling that still permits delivery while the device is
        // idle, so the daily reminder is not dropped by battery optimizations.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: _title,
        body: _body,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: AppRoutes.todayWithAddAction(),
      );

      AppAnalytics.logNotificationScheduled(
        hour: time.hour,
        minute: time.minute,
        isExact: false,
      );

      if (kDebugMode) {
        debugPrint(
          '[NotificationService] scheduled daily reminder for $scheduledDate '
          '(main isolate: ${Isolate.current.debugName == 'main'})',
        );
      }
      return true;
    } catch (e, stack) {
      debugPrint(
        '[NotificationService] scheduleDailyReminder failed: $e\n$stack',
      );
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

  /// Displays an instant system notification when the user unlocks an achievement.
  Future<void> showAchievementNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _achievementsChannelId,
            _achievementsChannelName,
            channelDescription: _achievementsChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            color: AppTheme.primaryColor,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload ?? AppRoutes.statistics,
      );
      AppAnalytics.logEvent(
        name: 'achievement_notification_shown',
        parameters: {'notification_id': id},
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[NotificationService] showAchievementNotification failed',
        fatal: false,
      );
    }
  }

  /// Displays a single summary notification when multiple achievements are unlocked at once.
  Future<void> showMultipleAchievementsNotification({
    required int count,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: 999,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _achievementsChannelId,
            _achievementsChannelName,
            channelDescription: _achievementsChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            color: AppTheme.primaryColor,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload ?? AppRoutes.statistics,
      );
      AppAnalytics.logEvent(
        name: 'multiple_achievements_notification_shown',
        parameters: {'unlocked_count': count},
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason:
            '[NotificationService] showMultipleAchievementsNotification failed',
        fatal: false,
      );
    }
  }
}
