// custom_colors.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

extension CustomColors on ThemeData {
  /// Returns the project’s primary black color.
  Color get black => AppColors.black;

  /// Returns the project’s primary white color.
  Color get white => AppColors.white;

  /// Returns the default gray color (using gray1 from the new scheme).
  Color get gray => AppColors.gray1;

  /// Returns the light gray color (gray2 from the new scheme).
  Color get lightGray => AppColors.gray2;

  /// Returns the primary color (cyan).
  Color get primary => AppColors.cyan;

  /// Returns the secondary color (orange).
  Color get secondary => AppColors.orange;

  /// Returns the error color (red).
  Color get errorColor => AppColors.red;
}
