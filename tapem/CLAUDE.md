# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Tap'em** is an NFC-first, offline-capable gym workout tracking platform. Users scan NFC tags on gym equipment to log workouts. Architecture: Flutter (mobile) + Supabase (Postgres + Edge Functions + Auth) + Drift (local SQLite).

## Commands

### Development
```bash
make ios-emu          # Run on iOS Simulator (boots sim, passes .env.json)
make ios-iphone       # Build release + install on physical device via devicectl
make apk              # Build Android release APK
make testflight       # Bump build number, build IPA, upload to TestFlight
make deploy-functions # Deploy all 3 Supabase Edge Functions
```

All Flutter commands require `--dart-define-from-file=.env.json`. The Makefile handles this automatically.

### Code Generation
```bash
dart run build_runner build           # Generate Drift DB code (.g.dart), Freezed, JSON serializable
dart run build_runner build --delete-conflicting-outputs  # Force clean regeneration
```

Must run after any changes to Drift table definitions, Freezed entities, or JSON serializable models.

### Testing
```bash
flutter test                              # All tests
flutter test test/features/nutrition/    # Feature-specific tests
flutter test test/unit/                  # Unit tests
```

### Analysis
```bash
flutter analyze   # Run linter (must pass with 0 errors before committing)
dart fix --apply  # Auto-fix lint issues
```

### Rules:
Never update any code, without first asking me 3 clarifying questions about what it is that we are updating.

## Architecture

### Layer Structure (`lib/`)
```
core/        → Infrastructure: sync service, NFC, DB provider, theme, config
data/        → Repositories, Drift datasource, nutrition API clients
domain/      → Entities (Freezed), repository interfaces, domain services
presentation/ → UI: GoRouter, feature screens/providers/widgets
```

### State Management
**Riverpod** throughout. Conventions:
- `StateNotifier` for mutable UI state (e.g., `SyncNotifier`, `NutritionNotifier`)
- `StreamProvider` for real-time Supabase subscriptions
- `Provider` / `FutureProvider` for derived/async reads
- Screens use `ConsumerWidget` or `HookConsumerWidget` (flutter_hooks + hooks_riverpod)

### Navigation (GoRouter)
`lib/presentation/router/app_router.dart` — stateful shell routing with 6 bottom-nav branches:
1. Home, 2. Gym, 3. Active Workout (hidden when inactive), 4. Progress, 5. Nutrition, 6. Admin (admin/owner only)

**Redirect chain**: unauthenticated → `/auth/login` → missing username → `/auth/username-setup` → no gym → `/auth/gym-setup` → home.

**Admin route guard**: `/admin` and `/admin/nfc` have a `redirect:` callback that checks `isGymAdminProvider`. Non-admins are sent to `/`. `_AuthStateNotifier` subscribes to `isGymAdminProvider` so the router re-evaluates when membership resolves.

**Critical**: active workout sessions are NOT redirected away even on token expiry. The session persists in SQLite and syncs after re-auth.

### Offline-First Sync (`core/services/sync_service.dart`)
The sync service uploads local SQLite sessions to Supabase via Edge Functions.

Sync triggers: finish-session call, heartbeat (≥30s debounce on set log), 30s periodic timer, network reconnect, re-auth. Only invalidates Riverpod providers when `syncedCount > 0` (idle ticks skip invalidation).

**Edge Functions** (in `supabase/functions/`):
- `sync-workout` — upserts session/exercises/sets, processes XP inline if finished
- `finish-session` — marks session finished, runs XP for already-synced sessions
- `process-xp-event` — calculates XP, updates aggregates

**Shared XP module**: `supabase/functions/_shared/xp.ts` is the single source of truth for XP constants and calculation logic. All three functions import from it. Never duplicate XP constants locally in a function.

Deploy with `--no-verify-jwt` (Kong JWT check is incompatible with the Dart client). The `verify_jwt = false` flag is already set in `supabase/config.toml`.

**Security invariants** enforced in `sync-workout`:
- Memberships are never auto-created — 403 if no active membership exists for the requested gym
- `session_day_anchor` is derived server-side from `started_at` (Europe/Berlin); client value ignored
- Set metrics are validated: reps ≤ 500, weight_kg ≤ 500, duration_seconds ≤ 86400, distance_meters ≤ 200000
- `exercise_key` must match `^[a-z0-9_:.-]{1,120}$`; `display_name` is silently truncated to 120 chars

