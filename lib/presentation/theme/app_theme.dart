import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFFF7F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF2C2848);
  static const Color inkSoft = Color(0xFF6B5F9A);
  static const Color muted = Color(0xFF9892A8);
  static const Color line = Color(0xFFECE8F7);

  static const Color lavender50 = Color(0xFFF3F0FC);
  static const Color lavender100 = Color(0xFFE4DFF5);
  static const Color lavender200 = Color(0xFFD4CCF5);
  static const Color lavender300 = Color(0xFFB6AAF0);
  static const Color lavender500 = Color(0xFF8A7DDC);
  static const Color lavender600 = Color(0xFF6B5FCC);

  static const Color mint100 = Color(0xFFD8EFE5);
  static const Color mint200 = Color(0xFFB8D8D0);
  static const Color peach100 = Color(0xFFFDE0D4);
  static const Color peach200 = Color(0xFFF5CDB8);
  static const Color pink100 = Color(0xFFF5D4E8);
  static const Color pink200 = Color(0xFFF5B8B0);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Pretendard',
    colorScheme: ColorScheme.fromSeed(
      seedColor: lavender500,
      brightness: Brightness.light,
      primary: lavender500,
      secondary: lavender600,
      surface: surface,
      outline: line,
      onPrimary: surface,
      onSecondary: surface,
      onSurface: ink,
    ),
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: bg,
      foregroundColor: ink,
    ),
    dividerTheme: const DividerThemeData(color: line),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: line),
      ),
      color: surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lavender500,
        foregroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lavender500,
        side: const BorderSide(color: lavender500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: lavender50,
      checkmarkColor: lavender500,
      side: const BorderSide(color: line),
      labelStyle: const TextStyle(color: inkSoft),
      secondaryLabelStyle: const TextStyle(color: lavender600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lavender500),
      ),
      filled: true,
      fillColor: surface,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: lavender500,
      unselectedItemColor: muted,
      backgroundColor: surface,
      elevation: 0,
    ),
  );
}
