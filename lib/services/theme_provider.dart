// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // Define the keys for SharedPreferences
  static const String themeModeKey = 'themeMode';

  // Initialize with system theme
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  // Load the saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(themeModeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  // Update the theme mode and save it to SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, mode.index);
  }
}
