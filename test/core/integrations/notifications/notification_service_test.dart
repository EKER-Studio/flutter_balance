import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show FlutterLocalNotificationsPlatform;
import 'package:flutter_local_notifications/src/platform_flutter_local_notifications.dart'
    show
        AndroidFlutterLocalNotificationsPlugin,
        IOSFlutterLocalNotificationsPlugin,
        MacOSFlutterLocalNotificationsPlugin;

/// A mock handler for the flutter_local_notifications method channel that
/// records which methods were invoked and returns configurable values.
class FakeNotificationsChannel {
  final List<String> invokedMethods = [];

  bool canScheduleExact = true;
  bool? requestExactResult = true;
  bool requestNotificationsResult = true;

  /// The reported Android SDK level (API 31+ exercises the permission flow).
  int androidSdkInt = 33;

  /// The local ISO-8601 date string of the last `zonedSchedule` call.
  String? latestScheduledDateTime;

  Future<Object?> handle(MethodCall call) async {
    invokedMethods.add(call.method);
    if (call.method == 'zonedSchedule') {
      latestScheduledDateTime = call.arguments['scheduledDateTime'] as String?;
    }
    if (call.method == 'requestExactAlarmsPermission' &&
        requestExactResult == true) {
      canScheduleExact = true;
    }
    return switch (call.method) {
      'initialize' => true,
      'createNotificationChannel' => null,
      'cancel' => null,
      'zonedSchedule' => null,
      'requestNotificationsPermission' => requestNotificationsResult,
      'requestPermissions' => true,
      'canScheduleExactNotifications' => canScheduleExact,
      'requestExactAlarmsPermission' => requestExactResult,
      _ => null,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const timezoneChannel = MethodChannel('flutter_timezone');
  const deviceInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/device_info',
  );

  void installMocks(FakeNotificationsChannel fake) {
    messenger.setMockMethodCallHandler(notificationsChannel, fake.handle);
    messenger.setMockMethodCallHandler(
      timezoneChannel,
      (call) async => 'Europe/Warsaw',
    );
    messenger.setMockMethodCallHandler(
      deviceInfoChannel,
      (call) async => {
        'version': {
          'sdkInt': fake.androidSdkInt,
          'release': '14',
          'codename': 'REL',
          'incremental': 'test',
        },
        'board': 'board',
        'bootloader': 'bootloader',
        'brand': 'brand',
        'device': 'device',
        'display': 'display',
        'fingerprint': 'fingerprint',
        'hardware': 'hardware',
        'host': 'host',
        'id': 'id',
        'manufacturer': 'manufacturer',
        'model': 'model',
        'product': 'product',
        'name': 'name',
        'supported32BitAbis': <String>[],
        'supported64BitAbis': <String>[],
        'supportedAbis': <String>[],
        'tags': 'tags',
        'type': 'type',
        'isPhysicalDevice': true,
        'freeDiskSize': 0,
        'totalDiskSize': 0,
        'systemFeatures': <String>[],
        'isLowRamDevice': false,
        'physicalRamSize': 0,
        'availableRamSize': 0,
      },
    );
  }

  void removeMocks() {
    messenger.setMockMethodCallHandler(notificationsChannel, null);
    messenger.setMockMethodCallHandler(timezoneChannel, null);
    messenger.setMockMethodCallHandler(deviceInfoChannel, null);
  }

  tearDown(removeMocks);

  group('NotificationService', () {
    test('singleton instance is not null', () {
      expect(NotificationService.instance, isNotNull);
    });

    test('setLocalizedTexts updates texts without crashing', () {
      expect(
        () => NotificationService.instance.setLocalizedTexts(
          title: 'Title',
          body: 'Body',
          channelName: 'Channel',
          channelDescription: 'Desc',
        ),
        returnsNormally,
      );
    });

    test(
      'initialize catches exceptions when method channels are not mocked',
      () async {
        await expectLater(NotificationService.instance.initialize(), completes);
      },
    );

    test('requestPermissions catches exceptions when not mocked', () async {
      final result = await NotificationService.instance.requestPermissions();
      expect(result, isFalse);
    });

    test('scheduleDailyReminder returns false before initialization', () async {
      final result = await NotificationService.instance.scheduleDailyReminder(
        const (hour: 8, minute: 0),
      );
      expect(result, isFalse);
    });

    test(
      'canScheduleExactNotifications returns true when plugin is unavailable',
      () async {
        final result = await NotificationService.instance
            .canScheduleExactNotifications();
        expect(result, isTrue);
      },
    );

    test(
      'requestExactAlarmsPermission returns false when plugin is unavailable',
      () async {
        final result = await NotificationService.instance
            .requestExactAlarmsPermission();
        expect(result, isFalse);
      },
    );

    test('cancelDailyReminder does not crash', () async {
      await expectLater(
        NotificationService.instance.cancelDailyReminder(),
        completes,
      );
    });
  });

  group('NotificationService with mocked platform channels', () {
    late FakeNotificationsChannel fake;
    late FlutterLocalNotificationsPlatform? originalPlatform;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      fake = FakeNotificationsChannel();
      installMocks(fake);
      // The plugin platform instance is only registered by the native
      // registrant, which never runs in the test VM. Register the method
      // channel implementation so the plugin delegates to our mocked channel.
      try {
        originalPlatform = FlutterLocalNotificationsPlatform.instance;
      } catch (_) {
        originalPlatform = null;
      }
      FlutterLocalNotificationsPlatform.instance =
          AndroidFlutterLocalNotificationsPlugin();
    });

    tearDown(() {
      if (originalPlatform != null) {
        FlutterLocalNotificationsPlatform.instance = originalPlatform!;
      }
      debugDefaultTargetPlatformOverride = null;
    });

    test('requestPermissions initializes the service first when not yet '
        'initialized', () async {
      fake.requestNotificationsResult = true;

      final granted = await NotificationService.instance.requestPermissions();

      expect(granted, isTrue);
      expect(fake.invokedMethods, contains('initialize'));
      expect(fake.invokedMethods, contains('requestNotificationsPermission'));
    });

    test('initialize completes successfully and becomes idempotent', () async {
      await NotificationService.instance.initialize();
      final channelCallsAfterFirst = fake.invokedMethods
          .where((m) => m == 'createNotificationChannel')
          .length;

      await NotificationService.instance.initialize();
      final channelCallsAfterSecond = fake.invokedMethods
          .where((m) => m == 'createNotificationChannel')
          .length;

      expect(
        channelCallsAfterSecond,
        channelCallsAfterFirst,
        reason: 'A second initialize must not recreate the channel',
      );
    });

    test('setLocalizedTexts updates the Android channel after init', () async {
      await NotificationService.instance.initialize();
      final channelCallsBefore = fake.invokedMethods
          .where((m) => m == 'createNotificationChannel')
          .length;

      NotificationService.instance.setLocalizedTexts(
        title: 'Nowy tytuł',
        body: 'Nowa treść',
        channelName: 'Przypomnienie',
        channelDescription: 'Opis',
      );

      expect(
        fake.invokedMethods.where((m) => m == 'createNotificationChannel'),
        hasLength(channelCallsBefore + 1),
      );
    });

    test(
      'requestPermissions returns true when permission is granted',
      () async {
        await NotificationService.instance.initialize();
        fake.requestNotificationsResult = true;

        final granted = await NotificationService.instance.requestPermissions();

        expect(granted, isTrue);
        expect(fake.invokedMethods, contains('requestNotificationsPermission'));
      },
    );

    test(
      'requestPermissions returns false when permission is denied',
      () async {
        await NotificationService.instance.initialize();
        fake.requestNotificationsResult = false;

        final granted = await NotificationService.instance.requestPermissions();

        expect(granted, isFalse);
      },
    );

    test('canScheduleExactNotifications reflects the platform value', () async {
      fake.canScheduleExact = true;
      expect(
        await NotificationService.instance.canScheduleExactNotifications(),
        isTrue,
      );

      fake.canScheduleExact = false;
      expect(
        await NotificationService.instance.canScheduleExactNotifications(),
        isFalse,
      );
    });

    test(
      'canScheduleExactNotifications is always true on Android < 12',
      () async {
        fake.androidSdkInt = 30;

        expect(
          await NotificationService.instance.canScheduleExactNotifications(),
          isTrue,
          reason: 'SCHEDULE_EXACT_ALARM does not exist before API 31',
        );
        expect(
          fake.invokedMethods.where(
            (m) => m == 'canScheduleExactNotifications',
          ),
          isEmpty,
          reason: 'The plugin channel must not be consulted on Android < 12',
        );
      },
    );

    test('requestExactAlarmsPermission reflects the platform value', () async {
      fake.requestExactResult = true;
      expect(
        await NotificationService.instance.requestExactAlarmsPermission(),
        isTrue,
      );

      fake.requestExactResult = false;
      expect(
        await NotificationService.instance.requestExactAlarmsPermission(),
        isFalse,
      );
    });

    test(
      'scheduleDailyReminder schedules with exact timing by default',
      () async {
        await NotificationService.instance.initialize();
        fake.canScheduleExact = true;

        final scheduled = await NotificationService.instance
            .scheduleDailyReminder(const (hour: 8, minute: 0));

        expect(scheduled, isTrue);
        expect(fake.invokedMethods, contains('cancel'));
        expect(fake.invokedMethods, contains('zonedSchedule'));
      },
    );

    test('scheduleDailyReminder falls back to inexact scheduling when exact '
        'alarms are revoked', () async {
      await NotificationService.instance.initialize();
      fake.canScheduleExact = false;
      fake.requestExactResult = false;

      final scheduled = await NotificationService.instance
          .scheduleDailyReminder(const (hour: 8, minute: 0));

      expect(scheduled, isFalse);
      expect(fake.invokedMethods, contains('requestExactAlarmsPermission'));
      final zonedScheduleCall = fake.invokedMethods.indexOf('zonedSchedule');
      expect(
        fake.invokedMethods.indexOf('cancel'),
        lessThan(zonedScheduleCall),
      );
    });

    test(
      'scheduleDailyReminder stays exact when permission is re-granted',
      () async {
        await NotificationService.instance.initialize();
        fake.canScheduleExact = false;
        fake.requestExactResult = true;

        final scheduled = await NotificationService.instance
            .scheduleDailyReminder(const (hour: 8, minute: 0));

        expect(scheduled, isTrue);
        expect(
          fake.invokedMethods.where(
            (m) => m == 'canScheduleExactNotifications',
          ),
          hasLength(2),
        );
      },
    );

    test(
      'scheduleDailyReminder schedules for a moment in the future',
      () async {
        await NotificationService.instance.initialize();
        fake.canScheduleExact = true;

        await NotificationService.instance.scheduleDailyReminder(const (
          hour: 23,
          minute: 59,
        ));

        final scheduledAt = DateTime.parse(fake.latestScheduledDateTime!);
        expect(
          scheduledAt.isAfter(DateTime.now()),
          isTrue,
          reason: 'A reminder must never be scheduled in the past',
        );
      },
    );

    test('cancelDailyReminder invokes the platform cancel', () async {
      await NotificationService.instance.initialize();

      await NotificationService.instance.cancelDailyReminder();

      expect(fake.invokedMethods, contains('cancel'));
    });
  });

  group('NotificationService failing platform channels', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      messenger.setMockMethodCallHandler(
        notificationsChannel,
        (call) async => throw PlatformException(code: 'TEST_FAILURE'),
      );
      messenger.setMockMethodCallHandler(
        timezoneChannel,
        (call) async => throw PlatformException(code: 'TEST_FAILURE'),
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('initialize swallows platform-channel errors', () async {
      await expectLater(NotificationService.instance.initialize(), completes);
    });

    test('canScheduleExactNotifications falls back to true on error', () async {
      expect(
        await NotificationService.instance.canScheduleExactNotifications(),
        isTrue,
      );
    });

    test('requestPermissions returns false on error', () async {
      expect(await NotificationService.instance.requestPermissions(), isFalse);
    });

    test('scheduleDailyReminder returns false on error', () async {
      expect(
        await NotificationService.instance.scheduleDailyReminder(const (
          hour: 8,
          minute: 0,
        )),
        isFalse,
      );
    });

    test('requestExactAlarmsPermission returns false on error', () async {
      expect(
        await NotificationService.instance.requestExactAlarmsPermission(),
        isFalse,
      );
    });

    test('cancelDailyReminder swallows platform errors', () async {
      await expectLater(
        NotificationService.instance.cancelDailyReminder(),
        completes,
      );
    });
  });

  group('NotificationService per-platform permission requests', () {
    late FakeNotificationsChannel fake;
    late FlutterLocalNotificationsPlatform? originalPlatform;

    setUp(() {
      fake = FakeNotificationsChannel();
      installMocks(fake);
      try {
        originalPlatform = FlutterLocalNotificationsPlatform.instance;
      } catch (_) {
        originalPlatform = null;
      }
    });

    tearDown(() {
      if (originalPlatform != null) {
        FlutterLocalNotificationsPlatform.instance = originalPlatform!;
      }
      debugDefaultTargetPlatformOverride = null;
    });

    test('requestPermissions requests iOS permissions on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      FlutterLocalNotificationsPlatform.instance =
          IOSFlutterLocalNotificationsPlugin();

      final granted = await NotificationService.instance.requestPermissions();

      expect(granted, isTrue);
      expect(fake.invokedMethods, contains('requestPermissions'));
    });

    test('requestPermissions requests macOS permissions on macOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      FlutterLocalNotificationsPlatform.instance =
          MacOSFlutterLocalNotificationsPlugin();

      final granted = await NotificationService.instance.requestPermissions();

      expect(granted, isTrue);
      expect(fake.invokedMethods, contains('requestPermissions'));
    });
  });
}
