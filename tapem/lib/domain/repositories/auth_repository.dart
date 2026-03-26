import '../entities/auth/membership.dart';
import '../entities/auth/user_profile.dart';

/// Auth and profile operations.
/// All implementations must uphold tenant isolation and privacy invariants.
abstract interface class AuthRepository {
  /// Stream of the current authenticated user ID. Null when signed out.
  Stream<String?> watchAuthState();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset({required String email});

  /// Returns null if no profile exists yet (new user).
  Future<UserProfile?> getCurrentProfile();

  /// Checks case-insensitive uniqueness. Returns true if available.
  Future<bool> isUsernameAvailable(String username);

  /// Suggests alternatives when username is taken.
  Future<List<String>> suggestUsernames(String preferredUsername);

  /// Creates the profile after first registration — mandatory step.
  Future<UserProfile> createProfile({
    required String username,
    String themeKey = 'default',
  });

  Future<UserProfile> updateProfile({
    String? displayName,
    String? themeKey,
    PrivacyLevel? privacyLevel,
  });

  /// Returns all memberships for the current user.
  Future<List<Membership>> getMemberships();

  /// Active membership for a specific gym, or null.
  Future<Membership?> getMembership({required String gymId});
}
