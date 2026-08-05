import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/presentation/theme/app_theme.dart';

void main() {
  group('AppTheme.lightColorScheme', () {
    test('is a light scheme anchored at the primary color', () {
      expect(AppTheme.lightColorScheme.brightness, Brightness.light);
      expect(AppTheme.lightColorScheme.primary, AppTheme.primaryColor);
    });

    test('defines all tonal surface roles', () {
      final scheme = AppTheme.lightColorScheme;
      expect(scheme.surface, isNot(scheme.onSurface));
      expect(scheme.surfaceContainerLowest, isNotNull);
      expect(scheme.surfaceContainerHighest, isNotNull);
      expect(scheme.onPrimary, isNotNull);
      expect(scheme.outline, isNotNull);
    });
  });

  group('AppTheme.darkColorScheme', () {
    test('is a dark scheme', () {
      expect(AppTheme.darkColorScheme.brightness, Brightness.dark);
    });

    test('shares the same hue family as the light scheme', () {
      expect(
        AppTheme.darkColorScheme.primaryContainer,
        AppTheme.lightColorScheme.primary,
      );
    });
  });

  group('AppTheme.lightTheme', () {
    test('uses Material 3 and the light color scheme', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme, AppTheme.lightColorScheme);
      expect(theme.scaffoldBackgroundColor, AppTheme.lightColorScheme.surface);
      expect(theme.textTheme.displayLarge?.fontFamily, 'Roboto');
    });

    test('uses rounded card theme with no elevation', () {
      final card = AppTheme.lightTheme.cardTheme;
      expect(card.elevation, 0);
      expect(card.shape, isA<RoundedRectangleBorder>());
      expect(
        (card.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(28),
      );
    });

    test('stylizes filled buttons with full-width minimum height', () {
      final style = AppTheme.lightTheme.filledButtonTheme.style;
      final minimumSize = style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(minimumSize, const Size.fromHeight(48));
    });

    test('configures input decoration with rounded outline borders', () {
      final input = AppTheme.lightTheme.inputDecorationTheme;
      expect(input.filled, isTrue);
      expect(
        input.fillColor,
        AppTheme.lightColorScheme.surfaceContainerHighest,
      );
      final focused = input.focusedBorder! as OutlineInputBorder;
      expect(focused.borderRadius, BorderRadius.circular(8));
      expect(focused.borderSide.color, AppTheme.lightColorScheme.primary);
    });

    test('uses rounded dialog and bottom sheet shapes', () {
      expect(
        (AppTheme.lightTheme.dialogTheme.shape! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.circular(28),
      );
      expect(
        (AppTheme.lightTheme.bottomSheetTheme.shape! as RoundedRectangleBorder)
            .borderRadius,
        const BorderRadius.vertical(top: Radius.circular(28)),
      );
    });
  });

  group('AppTheme.darkTheme', () {
    test('uses Material 3 and the dark color scheme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme, AppTheme.darkColorScheme);
      expect(theme.scaffoldBackgroundColor, AppTheme.darkColorScheme.surface);
    });

    test('uses rounded card theme with no elevation', () {
      final card = AppTheme.darkTheme.cardTheme;
      expect(card.elevation, 0);
      expect(card.shape, isA<RoundedRectangleBorder>());
      expect(
        (card.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(28),
      );
    });

    test('stylizes filled buttons with full-width minimum height', () {
      final style = AppTheme.darkTheme.filledButtonTheme.style;
      final minimumSize = style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(minimumSize, const Size.fromHeight(48));
    });

    test('configures input decoration with rounded outline borders', () {
      final input = AppTheme.darkTheme.inputDecorationTheme;
      expect(input.filled, isTrue);
      expect(input.fillColor, AppTheme.darkColorScheme.surfaceContainerHighest);
      final focused = input.focusedBorder! as OutlineInputBorder;
      expect(focused.borderRadius, BorderRadius.circular(8));
      expect(focused.borderSide.color, AppTheme.darkColorScheme.primary);
    });
  });

  group('AppTheme.textTheme', () {
    test('uses Roboto across the type scale', () {
      final text = AppTheme.textTheme;
      expect(text.displayLarge?.fontFamily, 'Roboto');
      expect(text.headlineMedium?.fontFamily, 'Roboto');
      expect(text.titleLarge?.fontFamily, 'Roboto');
      expect(text.bodyLarge?.fontFamily, 'Roboto');
      expect(text.labelLarge?.fontFamily, 'Roboto');
    });

    test('defines distinct sizes for headline and body styles', () {
      expect(AppTheme.textTheme.displayLarge?.fontSize, greaterThan(40));
      expect(AppTheme.textTheme.bodyMedium?.fontSize, 14);
    });
  });
}
