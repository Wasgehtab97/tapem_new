import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Primary action button — cyberpunk style with press animation,
/// optional loading/disabled state, and screen-reader semantics.
class TapemButton extends StatefulWidget {
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
  State<TapemButton> createState() => _TapemButtonState();
}

class _TapemButtonState extends State<TapemButton> {
  bool _pressed = false;

  bool get _enabled =>
      !widget.isLoading && !widget.isDisabled && widget.onPressed != null;

  void _onTapDown(_) {
    if (_enabled) setState(() => _pressed = true);
  }

  void _onTapUp(_) {
    if (_pressed) setState(() => _pressed = false);
  }

  void _onTapCancel() {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: widget.label,
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: _buildButton(accent),
        ),
      ),
    );
  }

  Widget _buildButton(Color accent) {
    switch (widget.variant) {
      case TapemButtonVariant.primary:
        return ElevatedButton(
          onPressed: _enabled ? widget.onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _enabled ? accent : AppColors.surface600,
            foregroundColor:
                _enabled ? AppColors.textOnAction : AppColors.textDisabled,
            minimumSize: const Size(double.infinity, 52),
          ),
          child: _child(context),
        );
      case TapemButtonVariant.outlined:
        return OutlinedButton(
          onPressed: _enabled ? widget.onPressed : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _enabled ? accent : AppColors.surface500,
            ),
            minimumSize: const Size(double.infinity, 52),
          ),
          child: _child(context),
        );
      case TapemButtonVariant.ghost:
        return TextButton(
          onPressed: _enabled ? widget.onPressed : null,
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
          child: _child(context),
        );
    }
  }

  Widget _child(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8),
          Text(widget.label, style: AppTextStyles.buttonMd),
        ],
      );
    }
    return Text(widget.label, style: AppTextStyles.buttonMd);
  }
}

enum TapemButtonVariant { primary, outlined, ghost }
