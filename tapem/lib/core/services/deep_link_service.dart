import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/gym/gym_equipment.dart';

// ─── Deep link stream ─────────────────────────────────────────────────────────

final _appLinksProvider = Provider<AppLinks>((ref) => AppLinks());

/// Emits every incoming `tapem://e/<id>` URI (from URL scheme or NDEF dispatch).
final deepLinkStreamProvider = StreamProvider<Uri>((ref) async* {
  final appLinks = ref.watch(_appLinksProvider);

  // Emit the initial link (app was launched from a deep link while closed).
  final initial = await appLinks.getInitialLink();
  if (initial != null && _isTapemEquipmentLink(initial)) yield initial;

  // Emit subsequent links (app in background, receives new link).
  yield* appLinks.uriLinkStream.where(_isTapemEquipmentLink);
});

// ─── Pending equipment from NFC / deep link ───────────────────────────────────

/// Holds the [GymEquipment] that arrived via NFC or deep link and has not yet
/// been processed by the active screen. Consume immediately by setting to null.
final pendingNfcEquipmentProvider = StateProvider<GymEquipment?>((ref) => null);

// ─── Helpers ──────────────────────────────────────────────────────────────────

bool _isTapemEquipmentLink(Uri uri) =>
    uri.scheme == 'tapem' && uri.host == 'e' && uri.pathSegments.isNotEmpty;

/// Extracts the equipment ID from a valid `tapem://e/<id>` URI.
String? equipmentIdFromLink(Uri uri) {
  if (!_isTapemEquipmentLink(uri)) return null;
  final id = uri.pathSegments.first.trim();
  return id.isNotEmpty ? id : null;
}
