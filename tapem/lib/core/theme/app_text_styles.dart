import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typographic scale — cyberpunk + technical feel.
abstract final class AppTextStyles {
  static const _mono = TextStyle(fontFamily: 'ShareTechMono');
  static const _display = TextStyle(fontFamily: 'Rajdhani', letterSpacing: 1.2);

  // ─── Display / Hero ───────────────────────────────────────────────────────
  static final displayLg = _display.copyWith(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
  );
  static final displayMd = _display.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  // ─── Headings ─────────────────────────────────────────────────────────────
  static final h1 = _display.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  static final h2 = _display.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );
  static final h3 = _display.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ─── Body ────────────────────────────────────────────────────────────────
  static const bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  static const bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  static const bodySm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ─── Labels ───────────────────────────────────────────────────────────────
  static const labelLg = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
  static const labelMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );
  static const labelSm = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.0,
  );

  // ─── Monospace (XP values, stats, counters) ───────────────────────────────
  static final monoLg = _mono.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    color: AppColors.neonCyan,
    height: 1.1,
  );
  static final monoMd = _mono.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.neonCyan,
  );
  static final monoSm = _mono.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ─── Button ───────────────────────────────────────────────────────────────
  static const buttonLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
  );
  static const buttonMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
}
