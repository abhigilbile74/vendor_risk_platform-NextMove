import 'package:flutter/material.dart';

class MyTheme {
  // 🔵 LIGHT THEME
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF10A37F),
      onPrimary: Colors.white,
      secondary: Color(0xFF10A37F),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Color(0xFFFFFFFF),
      onBackground: Color(0xFF111827),
      surface: Color(0xFFF7F7F8),
      onSurface: Color(0xFF111827),
    ),

    scaffoldBackgroundColor: const Color(0xFFFFFFFF),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF111827),
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFFF7F7F8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF10A37F),
      foregroundColor: Colors.white,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF111827)),
      bodyMedium: TextStyle(color: Color(0xFF6B7280)),
    ),
  );

  // 🌙 DARK THEME
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF10A37F),
      onPrimary: Colors.white,
      secondary: Color(0xFF10A37F),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Color.fromARGB(255, 25, 25, 30),
      onBackground: Color(0xFFECECF1),
      surface: Color(0xFF444654),
      onSurface: Color(0xFFECECF1),
    ),

    scaffoldBackgroundColor: const Color.fromARGB(255, 22, 22, 27),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 29, 31, 41),
      foregroundColor: Color(0xFFECECF1),
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF444654),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF10A37F),
      foregroundColor: Colors.white,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFECECF1)),
      bodyMedium: TextStyle(color: Color.fromARGB(255, 200, 248, 236)),
    ),
  );
}