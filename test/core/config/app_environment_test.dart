import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/config/app_environment.dart';

void main() {
  group('AppEnvironment Tests', () {
    test('returns correct notificationChannelId per environment', () {
      expect(
        AppEnvironment.dev.notificationChannelId,
        equals('daily_weight_reminders_dev_v1'),
      );
      expect(
        AppEnvironment.prod.notificationChannelId,
        equals('daily_weight_reminders_v2'),
      );
    });

    test('current environment evaluates boolean getters consistently', () {
      final current = AppEnvironment.current;
      if (current == AppEnvironment.dev) {
        expect(AppEnvironment.isDev, isTrue);
        expect(AppEnvironment.isProd, isFalse);
      } else {
        expect(AppEnvironment.isDev, isFalse);
        expect(AppEnvironment.isProd, isTrue);
      }
    });
  });
}
