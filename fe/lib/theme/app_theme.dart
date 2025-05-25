import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // === Màu nền và chữ cơ bản ===
  static const Color background = Color(0xFFF2F3F8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color nearlyWhite = Color(0xFFFAFAFA);
  static const Color spacer = Color(0xFFF2F2F2);

  static const Color darkText = Color(0xFF253840);
  static const Color darkerText = Color(0xFF17262A);
  static const Color lightText = Color(0xFF4A6572);
  static const Color deactivatedText = Color(0xFF767676);
  static const Color dismissibleBackground = Color(0xFF364A54);

  // === Màu thương hiệu ===
  static const Color primaryGreen = Color(0xFF4CAF50); // Sức khỏe
  static const Color caloriesOrange = Color(0xFFFF9800); // Calories
  static const Color proteinBlue = Color(0xFF42A5F5); // Protein
  static const Color fatRed = Color(0xFFEF5350); // Fat
  static const Color carbYellow = Color(0xFFFFEB3B); // Carb

  // === Font ===
  static const String fontName = 'WorkSans';

  // === Kiểu chữ chuẩn (Flutter >=3.10) ===
  static const TextTheme textTheme = TextTheme(
    displayLarge: display1,
    headlineMedium: headline,
    titleLarge: title,
    titleSmall: subtitle,
    bodyMedium: body2,
    bodyLarge: body1,
    bodySmall: caption,
  );

  static const TextStyle display1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 36,
    letterSpacing: 0.4,
    height: 0.9,
    color: darkerText,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    letterSpacing: 0.27,
    color: darkerText,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 16,
    letterSpacing: 0.18,
    color: darkerText,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: -0.04,
    color: darkerText,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 0.2,
    color: darkerText,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    letterSpacing: -0.05,
    color: darkerText,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.2,
    color: darkText,
  );
}
