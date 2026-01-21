import 'package:flutter/material.dart';

class AppTheme {
  // 🌸 Pink / Rose Theme for Women Safety App
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: const Color(0xFFFFF7FA),

    primaryColor: const Color(0xFFF06292),

    colorScheme: ColorScheme.light(
      primary: const Color(0xFFF06292),
      secondary: const Color(0xFFFCE4EC),
      surface: Colors.white,
      error: const Color(0xFFE53935),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF3A2A2A),
      elevation: 0,
      centerTitle: true,
    ),

    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: Color(0xFF3A2A2A),
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: Color(0xFF3A2A2A)),
      bodyMedium: TextStyle(color: Color(0xFF8E6E73)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFCE4EC),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFF06292),
          width: 1.5,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF06292),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFF06292),
        side: const BorderSide(color: Color(0xFFF06292)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}
