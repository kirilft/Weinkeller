// custom_colors.dart
import 'package:flutter/material.dart';
import 'app_colors.dart'; // Adjust the import path as necessary

extension CustomColors on ThemeData {
  Color get black => brightness == Brightness.light
      ? AppColors.blackLight
      : AppColors.blackDark;
  Color get gray =>
      brightness == Brightness.light ? AppColors.grayLight : AppColors.grayDark;
  Color get gray2 => brightness == Brightness.light
      ? AppColors.gray2Light
      : AppColors.gray2Dark;
  Color get gray3 => brightness == Brightness.light
      ? AppColors.gray3Light
      : AppColors.gray3Dark;
  Color get gray4 => brightness == Brightness.light
      ? AppColors.gray4Light
      : AppColors.gray4Dark;
  Color get gray5 => brightness == Brightness.light
      ? AppColors.gray5Light
      : AppColors.gray5Dark;
  Color get gray6 => brightness == Brightness.light
      ? AppColors.gray6Light
      : AppColors.gray6Dark;
  Color get white => brightness == Brightness.light
      ? AppColors.whiteLight
      : AppColors.whiteDark;
  Color get red =>
      brightness == Brightness.light ? AppColors.redLight : AppColors.redDark;
  Color get orange => brightness == Brightness.light
      ? AppColors.orangeLight
      : AppColors.orangeDark;
  Color get yellow => brightness == Brightness.light
      ? AppColors.yellowLight
      : AppColors.yellowDark;
  Color get green => brightness == Brightness.light
      ? AppColors.greenLight
      : AppColors.greenDark;
  Color get turkis => brightness == Brightness.light
      ? AppColors.turkisLight
      : AppColors.turkisDark;
  Color get cyan =>
      brightness == Brightness.light ? AppColors.cyanLight : AppColors.cyanDark;
  Color get lightBlue => brightness == Brightness.light
      ? AppColors.lightBlueLight
      : AppColors.lightBlueDark;
  Color get blue =>
      brightness == Brightness.light ? AppColors.blueLight : AppColors.blueDark;
  Color get purple => brightness == Brightness.light
      ? AppColors.purpleLight
      : AppColors.purpleDark;
  Color get magenta => brightness == Brightness.light
      ? AppColors.magentaLight
      : AppColors.magentaDark;
  Color get pink =>
      brightness == Brightness.light ? AppColors.pinkLight : AppColors.pinkDark;
  Color get brown => brightness == Brightness.light
      ? AppColors.brownLight
      : AppColors.brownDark;
}
