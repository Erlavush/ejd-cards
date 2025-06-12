// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ejd_cards/features/deck_list/screens/deck_list_screen.dart';
import 'package:ejd_cards/core/services/settings_service.dart';

// Global ValueNotifier for the theme mode.
// This allows any widget in the app to listen to theme changes.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  // Ensure Flutter bindings are initialized before using async operations like loading settings.
  WidgetsFlutterBinding.ensureInitialized();

  // Load the saved theme mode and update the notifier before the app runs.
  final settingsService = SettingsService();
  themeNotifier.value = await settingsService.getThemeMode();

  runApp(const EjdCardsApp());
}

class EjdCardsApp extends StatelessWidget {
  const EjdCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define our custom TextTheme using Google Fonts
    final textTheme = Theme.of(context).textTheme;
    final poppinsTextTheme = GoogleFonts.poppinsTextTheme(textTheme).copyWith(
          displaySmall: GoogleFonts.poppins(textStyle: textTheme.displaySmall, fontWeight: FontWeight.w600),
          headlineMedium: GoogleFonts.poppins(textStyle: textTheme.headlineMedium, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.poppins(textStyle: textTheme.titleLarge, fontWeight: FontWeight.bold),
        );

    // Define our Light Theme
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6A5AE0), // Our primary purple/violet
        brightness: Brightness.light,
        primary: const Color(0xFF6A5AE0),
        surface: const Color(0xFFFFFFFF), // Card backgrounds
        background: const Color(0xFFF6F6F9), // App background
        shadow: Colors.black.withOpacity(0.1),
        surfaceVariant: Colors.grey.shade200,
      ),
      textTheme: poppinsTextTheme,
      scaffoldBackgroundColor: const Color(0xFFF6F6F9),
    );

    // Define our Dark Theme
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7B61FF), // A slightly brighter purple for dark mode
        brightness: Brightness.dark,
        primary: const Color(0xFF7B61FF),
        surface: const Color(0xFF2D2D3A), // Card backgrounds
        background: const Color(0xFF1F1F29), // App background
        shadow: Colors.black.withOpacity(0.2),
        surfaceVariant: Colors.white.withOpacity(0.1),
      ),
      textTheme: poppinsTextTheme,
      scaffoldBackgroundColor: const Color(0xFF1F1F29),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'EJD Cards',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentMode,
          home: const DeckListScreen(),
        );
      },
    );
  }
}