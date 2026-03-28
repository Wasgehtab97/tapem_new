/// The authoritative set of 15 muscle groups tracked throughout the app.
///
/// Values are stored as lowercase_snake_case strings in all databases and edge
/// functions. Every surface in the app must use this enum — raw strings are
/// only permitted at serialization boundaries.
enum MuscleGroup {
  chest('chest', 'Brust', 'Chest', MuscleBodyRegion.front, 0),
  upperBack('upper_back', 'Oberer Rücken', 'Upper Back', MuscleBodyRegion.back, 1),
  lats('lats', 'Latissimus', 'Lats', MuscleBodyRegion.back, 2),
  lowerBack('lower_back', 'Unterer Rücken', 'Lower Back', MuscleBodyRegion.back, 3),
  frontShoulder('front_shoulder', 'Vordere Schulter', 'Front Shoulder', MuscleBodyRegion.front, 4),
  sideShoulder('side_shoulder', 'Seitliche Schulter', 'Side Shoulder', MuscleBodyRegion.both, 5),
  rearShoulder('rear_shoulder', 'Hintere Schulter', 'Rear Shoulder', MuscleBodyRegion.back, 6),
  biceps('biceps', 'Bizeps', 'Biceps', MuscleBodyRegion.front, 7),
  triceps('triceps', 'Trizeps', 'Triceps', MuscleBodyRegion.back, 8),
  forearms('forearms', 'Unterarme', 'Forearms', MuscleBodyRegion.both, 9),
  core('core', 'Core', 'Core', MuscleBodyRegion.front, 10),
  glutes('glutes', 'Gesäß', 'Glutes', MuscleBodyRegion.back, 11),
  quads('quads', 'Quadrizeps', 'Quads', MuscleBodyRegion.front, 12),
  hamstrings('hamstrings', 'Hamstrings', 'Hamstrings', MuscleBodyRegion.back, 13),
  calves('calves', 'Waden', 'Calves', MuscleBodyRegion.back, 14),
  adductors('adductors', 'Adduktoren', 'Adductors', MuscleBodyRegion.front, 15),
  abductors('abductors', 'Abduktoren', 'Abductors', MuscleBodyRegion.both, 16);

  const MuscleGroup(
    this.value,
    this.displayNameDe,
    this.displayNameEn,
    this.bodyRegion,
    this.sortOrder,
  );

  /// Database/JSON representation — always lowercase_snake_case.
  final String value;

  /// German display name shown in the UI.
  final String displayNameDe;

  /// English display name shown in the UI.
  final String displayNameEn;

  /// Which body view renders this group (front, back, or both).
  final MuscleBodyRegion bodyRegion;

  /// Canonical top-to-bottom, front-before-back ordering for sorted lists.
  final int sortOrder;

  // ─── Serialization ──────────────────────────────────────────────────────────

  /// Returns the [MuscleGroup] for [v], or null if the value is unrecognised.
  /// Use at trust boundaries (DB reads) where unknown values should be skipped
  /// rather than thrown.
  static MuscleGroup? tryFromValue(String v) =>
      MuscleGroup.values.where((e) => e.value == v).firstOrNull;

  /// Returns the [MuscleGroup] for [v].
  /// Throws [ArgumentError] for unrecognised values — use only in trusted paths.
  static MuscleGroup fromValue(String v) =>
      tryFromValue(v) ??
      (throw ArgumentError('Unknown MuscleGroup value: "$v"'));

  // ─── Convenience ────────────────────────────────────────────────────────────

  /// All groups sorted by [sortOrder].
  static List<MuscleGroup> get sorted =>
      MuscleGroup.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Groups visible on the front body view.
  static List<MuscleGroup> get frontGroups =>
      sorted.where((g) => g.bodyRegion != MuscleBodyRegion.back).toList();

  /// Groups visible on the back body view.
  static List<MuscleGroup> get backGroups =>
      sorted.where((g) => g.bodyRegion != MuscleBodyRegion.front).toList();
}

/// Indicates on which body-view side a [MuscleGroup] is primarily rendered.
enum MuscleBodyRegion {
  front,
  back,

  /// Shown on both front and back views (e.g. side shoulders, forearms).
  both,
}
