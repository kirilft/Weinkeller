// font_theme.dart
import 'package:flutter/material.dart';
import './app_colors.dart';

class FontTheme {
  /// Returns a TextTheme based on the given [brightness].
  static TextTheme getTextTheme(Brightness brightness) {
    // Use black for light mode and white for dark mode as default text colors.
    final defaultTextColor =
        brightness == Brightness.light ? AppColors.black : AppColors.white;
    // Default blue color for footnote (used for links).
    const footnoteDefaultColor = Color(0xFF007AFF);

    return TextTheme(
      // #title (Large Title/Regular)
      // Note: textAlign is a widget property, so set it on your Text widget if needed.
      headlineLarge: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 34,
        fontWeight: FontWeight.w400,
        height: 41 / 34, // Equivalent to 41px line height
        letterSpacing: 0.4,
        color: defaultTextColor,
      ),
      // #H1 (Title1/Regular)
      headlineMedium: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 34 / 28, // 34px line height
        letterSpacing: 0.38,
        color: defaultTextColor,
      ),
      // #H2 (Title2/Regular)
      headlineSmall: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 22,
        fontWeight: FontWeight.w400,
        height: 28 / 22, // 28px line height
        letterSpacing: -0.26,
        color: defaultTextColor,
      ),
      // #h3 (Title3/Regular)
      titleLarge: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 20,
        fontWeight: FontWeight.w400,
        height: 25 / 20, // 25px line height
        letterSpacing: -0.45,
        color: defaultTextColor,
      ),
      // #regular (Body/Regular)
      bodyLarge: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 22 / 17, // 22px line height
        letterSpacing: -0.43,
        color: defaultTextColor,
      ),
      // #Footnote (Footnote/Regular) – defaults to blue for links
      bodySmall: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13, // 18px line height
        letterSpacing: -0.08,
        color: footnoteDefaultColor,
      ),
    );
  }
}
