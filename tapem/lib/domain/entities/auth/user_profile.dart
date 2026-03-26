import 'package:equatable/equatable.dart';

/// Privacy level for friend activity visibility.
/// Matches `privacy_level` enum in Postgres.
enum PrivacyLevel {
  private('private'),
  friendsTrainingDays('friends_training_days'),
  friendsTrainingAndSummary('friends_training_and_summary');

  const PrivacyLevel(this.value);
  final String value;

  static PrivacyLevel fromValue(String v) => PrivacyLevel.values.firstWhere(
    (e) => e.value == v,
    orElse: () => PrivacyLevel.friendsTrainingDays,
  );
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.username,
    required this.themeKey,
    required this.privacyLevel,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id; // matches auth.users.id
  final String username; // unique, case-insensitive
  final String themeKey; // 'default' | 'energy' | 'minimal'
  final PrivacyLevel privacyLevel;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id];
}
