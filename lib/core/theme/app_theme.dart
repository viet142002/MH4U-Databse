import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceVariant = Color(0xFF252525);
  static const primary = Color(0xFFD4A017); // MH gold
  static const primaryDark = Color(0xFF9E7512);
  static const secondary = Color(0xFFB22222); // MH red
  static const onBackground = Color(0xFFE8E0D0);
  static const onSurface = Color(0xFFCDC5B5);
  static const onSurfaceMuted = Color(0xFF8A8070);
  static const divider = Color(0xFF2E2E2E);
  static const error = Color(0xFFCF6679);

  // Element colors
  static const elementFire = Color(0xFFFF4500);
  static const elementWater = Color(0xFF1E90FF);
  static const elementThunder = Color(0xFFFFD700);
  static const elementIce = Color(0xFF87CEEB);
  static const elementDragon = Color(0xFF8B008B);
  static const elementPoison = Color(0xFF9400D3);
  static const elementBlast = Color(0xFFFF8C00);
}

final mh4uTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    error: AppColors.error,
    onPrimary: Colors.black,
    onSecondary: Colors.white,
    onSurface: AppColors.onSurface,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.primary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.primary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: AppColors.divider, width: 1),
    ),
    margin: EdgeInsets.zero,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.onSurfaceMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: AppColors.onSurfaceMuted),
    prefixIconColor: AppColors.onSurfaceMuted,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surfaceVariant,
    labelStyle: const TextStyle(color: AppColors.onSurface, fontSize: 12),
    side: const BorderSide(color: AppColors.divider),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.onBackground,
      fontSize: 28,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      color: AppColors.onBackground,
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: AppColors.onBackground,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: AppColors.onBackground,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(color: AppColors.onSurface, fontSize: 14),
    bodyMedium: TextStyle(color: AppColors.onSurface, fontSize: 13),
    bodySmall: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
    labelLarge: TextStyle(
      color: AppColors.primary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  ),
);
