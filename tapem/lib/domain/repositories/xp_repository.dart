import '../entities/xp/xp_event.dart';

abstract interface class XpRepository {
  /// Current XP/level for user in gym across all three axes.
  Future<UserGymXp> getUserGymXp({
    required String gymId,
    required String userId,
  });

  Stream<UserGymXp> watchUserGymXp({
    required String gymId,
    required String userId,
  });

  /// Recent XP events for display.
  Future<List<XpEvent>> getRecentXpEvents({
    required String gymId,
    required String userId,
    int limit = 50,
  });
}
