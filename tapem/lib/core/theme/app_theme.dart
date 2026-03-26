import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the cyberpunk [ThemeData] for a given [ThemePreset] accent color.
/// All three theme presets (default/energy/minimal) share the same dark base —
/// only the accent seed differs.
ThemeData buildAppTheme(Color accentColor) {
  final colorScheme = ColorScheme.dark(
    primary: accentColor,
    onPrimary: AppColors.textOnAction,
    secondary: AppColors.neonMagenta,
    onSecondary: AppColors.textOnAction,
    surface: AppColors.surface800,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surface700,
    error: AppColors.error,
    onError: AppColors.textPrimary,
    outline: AppColors.surface500,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surface900,
    fontFamily: 'Rajdhani',

    // ─── AppBar ────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface900,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),

    // ─── Bottom Navigation ─────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface800,
      indicatorColor: accentColor.withAlpha(40),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: accentColor, size: 24);
        }
        return const IconThemeData(color: AppColors.textSecondary, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelSm.copyWith(color: accentColor);
        }
        return AppTextStyles.labelSm;
      }),
      elevation: 0,
      height: 64,
    ),

    // ─── Cards ─────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.surface800,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.surface500, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // ─── ElevatedButton ────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: AppColors.textOnAction,
        disabledBackgroundColor: AppColors.surface600,
        disabledForegroundColor: AppColors.textDisabled,
        textStyle: AppTextStyles.buttonMd,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
    ),

    // ─── OutlinedButton ────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: BorderSide(color: accentColor, width: 1.5),
        textStyle: AppTextStyles.buttonMd,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),

    // ─── TextButton ────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        textStyle: AppTextStyles.buttonMd,
      ),
    ),

    // ─── Input fields ──────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface600,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.surface500),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.surface500),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      labelStyle: AppTextStyles.labelMd,
      hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textDisabled),
      errorStyle: AppTextStyles.bodySm.copyWith(color: AppColors.error),
    ),

    // ─── Divider ───────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.surface500,
      thickness: 1,
      space: 1,
    ),

    // ─── Chip ──────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface700,
      selectedColor: accentColor.withAlpha(30),
      labelStyle: AppTextStyles.labelMd,
      side: const BorderSide(color: AppColors.surface500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // ─── Dialog ────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface800,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: accentColor.withAlpha(80), width: 1),
      ),
      titleTextStyle: AppTextStyles.h3,
      contentTextStyle: AppTextStyles.bodyMd,
    ),

    // ─── SnackBar ──────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface700,
      contentTextStyle: AppTextStyles.bodyMd,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      behavior: SnackBarBehavior.floating,
    ),

    // ─── Progress indicator ────────────────────────────────────────────────
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentColor,
      linearTrackColor: AppColors.surface600,
      circularTrackColor: AppColors.surface600,
    ),

    // ─── Switch / Checkbox ─────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? accentColor
            : AppColors.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? accentColor.withAlpha(60)
            : AppColors.surface600,
      ),
    ),

    // ─── List tiles ────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: AppTextStyles.bodyLg,
      subtitleTextStyle: AppTextStyles.bodySm,
    ),
  );
}
