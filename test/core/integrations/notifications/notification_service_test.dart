import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show FlutterLocalNotificationsPlatform;
import 'package:flutter_local_notifications/src/platform_flutter_local_notifications.dart'
    show AndroidFlutterLocalNotificationsPlugin;

/// A mock handler for the flutter_local_notifications method channel that
/// records which methods were invoked and returns configurable values.
class FakeNotificationsChannel {
  final List<String> invokedMethods = [];

  bool canScheduleExact = true;
  bool? requestExactResult = true;
  bool requestNotificationsResult = true;

  Future<Object?> handle(MethodCall call) async {
    invokedMethods.add(call.method);
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

  void installMocks(FakeNotificationsChannel fake) {
    messenger.setMockMethodCallHandler(notificationsChannel, fake.handle);
    messenger.setMockMethodCallHandler(
      timezoneChannel,
      (call) async => 'Europe/Warsaw',
    );
  }

  void removeMocks() {
    messenger.setMockMethodCallHandler(notificationsChannel, null);
    messenger.setMockMethodCallHandler(timezoneChannel, null);
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

    test('scheduleDailyReminder does not crash', () async {
      final result = await NotificationService.instance.scheduleDailyReminder(
        const (hour: 8, minute: 0),
      );
      expect(result, isA<bool>());
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

    test('initialize completes successfully and becomes idempotent', () async {
      await NotificationService.instance.initialize();
      await NotificationService.instance.initialize();

      // The channel was created once during the first initialization.
      expect(
        fake.invokedMethods.where((m) => m == 'createNotificationChannel'),
        hasLength(1),
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

    test('cancelDailyReminder invokes the platform cancel', () async {
      await NotificationService.instance.initialize();

      await NotificationService.instance.cancelDailyReminder();

      expect(fake.invokedMethods, contains('cancel'));
    });
  });

  group('NotificationService failing platform channels', () {
    setUp(() {
      messenger.setMockMethodCallHandler(
        notificationsChannel,
        (call) async => throw PlatformException(code: 'TEST_FAILURE'),
      );
      messenger.setMockMethodCallHandler(
        timezoneChannel,
        (call) async => throw PlatformException(code: 'TEST_FAILURE'),
      );
    });

    test('canScheduleExactNotifications falls back to true on error', () async {
      expect(
        await NotificationService.instance.canScheduleExactNotifications(),
        isTrue,
      );
    });

    test('requestExactAlarmsPermission returns false on error', () async {
      expect(
        await NotificationService.instance.requestExactAlarmsPermission(),
        isFalse,
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

    test('cancelDailyReminder swallows platform errors', () async {
      await expectLater(
        NotificationService.instance.cancelDailyReminder(),
        completes,
      );
    });
  });
}
