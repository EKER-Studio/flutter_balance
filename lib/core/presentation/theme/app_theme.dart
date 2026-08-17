import 'package:flutter/material.dart';

/// Material 3 theme definitions for the Balance (Serene Metric) design system.
abstract final class AppTheme {
  /// The primary brand color anchor: Vibrant Blue #006CFF.
  static const Color primaryColor = Color(0xFF006CFF);

  /// The light [ColorScheme], a hand-tuned Material 3 palette anchored at [primaryColor].
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF005BDE),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD8E2FF),
    onPrimaryContainer: Color(0xFF001A41),
    primaryFixed: Color(0xFFD8E2FF),
    primaryFixedDim: Color(0xFFADC6FF),
    onPrimaryFixed: Color(0xFF001A41),
    onPrimaryFixedVariant: Color(0xFF0044A5),
    secondary: Color(0xFF565E71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDAE2F9),
    onSecondaryContainer: Color(0xFF131C2C),
    secondaryFixed: Color(0xFFDAE2F9),
    secondaryFixedDim: Color(0xFFBEC6DC),
    onSecondaryFixed: Color(0xFF131C2C),
    onSecondaryFixedVariant: Color(0xFF3E4758),
    tertiary: Color(0xFF705574),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFBD7FC),
    onTertiaryContainer: Color(0xFF28132C),
    tertiaryFixed: Color(0xFFFBD7FC),
    tertiaryFixedDim: Color(0xFFDEBCDF),
    onTertiaryFixed: Color(0xFF28132C),
    onTertiaryFixedVariant: Color(0xFF573E5B),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFF9F9FF),
    onSurface: Color(0xFF191C20),
    surfaceDim: Color(0xFFD9D9E0),
    surfaceBright: Color(0xFFF9F9FF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3F3FA),
    surfaceContainer: Color(0xFFEDEDF4),
    surfaceContainerHigh: Color(0xFFE7E7EE),
    surfaceContainerHighest: Color(0xFFE2E2E9),
    onSurfaceVariant: Color(0xFF44474F),
    outline: Color(0xFF74777F),
    outlineVariant: Color(0xFFC4C6D0),
    inverseSurface: Color(0xFF2E3036),
    onInverseSurface: Color(0xFFF0F0F7),
    inversePrimary: Color(0xFFADC6FF),
    surfaceTint: Color(0xFF005BDE),
  );

  /// The dark [ColorScheme], a hand-tuned counterpart of [lightColorScheme] with the
  /// same tonal roles shifted to dark brightness for consistent contrast.
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFADC6FF),
    onPrimary: Color(0xFF002E69),
    primaryContainer: Color(0xFF0044A5),
    onPrimaryContainer: Color(0xFFD8E2FF),
    primaryFixed: Color(0xFFD8E2FF),
    primaryFixedDim: Color(0xFFADC6FF),
    onPrimaryFixed: Color(0xFF001A41),
    onPrimaryFixedVariant: Color(0xFF0044A5),
    secondary: Color(0xFFBEC6DC),
    onSecondary: Color(0xFF283041),
    secondaryContainer: Color(0xFF3E4758),
    onSecondaryContainer: Color(0xFFDAE2F9),
    secondaryFixed: Color(0xFFDAE2F9),
    secondaryFixedDim: Color(0xFFBEC6DC),
    onSecondaryFixed: Color(0xFF131C2C),
    onSecondaryFixedVariant: Color(0xFF3E4758),
    tertiary: Color(0xFFDEBCDF),
    onTertiary: Color(0xFF402844),
    tertiaryContainer: Color(0xFF573E5B),
    onTertiaryContainer: Color(0xFFFBD7FC),
    tertiaryFixed: Color(0xFFFBD7FC),
    tertiaryFixedDim: Color(0xFFDEBCDF),
    onTertiaryFixed: Color(0xFF28132C),
    onTertiaryFixedVariant: Color(0xFF573E5B),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF111318),
    onSurface: Color(0xFFE2E2E9),
    surfaceDim: Color(0xFF111318),
    surfaceBright: Color(0xFF37393E),
    surfaceContainerLowest: Color(0xFF0C0E13),
    surfaceContainerLow: Color(0xFF191C20),
    surfaceContainer: Color(0xFF1D2024),
    surfaceContainerHigh: Color(0xFF282A2F),
    surfaceContainerHighest: Color(0xFF33353A),
    onSurfaceVariant: Color(0xFFC4C6D0),
    outline: Color(0xFF8E9099),
    outlineVariant: Color(0xFF44474F),
    inverseSurface: Color(0xFFE2E2E9),
    onInverseSurface: Color(0xFF2E3036),
    inversePrimary: Color(0xFF005BDE),
    surfaceTint: Color(0xFFADC6FF),
  );

  /// The custom typography based on the Material 3 type scale using Roboto.
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

  /// The light theme [ThemeData].
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: lightColorScheme.surface,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      elevation: 0,
      color: lightColorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightColorScheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightColorScheme.error, width: 2),
      ),
      errorStyle: TextStyle(
        color: lightColorScheme.error,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selectedColor: lightColorScheme.primaryContainer,
      secondarySelectedColor: lightColorScheme.primaryContainer,
      labelStyle: TextStyle(color: lightColorScheme.onSurface),
      secondaryLabelStyle: TextStyle(
        color: lightColorScheme.onPrimaryContainer,
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: lightColorScheme.surfaceContainerHigh,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: lightColorScheme.surfaceContainerLow,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightColorScheme.secondaryContainer,
      contentTextStyle: TextStyle(color: lightColorScheme.onSecondaryContainer),
      actionTextColor: lightColorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  /// The dark theme [ThemeData].
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: darkColorScheme.surface,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkColorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: darkColorScheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: darkColorScheme.error, width: 2),
      ),
      errorStyle: TextStyle(
        color: darkColorScheme.error,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selectedColor: darkColorScheme.primaryContainer,
      secondarySelectedColor: darkColorScheme.primaryContainer,
      labelStyle: TextStyle(color: darkColorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: darkColorScheme.onPrimaryContainer),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: darkColorScheme.surfaceContainerHigh,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: darkColorScheme.surfaceContainerLow,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkColorScheme.secondaryContainer,
      contentTextStyle: TextStyle(color: darkColorScheme.onSecondaryContainer),
      actionTextColor: darkColorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
