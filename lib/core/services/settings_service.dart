// lib/core/services/settings_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // Import to get the AppThemeMode enum

class SettingsService {
  // Define keys for shared_preferences
  static const String _keyThemeMode = 'appThemeMode'; // Using a more specific key
  static const String _keyDefaultFrontTime = 'defaultFrontTime';
  static const String _keyDefaultBackTime = 'defaultBackTime';
  static const String _keyAutoplayShuffle = 'autoplayShuffle';
  static const String _keyAutoplayLoop = 'autoplayLoop';

  // Define default values if no setting is stored
  static const int defaultFrontSeconds = 5;
  static const int defaultBackSeconds = 7;
  static const bool defaultShuffle = false;
  static const bool defaultLoop = false;

  // Helper to get the SharedPreferences instance
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // --- Theme Mode ---
  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  Future<AppThemeMode> getThemeMode() async {
    final prefs = await _getPrefs();
    final themeString = prefs.getString(_keyThemeMode);
    // Find the AppThemeMode that matches the stored string, or default to system
    return AppThemeMode.values.firstWhere(
      (e) => e.name == themeString,
      orElse: () => AppThemeMode.system,
    );
  }

  // --- Default Front Time ---
  Future<void> setDefaultFrontTime(int seconds) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyDefaultFrontTime, seconds);
  }

  Future<int> getDefaultFrontTime() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyDefaultFrontTime) ?? defaultFrontSeconds;
  }

  // --- Default Back Time ---
  Future<void> setDefaultBackTime(int seconds) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyDefaultBackTime, seconds);
  }

  Future<int> getDefaultBackTime() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyDefaultBackTime) ?? defaultBackSeconds;
  }

  // --- Autoplay Shuffle ---
  Future<void> setAutoplayShuffle(bool shuffle) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyAutoplayShuffle, shuffle);
  }

  Future<bool> getAutoplayShuffle() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyAutoplayShuffle) ?? defaultShuffle;
  }

  // --- Autoplay Loop ---
  Future<void> setAutoplayLoop(bool loop) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyAutoplayLoop, loop);
  }

  Future<bool> getAutoplayLoop() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyAutoplayLoop) ?? defaultLoop;
  }
}