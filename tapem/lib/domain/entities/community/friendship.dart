import 'package:equatable/equatable.dart';

enum FriendshipStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  blocked('blocked');

  const FriendshipStatus(this.value);
  final String value;

  static FriendshipStatus fromValue(String v) =>
      FriendshipStatus.values.firstWhere((e) => e.value == v);
}

/// Gym-internal friendship. Both users must have active membership in the same gym.
class Friendship extends Equatable {
  const Friendship({
    required this.id,
    required this.gymId,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String gymId;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  bool get isAccepted => status == FriendshipStatus.accepted;

  @override
  List<Object?> get props => [id];
}
