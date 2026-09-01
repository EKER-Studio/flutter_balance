import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';

void main() {
  group('FirstDayOfWeek Enum Tests', () {
    test('contains expected values in order', () {
      expect(FirstDayOfWeek.values, [
        FirstDayOfWeek.system,
        FirstDayOfWeek.monday,
        FirstDayOfWeek.sunday,
      ]);
    });

    test('enum names match expected string representations', () {
      expect(FirstDayOfWeek.system.name, 'system');
      expect(FirstDayOfWeek.monday.name, 'monday');
      expect(FirstDayOfWeek.sunday.name, 'sunday');
    });
  });
}
