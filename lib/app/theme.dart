import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const primaryBlue = Color(0xFF3155FF);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F7FF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF101828),
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E9F2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE3F3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE3F3)),
      ),
    ),
  );
}
