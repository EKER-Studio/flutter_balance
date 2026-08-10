import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';

void main() {
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
}
