/// The training role of a muscle group within an exercise.
///
/// [primary]   — the main muscle group targeted; awards [XpRules.muscleGroupPrimaryXp].
/// [secondary] — an auxiliary group loaded at lower intensity; awards [XpRules.muscleGroupSecondaryXp].
enum MuscleGroupRole {
  primary('primary'),
  secondary('secondary');

  const MuscleGroupRole(this.value);

  /// Database/JSON representation.
  final String value;

  static MuscleGroupRole fromValue(String v) =>
      MuscleGroupRole.values.firstWhere(
        (e) => e.value == v,
        orElse: () => throw ArgumentError('Unknown MuscleGroupRole: "$v"'),
      );
}
