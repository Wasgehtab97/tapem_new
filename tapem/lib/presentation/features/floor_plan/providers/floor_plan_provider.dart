import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/workout/providers/equipment_provider.dart';

// ─── Data class ──────────────────────────────────────────────────────────────

/// Floor plan metadata for a gym.
@immutable
class GymFloorPlan {
  const GymFloorPlan({
    required this.gymId,
    required this.imageUrl,
    required this.aspectRatio,
  });

  final String gymId;

  /// Public Supabase Storage URL for the floor plan image.
  final String imageUrl;

  /// Image width ÷ height — stored at upload time so the canvas can be
  /// laid out without decoding the image at runtime.
  final double aspectRatio;
}

// ─── Provider ────────────────────────────────────────────────────────────────

/// Fetches the floor plan for [gymId] from `tenant_gyms`.
/// Returns null if no floor plan has been uploaded yet.
final gymFloorPlanProvider =
    FutureProvider.family<GymFloorPlan?, String>((ref, gymId) async {
      final client = ref.watch(supabaseClientProvider);

      final row = await client
          .from('tenant_gyms')
          .select('floor_plan_image_url, floor_plan_aspect_ratio')
          .eq('id', gymId)
          .maybeSingle();

      if (row == null) return null;

      final url = row['floor_plan_image_url'] as String?;
      if (url == null || url.isEmpty) return null;

      final ratio =
          (row['floor_plan_aspect_ratio'] as num?)?.toDouble() ?? 16 / 9;

      return GymFloorPlan(
        gymId: gymId,
        imageUrl: url,
        aspectRatio: ratio,
      );
    });

// ─── Service ─────────────────────────────────────────────────────────────────

/// Mutations for the floor plan feature.
/// All methods are fire-and-forget safe: they update both Supabase and the
/// local Drift cache, then invalidate the relevant providers.
class FloorPlanService {
  FloorPlanService(this._ref);

  final Ref _ref;

  // ── Image upload ───────────────────────────────────────────────────────────

  /// Picks an image via [ImagePicker], uploads it to the `floor-plans` Storage
  /// bucket, and saves the URL + aspect ratio to `tenant_gyms`.
  ///
  /// Returns the resulting [GymFloorPlan], or null if the user cancelled.
  /// Throws on network / storage errors so the caller can surface a snackbar.
  Future<GymFloorPlan?> uploadFloorPlan(String gymId) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return null; // user cancelled

    final bytes = await file.readAsBytes();

    // Decode image to determine its natural aspect ratio.
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final naturalWidth = frame.image.width;
    final naturalHeight = frame.image.height;
    frame.image.dispose();

    final aspectRatio = naturalWidth / naturalHeight;

    // Upload to Storage.
    final client = _ref.read(supabaseClientProvider);
    final storagePath =
        '$gymId/${DateTime.now().millisecondsSinceEpoch}_floor_plan.jpg';

    await client.storage
        .from('floor-plans')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    // Cache-bust so CachedNetworkImage picks up the new file.
    final publicUrl = client.storage.from('floor-plans').getPublicUrl(
      storagePath,
    );
    final bustedUrl =
        '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    // Persist metadata on the gym row.
    await client
        .from('tenant_gyms')
        .update({
          'floor_plan_image_url': bustedUrl,
          'floor_plan_aspect_ratio': aspectRatio,
        })
        .eq('id', gymId);

    _ref.invalidate(gymFloorPlanProvider(gymId));

    return GymFloorPlan(
      gymId: gymId,
      imageUrl: bustedUrl,
      aspectRatio: aspectRatio,
    );
  }

  // ── Position management ────────────────────────────────────────────────────

  /// Saves [posX] / [posY] for [equipmentId] to both Supabase and the local
  /// Drift cache, then refreshes [gymEquipmentProvider].
  Future<void> saveEquipmentPosition(
    String gymId,
    String equipmentId,
    double posX,
    double posY,
  ) async {
    final client = _ref.read(supabaseClientProvider);
    final db = _ref.read(appDatabaseProvider);

    // Optimistic local update first — the UI already shows the new position.
    await db.updateEquipmentPosition(equipmentId, posX, posY);

    try {
      await client
          .from('gym_equipment')
          .update({'pos_x': posX, 'pos_y': posY})
          .eq('id', equipmentId)
          .eq('gym_id', gymId);
    } catch (e, st) {
      AppLogger.e('[floor_plan] saveEquipmentPosition failed', e, st);
      // Roll back local optimistic update on failure.
      await db.clearEquipmentPosition(equipmentId);
      _ref.invalidate(gymEquipmentProvider(gymId));
      rethrow;
    }

    _ref.invalidate(gymEquipmentProvider(gymId));
  }

  /// Removes the floor-plan position for [equipmentId].
  Future<void> clearEquipmentPosition(String gymId, String equipmentId) async {
    final client = _ref.read(supabaseClientProvider);
    final db = _ref.read(appDatabaseProvider);

    await db.clearEquipmentPosition(equipmentId);

    try {
      await client
          .from('gym_equipment')
          .update({'pos_x': null, 'pos_y': null})
          .eq('id', equipmentId)
          .eq('gym_id', gymId);
    } catch (e, st) {
      AppLogger.e('[floor_plan] clearEquipmentPosition failed', e, st);
      rethrow;
    } finally {
      _ref.invalidate(gymEquipmentProvider(gymId));
    }
  }
}

final floorPlanServiceProvider = Provider<FloorPlanService>(
  (ref) => FloorPlanService(ref),
);
