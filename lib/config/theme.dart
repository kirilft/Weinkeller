import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String themeModeKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(themeModeKey) ?? ThemeMode.system.index;
    _themeMode =
        ThemeMode.values.elementAtOrNull(themeIndex) ?? ThemeMode.system;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, mode.index);
  }

  ThemeData _buildTheme(Brightness brightness) {
    // Create a base color scheme from your primary swatch
    final baseColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      brightness: brightness,
    );

    // Customize it as needed
    final colorScheme = baseColorScheme.copyWith(
      // Example: define secondary to ensure good contrast in dark mode
      secondary: Colors.amber,
      secondaryContainer: brightness == Brightness.dark
          ? Colors.amber.shade700
          : Colors.amber.shade100,
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      fontFamily: 'SFProDisplay',
      // Let elevated buttons reference colorScheme automatically
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    );
  }
}
