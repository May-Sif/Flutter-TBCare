import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4A7B8C);
  static const Color primaryLight = Color(0xFF6FA3B3);
  static const Color primaryDark = Color(0xFF2E5F6E);
  static const Color background = Color(0xFFF0F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFB8D8E3);
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C9A);
  static const Color tabActive = Color(0xFF4A7B8C);
  static const Color tabInactive = Color(0xFFB8D8E3);
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF27AE60);
  static const Color divider = Color(0xFFCDD8DC);
  static const Color primary1 = Color(0xFF577C8E); // Biru kehijauan dari desain
  static const Color background2 = Color(0xFFF4FBFC); // Background dari desain
  static const Color cardProfil = Color(0xFFCCEEF2); // Biru muda dari desain
  static const Color borderProfil = Color(0xFF577C8E); // Border biru
  static const Color cardPengingat = Color(0xFFE4E0EC); // Ungu muda dari desain
  static const Color borderPengingat = Color(0xFFC4B5FD);
  static const Color unguPrimary = Color(0xFF8B5CF6);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}