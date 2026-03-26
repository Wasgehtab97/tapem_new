import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/providers/profile_provider.dart';

/// Resolves the active ThemeData based on user profile theme_key.
/// Theme change is immediate and app-wide — no restart required.
final activeThemeProvider = Provider<ThemeData>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  final themeKey = profile?.themeKey ?? 'default';
  final preset = ThemePreset.fromKey(themeKey);
  return buildAppTheme(preset.accentColor);
});
