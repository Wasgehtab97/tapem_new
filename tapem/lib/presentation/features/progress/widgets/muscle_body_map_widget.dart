import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/gym/muscle_group.dart';

// ─── Public widget ────────────────────────────────────────────────────────────

/// Front + back anatomical body map with per-muscle-group colour coding.
///
/// Colour scale (per muscle group):
///   0 XP       → dark inactive (#1A1A26)
///   1–99 XP    → amber gradient growing with intensity
///   100+ XP    → full neon yellow (#FFEA00), stays capped
///
/// [xpMap] maps every [MuscleGroup] to its total XP (0.0 for untrained).
class MuscleBodyMapWidget extends StatelessWidget {
  const MuscleBodyMapWidget({super.key, required this.xpMap});

  final Map<MuscleGroup, double> xpMap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _BodyView(
            label: 'VORNE',
            svgString: _buildFrontSvg(xpMap),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BodyView(
            label: 'HINTEN',
            svgString: _buildBackSvg(xpMap),
          ),
        ),
      ],
    );
  }
}

// ─── Internal view ────────────────────────────────────────────────────────────

class _BodyView extends StatelessWidget {
  const _BodyView({required this.label, required this.svgString});

  final String label;
  final String svgString;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            fontSize: 9,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 100 / 240,
          child: SvgPicture.string(
            svgString,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

// ─── Colour helper ────────────────────────────────────────────────────────────

/// Returns a hex colour string (#RRGGBB) for the given XP value.
///
/// 0 XP   → surface700 (#1A1A26)
/// 0→100  → linear blend dark-amber → neon-yellow
/// 100+   → neon yellow (#FFEA00), capped
String _xpColor(double xp, {double cap = 100.0}) {
  if (xp <= 0) return '#1A1A26';
  final t = (xp / cap).clamp(0.0, 1.0);
  // Start: #2E2350 (deep purple-tinted), end: #FFEA00 (neon yellow)
  // Midpoint hint at ~0.4: #F9A825 (amber)
  final r = _lerp(0x2E, 0xFF, t).round();
  final g = _lerp(0x23, 0xEA, t).round();
  final b = _lerp(0x50, 0x00, t).round();
  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

double _lerp(num a, num b, double t) => a + (b - a) * t;

// ─── SVG builders ─────────────────────────────────────────────────────────────
//
// ViewBox: 0 0 100 240  (portrait, ~1:2.4 ratio)
// All paths are anatomically shaped but stylised — clean enough for a small
// widget without requiring external asset files.

String _buildFrontSvg(Map<MuscleGroup, double> xp) {
  final chest = _xpColor(xp[MuscleGroup.chest] ?? 0);
  final frontShoulder = _xpColor(xp[MuscleGroup.frontShoulder] ?? 0);
  final sideShoulder = _xpColor(xp[MuscleGroup.sideShoulder] ?? 0);
  final biceps = _xpColor(xp[MuscleGroup.biceps] ?? 0);
  final forearms = _xpColor(xp[MuscleGroup.forearms] ?? 0);
  final core = _xpColor(xp[MuscleGroup.core] ?? 0);
  final quads = _xpColor(xp[MuscleGroup.quads] ?? 0);
  final calves = _xpColor(xp[MuscleGroup.calves] ?? 0);
  final adductors = _xpColor(xp[MuscleGroup.adductors] ?? 0);
  final abductors = _xpColor(xp[MuscleGroup.abductors] ?? 0);

  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 240">
  <defs>
    <!-- Shared body silhouette gradient for 3-D depth -->
    <radialGradient id="bodyGrad" cx="50%" cy="40%" r="55%">
      <stop offset="0%" stop-color="#2A2A42"/>
      <stop offset="100%" stop-color="#12121A"/>
    </radialGradient>
    <!-- Per-muscle highlight gradients -->
    <radialGradient id="gc" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$chest" stop-opacity="1"/>
      <stop offset="100%" stop-color="$chest" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gfs" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$frontShoulder" stop-opacity="1"/>
      <stop offset="100%" stop-color="$frontShoulder" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gss" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$sideShoulder" stop-opacity="1"/>
      <stop offset="100%" stop-color="$sideShoulder" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gbi" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$biceps" stop-opacity="1"/>
      <stop offset="100%" stop-color="$biceps" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gfo" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$forearms" stop-opacity="1"/>
      <stop offset="100%" stop-color="$forearms" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gco" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$core" stop-opacity="1"/>
      <stop offset="100%" stop-color="$core" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gq" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$quads" stop-opacity="1"/>
      <stop offset="100%" stop-color="$quads" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gcv" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$calves" stop-opacity="1"/>
      <stop offset="100%" stop-color="$calves" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gad" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$adductors" stop-opacity="1"/>
      <stop offset="100%" stop-color="$adductors" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gabd" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$abductors" stop-opacity="1"/>
      <stop offset="100%" stop-color="$abductors" stop-opacity="0.4"/>
    </radialGradient>
  </defs>

  <!-- ── Base silhouette ── -->
  <!-- Head -->
  <ellipse cx="50" cy="11" rx="10" ry="11" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.5"/>
  <!-- Neck -->
  <rect x="44.5" y="21" width="11" height="7" rx="2" fill="#1E1E30"/>
  <!-- Trapezius / collar -->
  <path d="M30 28 Q50 24 70 28 L68 34 Q50 31 32 34Z" fill="#242438"/>

  <!-- Torso -->
  <path d="M30 28 L70 28 L66 82 L60 86 L40 86 L34 82Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Left upper arm (user's left = visual right) -->
  <path d="M70 28 L76 30 L78 58 L70 60 L68 34Z" rx="4" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>
  <!-- Right upper arm -->
  <path d="M30 28 L24 30 L22 58 L30 60 L32 34Z" rx="4" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Left forearm -->
  <path d="M70 60 L78 58 L80 82 L72 84 L70 60Z" rx="3" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>
  <!-- Right forearm -->
  <path d="M30 60 L22 58 L20 82 L28 84 L30 60Z" rx="3" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Left hand -->
  <ellipse cx="76" cy="87" rx="5" ry="4" fill="#1A1A28"/>
  <!-- Right hand -->
  <ellipse cx="24" cy="87" rx="5" ry="4" fill="#1A1A28"/>

  <!-- Pelvis -->
  <path d="M34 82 L66 82 L64 96 L36 96Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Left thigh -->
  <path d="M36 96 L50 96 L50 148 L38 148 L34 130Z" rx="5" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>
  <!-- Right thigh -->
  <path d="M64 96 L50 96 L50 148 L62 148 L66 130Z" rx="5" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Knee left -->
  <ellipse cx="44" cy="150" rx="6" ry="5" fill="#1E1E30" stroke="#2E2E50" stroke-width="0.4"/>
  <!-- Knee right -->
  <ellipse cx="56" cy="150" rx="6" ry="5" fill="#1E1E30" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Left calf -->
  <path d="M38 154 L50 153 L50 200 L40 202 L36 180Z" rx="4" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>
  <!-- Right calf -->
  <path d="M62 154 L50 153 L50 200 L60 202 L64 180Z" rx="4" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Feet -->
  <ellipse cx="44" cy="204" rx="6" ry="3.5" fill="#1A1A28"/>
  <ellipse cx="56" cy="204" rx="6" ry="3.5" fill="#1A1A28"/>

  <!-- ── Muscle overlays (front) ── -->

  <!-- Chest (pectorals) — two lobes -->
  <path d="M34 34 Q42 32 50 35 Q44 48 36 50 Q30 46 32 38Z" fill="url(#gc)" opacity="0.85"/>
  <path d="M66 34 Q58 32 50 35 Q56 48 64 50 Q70 46 68 38Z" fill="url(#gc)" opacity="0.85"/>

  <!-- Front shoulder (anterior deltoid) -->
  <ellipse cx="30.5" cy="31" rx="5" ry="6" fill="url(#gfs)" opacity="0.85"/>
  <ellipse cx="69.5" cy="31" rx="5" ry="6" fill="url(#gfs)" opacity="0.85"/>

  <!-- Side shoulder (lateral deltoid) -->
  <ellipse cx="23.5" cy="35" rx="4" ry="6" fill="url(#gss)" opacity="0.85"/>
  <ellipse cx="76.5" cy="35" rx="4" ry="6" fill="url(#gss)" opacity="0.85"/>

  <!-- Biceps -->
  <path d="M23 42 Q28 40 31 42 L31 57 Q26 59 22 57Z" fill="url(#gbi)" opacity="0.85"/>
  <path d="M77 42 Q72 40 69 42 L69 57 Q74 59 78 57Z" fill="url(#gbi)" opacity="0.85"/>

  <!-- Forearms -->
  <path d="M21 60 Q26 58 29 61 L29 80 Q24 83 20 80Z" fill="url(#gfo)" opacity="0.85"/>
  <path d="M79 60 Q74 58 71 61 L71 80 Q76 83 80 80Z" fill="url(#gfo)" opacity="0.85"/>

  <!-- Core (rectus abdominis + obliques) -->
  <path d="M36 52 L64 52 L62 82 L38 82Z" fill="url(#gco)" opacity="0.75"/>
  <!-- Abs line detail -->
  <line x1="50" y1="52" x2="50" y2="82" stroke="#12121A" stroke-width="0.6" opacity="0.5"/>
  <line x1="37" y1="61" x2="63" y2="61" stroke="#12121A" stroke-width="0.5" opacity="0.4"/>
  <line x1="37" y1="70" x2="63" y2="70" stroke="#12121A" stroke-width="0.5" opacity="0.4"/>

  <!-- Quads -->
  <path d="M36 98 L50 97 L49 146 L37 146 L34 128Z" fill="url(#gq)" opacity="0.85"/>
  <path d="M64 98 L50 97 L51 146 L63 146 L66 128Z" fill="url(#gq)" opacity="0.85"/>
  <!-- Quad separation line -->
  <line x1="42" y1="100" x2="40" y2="144" stroke="#12121A" stroke-width="0.5" opacity="0.4"/>
  <line x1="58" y1="100" x2="60" y2="144" stroke="#12121A" stroke-width="0.5" opacity="0.4"/>

  <!-- Calves (gastrocnemius front visible) -->
  <path d="M38 156 L50 155 L49 196 L39 198 L36 178Z" fill="url(#gcv)" opacity="0.85"/>
  <path d="M62 156 L50 155 L51 196 L61 198 L64 178Z" fill="url(#gcv)" opacity="0.85"/>

  <!-- Adductors (inner thigh) -->
  <path d="M44 100 L50 98 L50 144 L44 143 L42 126Z" fill="url(#gad)" opacity="0.80"/>
  <path d="M56 100 L50 98 L50 144 L56 143 L58 126Z" fill="url(#gad)" opacity="0.80"/>

  <!-- Abductors (outer hip, upper thigh) -->
  <path d="M32 94 L38 93 L37 112 L31 110Z" fill="url(#gabd)" opacity="0.80"/>
  <path d="M68 94 L62 93 L63 112 L69 110Z" fill="url(#gabd)" opacity="0.80"/>
</svg>''';
}

String _buildBackSvg(Map<MuscleGroup, double> xp) {
  final upperBack = _xpColor(xp[MuscleGroup.upperBack] ?? 0);
  final lats = _xpColor(xp[MuscleGroup.lats] ?? 0);
  final lowerBack = _xpColor(xp[MuscleGroup.lowerBack] ?? 0);
  final rearShoulder = _xpColor(xp[MuscleGroup.rearShoulder] ?? 0);
  final sideShoulder = _xpColor(xp[MuscleGroup.sideShoulder] ?? 0);
  final triceps = _xpColor(xp[MuscleGroup.triceps] ?? 0);
  final forearms = _xpColor(xp[MuscleGroup.forearms] ?? 0);
  final glutes = _xpColor(xp[MuscleGroup.glutes] ?? 0);
  final hamstrings = _xpColor(xp[MuscleGroup.hamstrings] ?? 0);
  final calves = _xpColor(xp[MuscleGroup.calves] ?? 0);
  final abductors = _xpColor(xp[MuscleGroup.abductors] ?? 0);

  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 240">
  <defs>
    <radialGradient id="bodyGrad" cx="50%" cy="40%" r="55%">
      <stop offset="0%" stop-color="#2A2A42"/>
      <stop offset="100%" stop-color="#12121A"/>
    </radialGradient>
    <radialGradient id="gub" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$upperBack" stop-opacity="1"/>
      <stop offset="100%" stop-color="$upperBack" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gla" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$lats" stop-opacity="1"/>
      <stop offset="100%" stop-color="$lats" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="glb" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$lowerBack" stop-opacity="1"/>
      <stop offset="100%" stop-color="$lowerBack" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="grs" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$rearShoulder" stop-opacity="1"/>
      <stop offset="100%" stop-color="$rearShoulder" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gss" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$sideShoulder" stop-opacity="1"/>
      <stop offset="100%" stop-color="$sideShoulder" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gtr" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$triceps" stop-opacity="1"/>
      <stop offset="100%" stop-color="$triceps" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gfo" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$forearms" stop-opacity="1"/>
      <stop offset="100%" stop-color="$forearms" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="ggl" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$glutes" stop-opacity="1"/>
      <stop offset="100%" stop-color="$glutes" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gha" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$hamstrings" stop-opacity="1"/>
      <stop offset="100%" stop-color="$hamstrings" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gcv" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$calves" stop-opacity="1"/>
      <stop offset="100%" stop-color="$calves" stop-opacity="0.4"/>
    </radialGradient>
    <radialGradient id="gabd" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="$abductors" stop-opacity="1"/>
      <stop offset="100%" stop-color="$abductors" stop-opacity="0.4"/>
    </radialGradient>
  </defs>

  <!-- ── Base silhouette (back view) ── -->
  <!-- Head (back) -->
  <ellipse cx="50" cy="11" rx="10" ry="11" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.5"/>
  <!-- Neck -->
  <rect x="44.5" y="21" width="11" height="7" rx="2" fill="#1E1E30"/>

  <!-- Torso -->
  <path d="M30 28 L70 28 L66 82 L60 86 L40 86 L34 82Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Left upper arm -->
  <path d="M70 28 L76 30 L78 58 L70 60 L68 34Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>
  <!-- Right upper arm -->
  <path d="M30 28 L24 30 L22 58 L30 60 L32 34Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Left forearm -->
  <path d="M70 60 L78 58 L80 82 L72 84 L70 60Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>
  <!-- Right forearm -->
  <path d="M30 60 L22 58 L20 82 L28 84 L30 60Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Hands -->
  <ellipse cx="76" cy="87" rx="5" ry="4" fill="#1A1A28"/>
  <ellipse cx="24" cy="87" rx="5" ry="4" fill="#1A1A28"/>

  <!-- Pelvis -->
  <path d="M34 82 L66 82 L64 96 L36 96Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Left thigh -->
  <path d="M36 96 L50 96 L50 148 L38 148 L34 130Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>
  <!-- Right thigh -->
  <path d="M64 96 L50 96 L50 148 L62 148 L66 130Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Knees -->
  <ellipse cx="44" cy="150" rx="6" ry="5" fill="#1E1E30" stroke="#2E2E50" stroke-width="0.4"/>
  <ellipse cx="56" cy="150" rx="6" ry="5" fill="#1E1E30" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Left calf -->
  <path d="M38 154 L50 153 L50 200 L40 202 L36 180Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>
  <!-- Right calf -->
  <path d="M62 154 L50 153 L50 200 L60 202 L64 180Z" fill="url(#bodyGrad)" stroke="#2E2E50" stroke-width="0.4"/>

  <!-- Feet -->
  <ellipse cx="44" cy="204" rx="6" ry="3.5" fill="#1A1A28"/>
  <ellipse cx="56" cy="204" rx="6" ry="3.5" fill="#1A1A28"/>

  <!-- ── Muscle overlays (back) ── -->

  <!-- Upper back (trapezius / rhomboids) -->
  <path d="M33 30 Q50 27 67 30 L64 50 Q50 47 36 50Z" fill="url(#gub)" opacity="0.85"/>

  <!-- Lats (latissimus dorsi) -->
  <path d="M36 48 L50 52 L50 76 L38 78 L32 62Z" fill="url(#gla)" opacity="0.85"/>
  <path d="M64 48 L50 52 L50 76 L62 78 L68 62Z" fill="url(#gla)" opacity="0.85"/>

  <!-- Lower back (erector spinae) -->
  <path d="M39 72 L61 72 L60 84 L40 84Z" fill="url(#glb)" opacity="0.85"/>
  <!-- Spine highlight -->
  <line x1="50" y1="30" x2="50" y2="84" stroke="#0A0A0F" stroke-width="1" opacity="0.5"/>

  <!-- Rear shoulder (posterior deltoid) -->
  <ellipse cx="29.5" cy="31.5" rx="5.5" ry="6" fill="url(#grs)" opacity="0.85"/>
  <ellipse cx="70.5" cy="31.5" rx="5.5" ry="6" fill="url(#grs)" opacity="0.85"/>

  <!-- Side shoulder (lateral deltoid — visible both sides) -->
  <ellipse cx="23.5" cy="35" rx="4" ry="6" fill="url(#gss)" opacity="0.85"/>
  <ellipse cx="76.5" cy="35" rx="4" ry="6" fill="url(#gss)" opacity="0.85"/>

  <!-- Triceps -->
  <path d="M23 42 Q28 40 31 43 L30 58 Q25 60 22 57Z" fill="url(#gtr)" opacity="0.85"/>
  <path d="M77 42 Q72 40 69 43 L70 58 Q75 60 78 57Z" fill="url(#gtr)" opacity="0.85"/>

  <!-- Forearms (back) -->
  <path d="M21 60 Q26 58 29 61 L28 80 Q23 83 20 80Z" fill="url(#gfo)" opacity="0.85"/>
  <path d="M79 60 Q74 58 71 61 L72 80 Q77 83 80 80Z" fill="url(#gfo)" opacity="0.85"/>

  <!-- Glutes -->
  <path d="M36 86 Q50 90 64 86 L63 100 Q50 104 37 100Z" fill="url(#ggl)" opacity="0.85"/>
  <!-- Glute separation -->
  <line x1="50" y1="87" x2="50" y2="100" stroke="#0A0A0F" stroke-width="0.8" opacity="0.5"/>

  <!-- Hamstrings -->
  <path d="M37 100 L50 101 L50 148 L38 147 L35 128Z" fill="url(#gha)" opacity="0.85"/>
  <path d="M63 100 L50 101 L50 148 L62 147 L65 128Z" fill="url(#gha)" opacity="0.85"/>

  <!-- Calves (gastrocnemius back) -->
  <path d="M38 156 L50 155 L49 196 L39 198 L36 178Z" fill="url(#gcv)" opacity="0.85"/>
  <path d="M62 156 L50 155 L51 196 L61 198 L64 178Z" fill="url(#gcv)" opacity="0.85"/>
  <!-- Calf separation line -->
  <line x1="44" y1="158" x2="43" y2="194" stroke="#0A0A0F" stroke-width="0.5" opacity="0.4"/>
  <line x1="56" y1="158" x2="57" y2="194" stroke="#0A0A0F" stroke-width="0.5" opacity="0.4"/>

  <!-- Abductors (outer hip, back view) -->
  <path d="M32 94 L38 93 L37 112 L31 110Z" fill="url(#gabd)" opacity="0.80"/>
  <path d="M68 94 L62 93 L63 112 L69 110Z" fill="url(#gabd)" opacity="0.80"/>
</svg>''';
}
