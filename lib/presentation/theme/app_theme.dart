import 'package:flutter/material.dart';

/// Centralized Material 3 theme definitions for PureWeight (Serene Metric design system).
abstract final class AppTheme {
  /// Primary brand color anchor: Lavender/Purple #4F378A.
  static const Color primaryColor = Color(0xFF4F378A);

  /// Light ColorScheme matching the full Serene Metric specification in DESIGN.md.
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4F378A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF6750A4),
    onPrimaryContainer: Color(0xFFE0D2FF),
    primaryFixed: Color(0xFFE9DDFF),
    primaryFixedDim: Color(0xFFCFBCFF),
    onPrimaryFixed: Color(0xFF22005D),
    onPrimaryFixedVariant: Color(0xFF4F378A),
    secondary: Color(0xFF625B71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE8DEF9),
    onSecondaryContainer: Color(0xFF686177),
    secondaryFixed: Color(0xFFE8DEF9),
    secondaryFixedDim: Color(0xFFCCC2DC),
    onSecondaryFixed: Color(0xFF1E192B),
    onSecondaryFixedVariant: Color(0xFF4A4358),
    tertiary: Color(0xFF633B48),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF7D5260),
    onTertiaryContainer: Color(0xFFFFCBDA),
    tertiaryFixed: Color(0xFFFFD9E3),
    tertiaryFixedDim: Color(0xFFEEB8C8),
    onTertiaryFixed: Color(0xFF31111D),
    onTertiaryFixedVariant: Color(0xFF633B48),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFDF7FF),
    onSurface: Color(0xFF1D1B20),
    surfaceDim: Color(0xFFDED8E0),
    surfaceBright: Color(0xFFFDF7FF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8F2FA),
    surfaceContainer: Color(0xFFF2ECF4),
    surfaceContainerHigh: Color(0xFFECE6EE),
    surfaceContainerHighest: Color(0xFFE6E0E9),
    onSurfaceVariant: Color(0xFF494551),
    outline: Color(0xFF7A7582),
    outlineVariant: Color(0xFFCBC4D2),
    inverseSurface: Color(0xFF322F35),
    onInverseSurface: Color(0xFFF5EFF7),
    inversePrimary: Color(0xFFCFBCFF),
    surfaceTint: Color(0xFF6750A4),
  );

  /// Dark ColorScheme generated from seed with dark brightness override.
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
  );

  /// Custom typography matching DESIGN.md specification using Roboto.
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: 64 / 57,
      letterSpacing: -0.25,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 32,
      fontWeight: FontWeight.w400,
      height: 40 / 32,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 36 / 28,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 28 / 22,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 24 / 16,
      letterSpacing: 0.15,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 24 / 16,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 20 / 14,
      letterSpacing: 0.25,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 16 / 12,
      letterSpacing: 0.5,
    ),
  );

  /// Light theme ThemeData.
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: lightColorScheme.surface,
        textTheme: textTheme,
        cardTheme: CardThemeData(
          elevation: 0,
          color: lightColorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: lightColorScheme.primaryContainer,
          foregroundColor: lightColorScheme.onPrimaryContainer,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightColorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lightColorScheme.outline, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lightColorScheme.outline, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          selectedColor: lightColorScheme.primaryContainer,
          secondarySelectedColor: lightColorScheme.primaryContainer,
          labelStyle: TextStyle(color: lightColorScheme.onSurface),
          secondaryLabelStyle: TextStyle(color: lightColorScheme.onPrimaryContainer),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: lightColorScheme.surfaceContainerHigh,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          backgroundColor: lightColorScheme.surfaceContainerLow,
        ),
      );

  /// Dark theme ThemeData.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: darkColorScheme.surface,
        textTheme: textTheme,
        cardTheme: CardThemeData(
          elevation: 0,
          color: darkColorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: darkColorScheme.primaryContainer,
          foregroundColor: darkColorScheme.onPrimaryContainer,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkColorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: darkColorScheme.outline, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: darkColorScheme.outline, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          selectedColor: darkColorScheme.primaryContainer,
          secondarySelectedColor: darkColorScheme.primaryContainer,
          labelStyle: TextStyle(color: darkColorScheme.onSurface),
          secondaryLabelStyle: TextStyle(color: darkColorScheme.onPrimaryContainer),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: darkColorScheme.surfaceContainerHigh,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          backgroundColor: darkColorScheme.surfaceContainerLow,
        ),
      );
}
