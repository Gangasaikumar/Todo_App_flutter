import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFE082), // Pastel Yellow
      primary: const Color(0xFFFFE082),
      secondary: const Color(0xFFFFCC80), // Pastel Orange
      surface: Colors.white,
      onPrimary: Colors.black, // Dark text on light pastel yellow for contrast
      onSecondary: Colors.black,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5FA),
    fontFamily: 'Roboto',
    cardColor: Colors.white,
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFE082),
      foregroundColor: Colors.black, // Dark text on light bar
      elevation: 0,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: const Color(0xFFFFE082),
      headerForegroundColor: Colors.black,
      confirmButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.black),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      cancelButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.grey[700]),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFE082),
      brightness: Brightness.dark,
      primary: const Color(0xFFFFE082),
      secondary: const Color(0xFFFFCC80),
      surface: const Color(0xFF1E1E1E),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: 'Roboto',
    cardColor: const Color(0xFF1E1E1E),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
