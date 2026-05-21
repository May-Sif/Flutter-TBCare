import 'package:flutter/material.dart';

class AppColors {
  // ── Primary palette (teal dari mockup) ──────────────────────────────
  static const Color primary       = Color(0xFF3D8FA0); 
  static const Color primaryLight  = Color(0xFF6FB8CA); 
  static const Color primaryDark   = Color(0xFF2A6B7A);

  // ── Background & Surface ─────────────────────────────────────────────
  static const Color background    = Color(0xFFF5FAFB);
  static const Color background2   = Color(0xFFEFF8FA);
  static const Color surface       = Color(0xFFFFFFFF);

  // ── Card khusus dari mockup ──────────────────────────────────────────
  static const Color cardObat      = Color(0xFFD6EEF2);
  static const Color cardGreeting  = Color(0xFFEEF0F2); 
  static const Color cardProfil    = Color(0xFFCCEEF2); 
  static const Color cardPengingat = Color(0xFFE4E0EC);
  static const Color cardWarning   = Color(0xFFFFF3F3);

  // ── Input ────────────────────────────────────────────────────────────
  static const Color inputBorder   = Color(0xFFB8D8E3);
  static const Color inputFill     = Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C9A);

  // ── Tab / Nav ────────────────────────────────────────────────────────
  static const Color tabActive     = Color(0xFF2A6B7A); // Bottom nav item aktif
  static const Color tabInactive   = Color(0xFFB8D8E3);
  static const Color navBackground = Color(0xFFDDEFF3); // Pill bottom nav background

  // ── Status badge ─────────────────────────────────────────────────────
  static const Color success       = Color(0xFF43A047); // Hijau — SUDAH DIMINUM, ON TRACK
  static const Color error         = Color(0xFFE53935); // Merah — BELUM DIMINUM, error
  static const Color warning       = Color(0xFFFF8F00); // Kuning — WASPADA / info
  static const Color highRisk      = Color(0xFFD32F2F); // Merah gelap — HIGH RISK screening

  // ── Efek samping / peringatan ────────────────────────────────────────
  static const Color waspada       = Color(0xFFE53935); // Badge WASPADA
  static const Color warningBorder = Color(0xFFFFCDD2); // Border card warning

  // ── Misc ─────────────────────────────────────────────────────────────
  static const Color divider       = Color(0xFFCDD8DC);
  static const Color borderProfil  = Color(0xFF3D8FA0);
  static const Color borderPengingat = Color(0xFFC4B5FD);
  static const Color unguPrimary   = Color(0xFF8B5CF6); // Aksen ungu (card pengingat)

  // ── Alias lama (backward-compat) ────────────────────────────────────
  static const Color primary1      = primary;
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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