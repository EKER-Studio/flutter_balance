import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';

void main() {
  group('WeightGoalMode Enum Tests', () {
    test('contains expected enum values in order', () {
      expect(WeightGoalMode.values, [
        WeightGoalMode.lose,
        WeightGoalMode.maintain,
        WeightGoalMode.gain,
      ]);
    });

    test('enum name string values match contract', () {
      expect(WeightGoalMode.lose.name, 'lose');
      expect(WeightGoalMode.maintain.name, 'maintain');
      expect(WeightGoalMode.gain.name, 'gain');
    });
  });
}
