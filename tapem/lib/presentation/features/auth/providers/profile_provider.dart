import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../domain/entities/auth/user_profile.dart';
import 'auth_provider.dart';

// ─── Current profile ──────────────────────────────────────────────────────────

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('user_profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (data == null) return null;
  return _mapProfile(data);
});

UserProfile _mapProfile(Map<String, dynamic> d) => UserProfile(
  id: d['id'] as String,
  username: d['username'] as String,
  themeKey: (d['theme_key'] as String?) ?? 'default',
  privacyLevel: PrivacyLevel.fromValue(
    (d['privacy_level'] as String?) ?? 'friends_training_days',
  ),
  displayName: d['display_name'] as String?,
  avatarUrl: d['avatar_url'] as String?,
  createdAt: DateTime.parse(d['created_at'] as String),
  updatedAt: DateTime.parse(d['updated_at'] as String),
);

// ─── Profile actions notifier ─────────────────────────────────────────────────

class ProfileNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> isUsernameAvailable(String username) async {
    final client = ref.read(supabaseClientProvider);
    final result = await client
        .from('user_profiles')
        .select('id')
        .ilike('username', username)
        .maybeSingle();
    return result == null;
  }

  Future<List<String>> suggestUsernames(String preferred) async {
    // Strip characters not allowed by the username spec (keep a-z, 0-9, _, .)
    final base = preferred.replaceAll(RegExp(r'[^a-z0-9_.]'), '').toLowerCase();
    final suggestions = <String>[];
    final client = ref.read(supabaseClientProvider);

    for (var i = 1; suggestions.length < 3; i++) {
      final candidate = '$base$i';
      final taken = await client
          .from('user_profiles')
          .select('id')
          .ilike('username', candidate)
          .maybeSingle();
      if (taken == null) suggestions.add(candidate);
      if (i > 20) break;
    }
    return suggestions;
  }

  Future<void> createProfile({
    required String userId,
    required String username,
    String themeKey = 'default',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.from('user_profiles').insert({
        'id': userId,
        'username': username,
        'theme_key': themeKey,
        'privacy_level': 'friends_training_days',
      });
      ref.invalidate(currentProfileProvider);
      // Trigger TOKEN_REFRESHED on auth stream so the router re-checks
      // hasProfile and redirects to gym setup automatically.
      await client.auth.refreshSession();
    });
  }

  /// Uploads [bytes] as the user's avatar and persists the public URL.
  /// Throws on failure so the caller can surface the error.
  Future<void> uploadAvatar(Uint8List bytes) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Not authenticated');

    final client = ref.read(supabaseClientProvider);
    final storagePath = '${user.id}/avatar.jpg';

    await client.storage
        .from('avatars')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    // Cache-bust so CachedNetworkImage fetches the new image.
    final publicUrl = client.storage.from('avatars').getPublicUrl(storagePath);
    final bustedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await client
        .from('user_profiles')
        .update({
          'avatar_url': bustedUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);

    ref.invalidate(currentProfileProvider);
  }

  Future<void> updateTheme(String themeKey) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('user_profiles')
          .update({
            'theme_key': themeKey,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
      ref.invalidate(currentProfileProvider);
    });
  }

  Future<void> updatePrivacyLevel(PrivacyLevel level) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('user_profiles')
          .update({
            'privacy_level': level.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
      ref.invalidate(currentProfileProvider);
    });
  }
}

final profileNotifierProvider = AsyncNotifierProvider<ProfileNotifier, void>(
  ProfileNotifier.new,
);
