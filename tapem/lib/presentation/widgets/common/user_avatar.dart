import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Reusable circular avatar that shows a real photo or initials fallback.
///
/// When [avatarUrl] is non-null, [CachedNetworkImage] loads and caches the
/// image (disk + memory cache via the `cached_network_image` package).
/// On load failure or when [avatarUrl] is null, the first character of
/// [username] is rendered in a coloured circle instead.
///
/// Pass [borderColor] to draw an accent ring — used in leaderboards to
/// convey rank (gold, silver, bronze) or "current user" (neonCyan).
///
/// Usage examples:
/// ```dart
/// // Profile header — large, glowing cyan border
/// UserAvatar(username: profile.username, radius: 52,
///            avatarUrl: profile.avatarUrl, borderColor: AppColors.neonCyan)
///
/// // Friend list row — compact, no border
/// UserAvatar(username: friend.username, radius: 20, avatarUrl: friend.avatarUrl)
///
/// // Leaderboard row — medal-coloured border
/// UserAvatar(username: entry.username, radius: 16,
///            avatarUrl: entry.avatarUrl, borderColor: medalColor)
/// ```
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.username,
    required this.radius,
    this.avatarUrl,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  final String username;

  /// Circle radius in logical pixels. Diameter = [radius] × 2.
  final double radius;

  /// Remote URL of the profile photo. Null = show initials.
  final String? avatarUrl;

  /// When non-null, a border ring of this colour is drawn around the circle.
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final accent = borderColor ?? Theme.of(context).colorScheme.primary;
    final size = radius * 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withAlpha(22),
        border: borderColor != null
            ? Border.all(color: accent.withAlpha(110), width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => _Initials(
                  username: username,
                  radius: radius,
                  color: accent,
                ),
                errorWidget: (_, __, ___) => _Initials(
                  username: username,
                  radius: radius,
                  color: accent,
                ),
              )
            : _Initials(username: username, radius: radius, color: accent),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.username,
    required this.radius,
    required this.color,
  });

  final String username;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withAlpha(22),
      alignment: Alignment.center,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: AppTextStyles.labelMd.copyWith(
          color: color,
          fontSize: (radius * 0.7).clamp(10.0, 28.0),
        ),
      ),
    );
  }
}
