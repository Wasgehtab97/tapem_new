import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Primary action button — cyberpunk style with optional loading/disabled state.
class TapemButton extends StatelessWidget {
  const TapemButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.variant = TapemButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final TapemButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final enabled = !isLoading && !isDisabled && onPressed != null;

    return switch (variant) {
      TapemButtonVariant.primary => ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? accent : AppColors.surface600,
          foregroundColor: enabled
              ? AppColors.textOnAction
              : AppColors.textDisabled,
          minimumSize: const Size(double.infinity, 52),
        ),
        child: _child(context),
      ),
      TapemButtonVariant.outlined => OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: enabled ? accent : AppColors.surface500),
          minimumSize: const Size(double.infinity, 52),
        ),
        child: _child(context),
      ),
      TapemButtonVariant.ghost => TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
        ),
        child: _child(context),
      ),
    };
  }

  Widget _child(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.buttonMd),
        ],
      );
    }
    return Text(label, style: AppTextStyles.buttonMd);
  }
}

enum TapemButtonVariant { primary, outlined, ghost }
