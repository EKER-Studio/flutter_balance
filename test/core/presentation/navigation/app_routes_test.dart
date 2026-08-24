import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/presentation/navigation/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('defines correct path constants', () {
      expect(AppRoutes.splash, equals('/splash'));
      expect(AppRoutes.error, equals('/error'));
      expect(AppRoutes.onboarding, equals('/onboarding'));
      expect(AppRoutes.shield, equals('/shield'));
      expect(AppRoutes.today, equals('/today'));
      expect(AppRoutes.calendar, equals('/calendar'));
      expect(AppRoutes.statistics, equals('/statistics'));
      expect(AppRoutes.settings, equals('/settings'));
    });

    test('todayWithAddAction constructs valid URI', () {
      expect(AppRoutes.todayWithAddAction(), equals('/today?action=add'));
    });

    test('calendarForDate constructs formatted date URI', () {
      final date = DateTime(2026, 8, 24);
      expect(
        AppRoutes.calendarForDate(date),
        equals('/calendar?date=2026-08-24'),
      );
    });
  });
}
