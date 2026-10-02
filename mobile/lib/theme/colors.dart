import 'package:flutter/material.dart';

class AppColors {
  static const darkNavyBlue = Color(0xFF142B4A);
  static const secondaryNavyBlue = Color(0xFF203D63);
  static const deepNavyBlue = Color(0xFF0B1F38);
  static const white = Colors.white;
  static const lightGrey = Color(0xFFF5F7FA);
  static const borderGrey = Color(0xFFE2E8F0);
  static const mainText = Color(0xFF172033);
  static const secondaryText = Color(0xFF64748B);
  static const successGreen = Color(0xFF16A34A);
  static const errorRed = Color(0xFFDC2626);
  static const warningAmber = Color(0xFFD97706);
  static const cardWhite = Colors.white;
}

extension AppColorsExtension on BuildContext {
  AppColors get colors => AppColors();
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.darkNavyBlue,
      onPrimary: AppColors.white,
      secondary: AppColors.secondaryNavyBlue,
      onSecondary: AppColors.white,
      error: AppColors.errorRed,
      onError: AppColors.white,
      surface: AppColors.cardWhite,
      onSurface: AppColors.mainText,
    ),
    scaffoldBackgroundColor: AppColors.lightGrey,
    fontFamily: 'System',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.deepNavyBlue,
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
      headlineMedium: TextStyle(
        color: AppColors.darkNavyBlue,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      headlineSmall: TextStyle(
        color: AppColors.darkNavyBlue,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      bodyLarge: TextStyle(color: AppColors.mainText, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.secondaryText, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.secondaryText, fontSize: 12),
      labelLarge: TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.darkNavyBlue,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.deepNavyBlue,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: AppColors.darkNavyBlue),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.darkNavyBlue,
      unselectedItemColor: AppColors.secondaryText,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkNavyBlue,
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkNavyBlue, width: 2),
      ),
      fillColor: AppColors.white,
      filled: true,
      hintStyle: const TextStyle(color: AppColors.secondaryText),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
