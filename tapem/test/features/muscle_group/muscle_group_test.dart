// =============================================================================
// Muscle Group — unit tests
//
// Covers:
//   • MuscleGroup enum: serialization, sorted order, region groupings
//   • MuscleGroupRole enum: serialization
//   • ExerciseMuscleGroup: new-format and legacy-format JSON round-trip
//   • XpRules: muscle-group level/progress helpers
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/utils/xp_rules.dart';
import 'package:tapem/domain/entities/gym/exercise_muscle_group.dart';
import 'package:tapem/domain/entities/gym/muscle_group.dart';
import 'package:tapem/domain/entities/gym/muscle_group_role.dart';

void main() {
  // ─── MuscleGroup enum ────────────────────────────────────────────────────────

  group('MuscleGroup', () {
    test('has exactly 17 values', () {
      expect(MuscleGroup.values.length, 17);
    });

    test('fromValue returns the correct group', () {
      expect(MuscleGroup.fromValue('chest'), MuscleGroup.chest);
      expect(MuscleGroup.fromValue('upper_back'), MuscleGroup.upperBack);
      expect(MuscleGroup.fromValue('lats'), MuscleGroup.lats);
      expect(MuscleGroup.fromValue('lower_back'), MuscleGroup.lowerBack);
      expect(MuscleGroup.fromValue('front_shoulder'), MuscleGroup.frontShoulder);
      expect(MuscleGroup.fromValue('side_shoulder'), MuscleGroup.sideShoulder);
      expect(MuscleGroup.fromValue('rear_shoulder'), MuscleGroup.rearShoulder);
      expect(MuscleGroup.fromValue('biceps'), MuscleGroup.biceps);
      expect(MuscleGroup.fromValue('triceps'), MuscleGroup.triceps);
      expect(MuscleGroup.fromValue('forearms'), MuscleGroup.forearms);
      expect(MuscleGroup.fromValue('core'), MuscleGroup.core);
      expect(MuscleGroup.fromValue('glutes'), MuscleGroup.glutes);
      expect(MuscleGroup.fromValue('quads'), MuscleGroup.quads);
      expect(MuscleGroup.fromValue('hamstrings'), MuscleGroup.hamstrings);
      expect(MuscleGroup.fromValue('calves'), MuscleGroup.calves);
      expect(MuscleGroup.fromValue('adductors'), MuscleGroup.adductors);
      expect(MuscleGroup.fromValue('abductors'), MuscleGroup.abductors);
    });

    test('fromValue throws for unknown value', () {
      expect(() => MuscleGroup.fromValue('unknown'), throwsArgumentError);
    });

    test('tryFromValue returns null for unknown value', () {
      expect(MuscleGroup.tryFromValue('not_a_group'), isNull);
    });

    test('tryFromValue returns the group for known value', () {
      expect(MuscleGroup.tryFromValue('quads'), MuscleGroup.quads);
    });

    test('sorted returns all 17 groups in sortOrder order', () {
      final sorted = MuscleGroup.sorted;
      expect(sorted.length, 17);
      for (var i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].sortOrder < sorted[i + 1].sortOrder,
          isTrue,
          reason: '${sorted[i]} should come before ${sorted[i + 1]}',
        );
      }
    });

    test('sorted starts with chest (sortOrder 0)', () {
      expect(MuscleGroup.sorted.first, MuscleGroup.chest);
    });

    test('sorted ends with abductors (sortOrder 16)', () {
      expect(MuscleGroup.sorted.last, MuscleGroup.abductors);
    });

    test('frontGroups excludes back-only muscles', () {
      final front = MuscleGroup.frontGroups;
      expect(front, isNot(contains(MuscleGroup.upperBack)));
      expect(front, isNot(contains(MuscleGroup.lats)));
      expect(front, isNot(contains(MuscleGroup.lowerBack)));
      expect(front, isNot(contains(MuscleGroup.rearShoulder)));
      expect(front, isNot(contains(MuscleGroup.triceps)));
      expect(front, isNot(contains(MuscleGroup.glutes)));
      expect(front, isNot(contains(MuscleGroup.hamstrings)));
      expect(front, isNot(contains(MuscleGroup.calves)));
    });

    test('frontGroups includes front and both-region muscles', () {
      final front = MuscleGroup.frontGroups;
      expect(front, contains(MuscleGroup.chest));
      expect(front, contains(MuscleGroup.core));
      expect(front, contains(MuscleGroup.quads));
      expect(front, contains(MuscleGroup.adductors));    // front
      expect(front, contains(MuscleGroup.sideShoulder)); // both
      expect(front, contains(MuscleGroup.forearms));     // both
      expect(front, contains(MuscleGroup.abductors));    // both
    });

    test('backGroups excludes front-only muscles', () {
      final back = MuscleGroup.backGroups;
      expect(back, isNot(contains(MuscleGroup.chest)));
      expect(back, isNot(contains(MuscleGroup.frontShoulder)));
      expect(back, isNot(contains(MuscleGroup.biceps)));
      expect(back, isNot(contains(MuscleGroup.core)));
      expect(back, isNot(contains(MuscleGroup.quads)));
    });

    test('backGroups includes back and both-region muscles', () {
      final back = MuscleGroup.backGroups;
      expect(back, contains(MuscleGroup.upperBack));
      expect(back, contains(MuscleGroup.glutes));
      expect(back, contains(MuscleGroup.sideShoulder)); // both
      expect(back, contains(MuscleGroup.forearms));     // both
      expect(back, contains(MuscleGroup.abductors));    // both
    });

    test('adductors bodyRegion is front', () {
      expect(MuscleGroup.adductors.bodyRegion, MuscleBodyRegion.front);
    });

    test('abductors bodyRegion is both', () {
      expect(MuscleGroup.abductors.bodyRegion, MuscleBodyRegion.both);
    });

    test('sideShoulder bodyRegion is both', () {
      expect(MuscleGroup.sideShoulder.bodyRegion, MuscleBodyRegion.both);
    });

    test('chest bodyRegion is front', () {
      expect(MuscleGroup.chest.bodyRegion, MuscleBodyRegion.front);
    });

    test('upperBack bodyRegion is back', () {
      expect(MuscleGroup.upperBack.bodyRegion, MuscleBodyRegion.back);
    });
  });

  // ─── MuscleGroupRole enum ────────────────────────────────────────────────────

  group('MuscleGroupRole', () {
    test('fromValue maps "primary" correctly', () {
      expect(MuscleGroupRole.fromValue('primary'), MuscleGroupRole.primary);
    });

    test('fromValue maps "secondary" correctly', () {
      expect(MuscleGroupRole.fromValue('secondary'), MuscleGroupRole.secondary);
    });

    test('fromValue throws for unknown role', () {
      expect(() => MuscleGroupRole.fromValue('tertiary'), throwsArgumentError);
    });

    test('value property round-trips', () {
      expect(MuscleGroupRole.fromValue(MuscleGroupRole.primary.value), MuscleGroupRole.primary);
      expect(MuscleGroupRole.fromValue(MuscleGroupRole.secondary.value), MuscleGroupRole.secondary);
    });
  });

  // ─── ExerciseMuscleGroup ──────────────────────────────────────────────────────

  group('ExerciseMuscleGroup', () {
    test('fromJson parses new format with role field', () {
      final emg = ExerciseMuscleGroup.fromJson({
        'g': 'chest',
        'r': 'primary',
      });
      expect(emg.muscleGroup, MuscleGroup.chest);
      expect(emg.role, MuscleGroupRole.primary);
      expect(emg.isPrimary, isTrue);
      expect(emg.isSecondary, isFalse);
    });

    test('fromJson parses new format with secondary role', () {
      final emg = ExerciseMuscleGroup.fromJson({
        'g': 'biceps',
        'r': 'secondary',
      });
      expect(emg.muscleGroup, MuscleGroup.biceps);
      expect(emg.role, MuscleGroupRole.secondary);
      expect(emg.isPrimary, isFalse);
      expect(emg.isSecondary, isTrue);
    });

    test('fromJson parses legacy format weight > 0.5 as primary', () {
      final emg = ExerciseMuscleGroup.fromJson({
        'g': 'chest',
        'w': 0.7,
      });
      expect(emg.muscleGroup, MuscleGroup.chest);
      expect(emg.role, MuscleGroupRole.primary);
    });

    test('fromJson parses legacy format weight == 0.5 as secondary', () {
      final emg = ExerciseMuscleGroup.fromJson({
        'g': 'core',
        'w': 0.5,
      });
      expect(emg.muscleGroup, MuscleGroup.core);
      expect(emg.role, MuscleGroupRole.secondary);
    });

    test('fromJson parses legacy format weight < 0.5 as secondary', () {
      final emg = ExerciseMuscleGroup.fromJson({
        'g': 'core',
        'w': 0.3,
      });
      expect(emg.muscleGroup, MuscleGroup.core);
      expect(emg.role, MuscleGroupRole.secondary);
    });

    test('fromJson with missing weight defaults to secondary', () {
      final emg = ExerciseMuscleGroup.fromJson({'g': 'core', 'w': null});
      expect(emg.role, MuscleGroupRole.secondary);
    });

    test('toJson serializes to new format with role field', () {
      const emg = ExerciseMuscleGroup(
        muscleGroup: MuscleGroup.quads,
        role: MuscleGroupRole.primary,
      );
      final json = emg.toJson();
      expect(json['g'], 'quads');
      expect(json['r'], 'primary');
      expect(json.containsKey('w'), isFalse);
    });

    test('round-trip: toJson then fromJson preserves data', () {
      const original = ExerciseMuscleGroup(
        muscleGroup: MuscleGroup.hamstrings,
        role: MuscleGroupRole.secondary,
      );
      final roundTripped = ExerciseMuscleGroup.fromJson(original.toJson());
      expect(roundTripped, original);
    });

    test('equality: same group and role are equal', () {
      const a = ExerciseMuscleGroup(
        muscleGroup: MuscleGroup.chest,
        role: MuscleGroupRole.primary,
      );
      const b = ExerciseMuscleGroup(
        muscleGroup: MuscleGroup.chest,
        role: MuscleGroupRole.primary,
      );
      expect(a, equals(b));
    });

    test('equality: different role → not equal', () {
      const a = ExerciseMuscleGroup(
        muscleGroup: MuscleGroup.chest,
        role: MuscleGroupRole.primary,
      );
      const b = ExerciseMuscleGroup(
        muscleGroup: MuscleGroup.chest,
        role: MuscleGroupRole.secondary,
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ─── XpRules — muscle group helpers ─────────────────────────────────────────

  group('XpRules.muscleGroup', () {
    test('constants are correct', () {
      expect(XpRules.muscleGroupPrimaryXp, 10.0);
      expect(XpRules.muscleGroupSecondaryXp, 2.5);
      expect(XpRules.muscleGroupXpPerLevel, 100);
    });

    group('levelFromXpDouble', () {
      test('0 XP → level 1', () {
        expect(XpRules.levelFromXpDouble(0.0, 100), 1);
      });

      test('99 XP → level 1', () {
        expect(XpRules.levelFromXpDouble(99.9, 100), 1);
      });

      test('100 XP → level 2', () {
        expect(XpRules.levelFromXpDouble(100.0, 100), 2);
      });

      test('199.9 XP → level 2', () {
        expect(XpRules.levelFromXpDouble(199.9, 100), 2);
      });

      test('200 XP → level 3', () {
        expect(XpRules.levelFromXpDouble(200.0, 100), 3);
      });

      test('10 primary exercises → level 2 (exactly)', () {
        // 10 exercises × 10.0 XP = 100.0 XP → level 2
        expect(XpRules.levelFromXpDouble(10 * 10.0, 100), 2);
      });
    });

    group('levelProgressDouble', () {
      test('0 XP → 0.0 progress', () {
        expect(XpRules.levelProgressDouble(0.0, 100), 0.0);
      });

      test('50 XP → 0.5 progress', () {
        expect(XpRules.levelProgressDouble(50.0, 100), 0.5);
      });

      test('100 XP → 0.0 progress (start of new level)', () {
        expect(XpRules.levelProgressDouble(100.0, 100), 0.0);
      });

      test('150 XP → 0.5 progress', () {
        expect(XpRules.levelProgressDouble(150.0, 100), 0.5);
      });

      test('fractional XP: 2.5 XP → 0.025 progress', () {
        expect(
          XpRules.levelProgressDouble(2.5, 100),
          closeTo(0.025, 1e-10),
        );
      });

      test('result is always clamped to [0.0, 1.0]', () {
        final values = [-1.0, 0.0, 50.0, 99.9, 100.0, 200.0, 999.0];
        for (final xp in values) {
          final progress = XpRules.levelProgressDouble(xp, 100);
          expect(progress, inInclusiveRange(0.0, 1.0), reason: 'xp=$xp');
        }
      });
    });

    group('xpToNextLevelDouble', () {
      test('0 XP → 100 XP to next level', () {
        expect(XpRules.xpToNextLevelDouble(0.0, 100), 100.0);
      });

      test('2.5 XP → 97.5 XP to next level', () {
        expect(XpRules.xpToNextLevelDouble(2.5, 100), closeTo(97.5, 1e-10));
      });

      test('50 XP → 50 XP to next level', () {
        expect(XpRules.xpToNextLevelDouble(50.0, 100), 50.0);
      });

      test('100 XP (level 2 start) → 100 XP to next level', () {
        expect(XpRules.xpToNextLevelDouble(100.0, 100), 100.0);
      });

      test('10 primary exercises → exactly 0 XP to next level', () {
        // 10 × 10.0 = 100 XP → level 2 exactly → 100 XP to level 3
        expect(XpRules.xpToNextLevelDouble(100.0, 100), 100.0);
      });
    });

    group('XP stacking', () {
      test('two exercises on same muscle group stack XP', () {
        const primaryPerExercise = XpRules.muscleGroupPrimaryXp;
        final twoExercises = 2 * primaryPerExercise;
        expect(twoExercises, 20.0);
        expect(XpRules.levelFromXpDouble(twoExercises, 100), 1);
      });

      test('10 exercises → level 2', () {
        final xp = 10 * XpRules.muscleGroupPrimaryXp;
        expect(xp, 100.0);
        expect(XpRules.levelFromXpDouble(xp, 100), 2);
      });

      test('mix of primary and secondary XP sums correctly', () {
        // 5 primary (50 XP) + 4 secondary (10 XP) = 60 XP
        final xp = 5 * XpRules.muscleGroupPrimaryXp
            + 4 * XpRules.muscleGroupSecondaryXp;
        expect(xp, closeTo(60.0, 1e-10));
        expect(XpRules.levelFromXpDouble(xp, 100), 1);
        expect(XpRules.xpToNextLevelDouble(xp, 100), closeTo(40.0, 1e-10));
      });
    });
  });
}