**Security invariants** enforced in `finish-session`:
- `finished_at` is stamped server-side with `new Date().toISOString()`; client value ignored

### Local Database (Drift)
Schema: `lib/data/datasources/local/app_database.dart`. Generated: `app_database.g.dart`.

**Generated type name rules**:
- Most tables: strip trailing 's' → singular (e.g., `LocalWorkoutSessions` → `LocalWorkoutSession`)
- Exception: `LocalGymEquipment` → `LocalGymEquipmentData`
- Companions: `<TableName>Companion` (e.g., `LocalWorkoutSessionsCompanion`)

### XP Rules (must stay in sync across all surfaces)
- Training day: 25 XP/day (idempotent via idempotency_key)
- Exercise/equipment: 5 XP/set + floor(reps/5), capped 120 XP per exercise per session
- Level threshold: 100 XP = 1 level

**If changing XP amounts**, update ALL of: `lib/core/utils/xp_rules.dart`, `lib/core/config/app_config.dart`, `supabase/functions/_shared/xp.ts` (functions derive from this), and add a correction migration.

### Active Workout / Set Persistence

Strength sets are **written to SQLite immediately when checked** (not batched at FINISH). `WorkoutDraftsNotifier` exposes `checkSet(exerciseId, index, setId)` and `uncheckSet(exerciseId, index)` — there is no `toggleChecked()`. `SetDraft.persistedSetId` is the link between the UI draft and the SQLite row; unchecking calls `deleteSet()` using this id. On cold-start, `persistedSetId` is restored from `state.sets` so uncheck-after-resume works correctly.

`_finishWorkout()` only deletes exercises with zero persisted sets, then calls `finishSession()` — no batch-logging at finish time.

### Muscle Group Model

`ExerciseMuscleGroup` uses binary primary/secondary classification (not fractional weights). XP: primary → `XpRules.muscleGroupPrimaryXp` (10.0), secondary → `XpRules.muscleGroupSecondaryXp` (2.5). Serialized as `{"g":"chest","r":"primary"}`. `fromJson()` also accepts legacy weight format `{"g":"chest","w":0.7}` (infers role from w > 0.5) for graceful cache migration.

`MuscleGroupPicker` widget: primary is required single-select; secondary is optional multi-select (max 3, primary excluded from options).

### Nutrition Module
Separate data layer in `lib/data/nutrition/`. **Does not use Drift** — Supabase + Riverpod only (less latency-critical than workout sets). Uses atomic JSONB RPCs (`nutrition_upsert_year_day`, `nutrition_upsert_weight_day`). Product lookup: cache → Supabase → Open Food Facts API.

### Multi-Tenancy
One user, potentially multiple gym memberships. `activeGymIdProvider` drives all gym-scoped queries. Supabase RLS enforces isolation server-side. New tables need explicit `GRANT ALL ON <table> TO service_role` (see migration `00036` pattern) — `BYPASSRLS` alone is not enough for PostgREST.

## Key Gotchas

- **Import `Value` from Drift**: `import 'package:drift/drift.dart' show Value;`
- **`hooks_riverpod` doesn't re-export hooks**: also import `package:flutter_hooks/flutter_hooks.dart`
- **`AppTextStyles.h2` etc. are `final` not `const`**: cannot use in `const Text(style: ...)`
- **Supabase stream builder (v2.8.x)**: only supports one `.eq()` filter — chain additional filters in `.map()` client-side
- **Supabase filter syntax v2**: use `.inFilter()` not `.in_()`
- **`PopScope` replaces `WillPopScope`**: use `PopScope(canPop: false, onPopInvokedWithResult: ...)`
- **Logger**: use `AppLogger.w()` / `AppLogger.e()` (not `.warning()` / `.error()`)
- **`syncNotifierProvider` must be eagerly initialized**: it is watched in `TapemApp.build()` to ensure the background sync timer starts at launch

## Supabase Migrations

Numbered sequentially: `supabase/migrations/000XX_description.sql`. Always add `GRANT ALL ON <new_table> TO service_role;` for tables that Edge Functions write to.
