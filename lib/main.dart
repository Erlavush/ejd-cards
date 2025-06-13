// lib/main.dart
import 'package:flutter/material.dart';
import 'package:ejd_cards/features/deck_list/screens/deck_list_screen.dart';
import 'package:ejd_cards/core/services/settings_service.dart';
import 'package:ejd_cards/core/theme/app_theme.dart'; // Import our new theme file

// We now need a custom enum for our theme setting
enum AppThemeMode { system, light, dark, amoled }

final ValueNotifier<AppThemeMode> themeNotifier = ValueNotifier(AppThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = SettingsService();
  themeNotifier.value = await settingsService.getThemeMode();
  runApp(const EjdCardsApp());
}

class EjdCardsApp extends StatelessWidget {
  const EjdCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        final brightness = MediaQuery.platformBrightnessOf(context);
        final useDarkTheme = (currentMode == AppThemeMode.dark) ||
                             (currentMode == AppThemeMode.amoled) ||
                             (currentMode == AppThemeMode.system && brightness == Brightness.dark);

        return MaterialApp(
          title: 'EJD Cards',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: (currentMode == AppThemeMode.amoled || (currentMode == AppThemeMode.system && useDarkTheme))
              ? AppTheme.amoledTheme
              : AppTheme.darkTheme,
          themeMode: useDarkTheme ? ThemeMode.dark : ThemeMode.light,
          home: const DeckListScreen(),
        );
      },
    );
  }
}