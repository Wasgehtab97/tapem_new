import 'package:flutter/material.dart';

/// Cyberpunk design token palette.
/// All color references in the app go through these tokens — never raw hex.
abstract final class AppColors {
  // ─── Surface ─────────────────────────────────────────────────────────────
  static const surface900 = Color(0xFF0A0A0F); // deepest background
  static const surface800 = Color(0xFF12121A); // card background
  static const surface700 = Color(0xFF1A1A26); // elevated card
  static const surface600 = Color(0xFF22223A); // input fields
  static const surface500 = Color(0xFF2E2E50); // border/divider

  // ─── Neon accent — cyan (primary action) ─────────────────────────────────
  static const neonCyan = Color(0xFF00E5FF);
  static const neonCyanDim = Color(0xFF0097A7);
  static const neonCyanGlow = Color(0x3300E5FF);

  // ─── Neon accent — magenta (XP / level) ──────────────────────────────────
  static const neonMagenta = Color(0xFFE040FB);
  static const neonMagentaDim = Color(0xFF7B1FA2);
  static const neonMagentaGlow = Color(0x33E040FB);

  // ─── Neon accent — yellow (warning / highlight) ───────────────────────────
  static const neonYellow = Color(0xFFFFEA00);
  static const neonYellowDim = Color(0xFFF9A825);
  static const neonYellowGlow = Color(0x33FFEA00);

  // ─── Semantic ────────────────────────────────────────────────────────────
  static const success = Color(0xFF00E676);
  static const successGlow = Color(0x3300E676);
  static const warning = Color(0xFFFFEA00);
  static const error = Color(0xFFFF1744);
  static const errorGlow = Color(0x33FF1744);

  // ─── Text ────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFEEEEFF);
  static const textSecondary = Color(0xFF9090B0);
  static const textDisabled = Color(0xFF555570);
  static const textOnAction = Color(0xFF0A0A0F);

  // ─── Sync state ──────────────────────────────────────────────────────────
  static const syncLocalSaved = Color(0xFF9090B0);
  static const syncPending = Color(0xFFFFEA00);
  static const syncConfirmed = Color(0xFF00E676);
  static const syncFailed = Color(0xFFFF1744);

  // ─── Theme presets (seed colors) ─────────────────────────────────────────
  static const themeDefault = neonCyan;
  static const themeEnergy = neonMagenta;
  static const themeMinimal = Color(0xFF78909C);
}

/// Theme preset keys matching `user_profiles.theme_key` in the DB.
enum ThemePreset {
  defaultTheme('default'),
  energy('energy'),
  minimal('minimal');

  const ThemePreset(this.key);
  final String key;

  static ThemePreset fromKey(String key) => ThemePreset.values.firstWhere(
    (t) => t.key == key,
    orElse: () => ThemePreset.defaultTheme,
  );

  Color get accentColor => switch (this) {
    ThemePreset.defaultTheme => AppColors.themeDefault,
    ThemePreset.energy => AppColors.themeEnergy,
    ThemePreset.minimal => AppColors.themeMinimal,
  };
}
