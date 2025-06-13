// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final _baseTextTheme = GoogleFonts.poppinsTextTheme(const TextTheme()).copyWith(
    displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.w600),
    headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold),
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6A5AE0),
      brightness: Brightness.light,
      primary: const Color(0xFF6A5AE0),
      surface: const Color(0xFFFFFFFF),
      background: const Color(0xFFF6F6F9),
    ),
    textTheme: _baseTextTheme.apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFFF6F6F9),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B61FF),
      brightness: Brightness.dark,
      primary: const Color(0xFF7B61FF),
      surface: const Color(0xFF2D2D3A), // Dark Grey Card background
      background: const Color(0xFF1F1F29), // Dark Grey App background
    ),
    textTheme: _baseTextTheme.apply(
      bodyColor: Colors.white70,
      displayColor: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF1F1F29),
  );

  static final amoledTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B61FF),
      brightness: Brightness.dark,
      primary: const Color(0xFF7B61FF),
      surface: const Color(0xFF121212), // Slightly off-black for cards
      background: const Color(0xFF000000), // True black for background
    ),
    textTheme: _baseTextTheme.apply(
      bodyColor: Colors.white70,
      displayColor: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
  );
}