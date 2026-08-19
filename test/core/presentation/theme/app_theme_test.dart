import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';

void main() {
  group('AppTheme.lightColorScheme', () {
    test('is a light scheme', () {
      expect(AppTheme.lightColorScheme.brightness, Brightness.light);
      // The light primary color is a hand-tuned variant of the brand anchor.
      expect(AppTheme.lightColorScheme.primary, const Color(0xFF005BDE));
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

    test('has primary colors from the correct hue family', () {
      expect(
        AppTheme.darkColorScheme.primaryContainer,
        const Color(0xFF0044A5),
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
        BorderRadius.circular(16),
      );
    });

    test('stylizes filled buttons with a 48px height and bounded width', () {
      final style = AppTheme.lightTheme.filledButtonTheme.style;
      final minimumSize = style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(minimumSize, const Size(64, 48));
      // A finite minimum width keeps buttons valid inside unbounded
      // horizontal contexts such as bottom-sheet action rows.
      expect(minimumSize.width.isFinite, isTrue);
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
        BorderRadius.circular(16),
      );
      expect(
        (AppTheme.lightTheme.bottomSheetTheme.shape! as RoundedRectangleBorder)
            .borderRadius,
        const BorderRadius.vertical(top: Radius.circular(16)),
      );
    });

    test('configures elevated, outlined, and text button themes', () {
      final elevated = AppTheme.lightTheme.elevatedButtonTheme.style;
      expect(elevated?.elevation?.resolve({}), 1);
      final outlined = AppTheme.lightTheme.outlinedButtonTheme.style;
      expect(outlined?.minimumSize?.resolve({}), const Size(64, 48));
      final text = AppTheme.lightTheme.textButtonTheme.style;
      expect(text?.shape?.resolve({}), isA<RoundedRectangleBorder>());
    });

    test('configures fab, chip, and snackbar themes', () {
      final fab = AppTheme.lightTheme.floatingActionButtonTheme;
      expect(fab.elevation, 2);
      expect(fab.backgroundColor, AppTheme.lightColorScheme.primary);

      final chip = AppTheme.lightTheme.chipTheme;
      expect(chip.selectedColor, AppTheme.lightColorScheme.primaryContainer);

      final snack = AppTheme.lightTheme.snackBarTheme;
      expect(snack.behavior, SnackBarBehavior.floating);
      expect(
        snack.backgroundColor,
        AppTheme.lightColorScheme.secondaryContainer,
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
        BorderRadius.circular(16),
      );
    });

    test('stylizes filled buttons with a 48px height and bounded width', () {
      final style = AppTheme.darkTheme.filledButtonTheme.style;
      final minimumSize = style?.minimumSize?.resolve({}) ?? Size.zero;
      expect(minimumSize, const Size(64, 48));
      // A finite minimum width keeps buttons valid inside unbounded
      // horizontal contexts such as bottom-sheet action rows.
      expect(minimumSize.width.isFinite, isTrue);
    });

    test('configures input decoration with rounded outline borders', () {
      final input = AppTheme.darkTheme.inputDecorationTheme;
      expect(input.filled, isTrue);
      expect(input.fillColor, AppTheme.darkColorScheme.surfaceContainerHighest);
      final focused = input.focusedBorder! as OutlineInputBorder;
      expect(focused.borderRadius, BorderRadius.circular(8));
      expect(focused.borderSide.color, AppTheme.darkColorScheme.primary);
    });

    test('uses rounded dialog and bottom sheet shapes in dark theme', () {
      expect(
        (AppTheme.darkTheme.dialogTheme.shape! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.circular(16),
      );
      expect(
        (AppTheme.darkTheme.bottomSheetTheme.shape! as RoundedRectangleBorder)
            .borderRadius,
        const BorderRadius.vertical(top: Radius.circular(16)),
      );
    });

    test(
      'configures elevated, outlined, text button, fab, chip, and snackbar in dark theme',
      () {
        final elevated = AppTheme.darkTheme.elevatedButtonTheme.style;
        expect(elevated?.elevation?.resolve({}), 1);

        final outlined = AppTheme.darkTheme.outlinedButtonTheme.style;
        expect(outlined?.minimumSize?.resolve({}), const Size(64, 48));

        final text = AppTheme.darkTheme.textButtonTheme.style;
        expect(text?.shape?.resolve({}), isA<RoundedRectangleBorder>());

        final fab = AppTheme.darkTheme.floatingActionButtonTheme;
        expect(fab.backgroundColor, AppTheme.darkColorScheme.primary);

        final chip = AppTheme.darkTheme.chipTheme;
        expect(chip.selectedColor, AppTheme.darkColorScheme.primaryContainer);

        final snack = AppTheme.darkTheme.snackBarTheme;
        expect(snack.behavior, SnackBarBehavior.floating);
        expect(
          snack.backgroundColor,
          AppTheme.darkColorScheme.secondaryContainer,
        );
      },
    );
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
