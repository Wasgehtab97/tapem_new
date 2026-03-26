import 'package:equatable/equatable.dart';

/// Member role within a gym.
enum MemberRole {
  member('member'),
  coach('coach'),
  admin('admin'),
  owner('owner');

  const MemberRole(this.value);
  final String value;

  static MemberRole fromValue(String v) => MemberRole.values.firstWhere(
    (e) => e.value == v,
    orElse: () => MemberRole.member,
  );

  bool get canManageGym => this == MemberRole.admin || this == MemberRole.owner;
  bool get canCoach => this == MemberRole.coach || canManageGym;
}

class Membership extends Equatable {
  const Membership({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.role,
    required this.isActive,
    required this.joinedAt,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final String gymId;
  final MemberRole role;
  final bool isActive;
  final DateTime joinedAt;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isValid => isActive && !isExpired;

  @override
  List<Object?> get props => [id];
}
