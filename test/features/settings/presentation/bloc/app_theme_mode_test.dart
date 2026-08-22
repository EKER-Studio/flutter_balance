import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';

void main() {
  group('AppThemeMode', () {
    test('contains all expected theme mode options in order', () {
      expect(
        AppThemeMode.values,
        equals([AppThemeMode.system, AppThemeMode.light, AppThemeMode.dark]),
      );
    });

    test('has valid name identifiers', () {
      expect(AppThemeMode.system.name, equals('system'));
      expect(AppThemeMode.light.name, equals('light'));
      expect(AppThemeMode.dark.name, equals('dark'));
    });
  });
}
