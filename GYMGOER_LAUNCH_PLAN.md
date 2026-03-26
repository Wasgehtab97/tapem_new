# Gymgoer Launch Plan

> Scope: Everything needed to make Tap'em fully launch-ready for gym members.
> Gymowner work is tracked separately.
> Status: 2026-03-20
> Priority: Items within each section are ordered highest→lowest priority.

---

## 1. Leaderboards — Separated by Axis, Privacy-Aware, High-Quality Design

### Current state (what's actually in the code)
- ONE leaderboard exists: `gymRankingsProvider` queries `user_gym_xp` (= training_day XP only).
- No separate Equipment Experience leaderboard.
- No Muscle Group leaderboard.
- No privacy filter — every user in the gym appears regardless of their `privacy_level`.
- Design: plain flat list with rank number, username, level, XP. No podium for top 3. No sticky "your position" footer. No axis context labels.
- The `_RankingsTab` widget has zero tabs/segments — it's a single unsegmented list.

### What needs to be built

#### 1a — Training Day Leaderboard (rename + fix existing)
- Rename / relabel the existing rankings to clearly say "TRAINING DAYS" / "Consistency".
- Add privacy filter: only include users where `privacy_level != 'private'`.
  - This requires joining `user_gym_xp` with `user_profiles` and filtering by `privacy_level`.
  - Do this server-side (Supabase view or RPC) — never client-side filtering of a full table.
- Add "your position" sticky row at the bottom if the current user is outside the visible top-N.
- Design upgrade:
  - Top-3 podium block (gold/silver/bronze) above the list.
  - Remaining ranks as compact tiles.
  - Current user tile always highlighted with neonCyan accent border.
  - Show training day count next to XP (e.g. "Level 7 · 142 days · 14,200 XP").

#### 1b — Equipment Experience Leaderboard (new)
- Source: `user_exercise_xp` table — sum `total_xp` per `user_id` + `gym_id` across all exercise keys.
- Best approach: create a Supabase DB view `gym_equipment_xp_ranking` that pre-aggregates and joins with `user_profiles` + `privacy_level`.
- Show: rank, username, total equipment XP, equipment level (derive from sum, or store a `current_level` aggregate per user+gym for the equipment axis — requires a new `user_gym_equipment_xp` summary table or compute on-the-fly via the view).
- Design: same podium + list pattern as training day, but use neonMagenta accent.
- Label: "EQUIPMENT MASTERY" / "Experience".

#### 1c — Muscle Group Leaderboard (BLOCKED — do after muscle group weights are populated)
- Source: `user_muscle_group_xp` — sum per user+gym across all muscle groups.
- BLOCKED because `muscle_group_weights` table is empty for existing equipment — muscle group XP cannot be awarded until weights are defined.
- What to do now: Add the tab as a "Coming Soon" placeholder with a clear message that it unlocks once muscle group data is curated.
- When muscle group weights are added by gym owners (via admin screen), this leaderboard becomes live automatically.
- Design accent: neonYellow.

#### 1d — Leaderboard UI structure
Replace the single `_RankingsTab` with a segmented control or horizontal swipeable tabs:

```
[ CONSISTENCY ] [ EQUIPMENT ] [ MUSCLE GROUP ]
```

Each tab has its own provider, its own podium widget, and its own accent color.
All three respect privacy filter identically.

#### 1e — DB: Privacy-aware ranking view (migration needed)
Create a Postgres view or RPC function for each leaderboard axis that:
1. Joins the XP table with `user_profiles` on `user_id`.
2. Filters `privacy_level != 'private'`.
3. Returns: `rank() OVER (ORDER BY total_xp DESC)`, `username`, `total_xp`, `current_level`, `user_id`.
4. Is gym-scoped via a parameter (use an RPC function, not a bare view, to pass `gym_id`).

Why RPC not view: RLS on views is tricky in Supabase; an RPC with `SECURITY DEFINER` + explicit gym_id input is safer and testable.

---

## 2. Privacy Enforcement — Currently Incomplete

### Current state
- `privacy_level` field exists on `user_profiles` (enum: `private`, `friends_training_days`, `friends_training_and_summary`).
- Privacy selector UI exists in `ProfileScreen` and persists to Supabase via `profileNotifierProvider`.
- `FriendUser.lastTrainingDay` is **hardcoded `null`** in `community_provider.dart` line 104 — it is never actually fetched.
- User search (`userSearchProvider`) queries ALL `user_profiles` globally — no gym scope. A user can find and add friends from other gyms.
- Leaderboard shows all gym members regardless of privacy setting.
- The `friends_training_and_summary` level never shows session summary anywhere.

### What needs to be built

#### 2a — `lastTrainingDay` on friend tiles (fix the null)
- When loading the friends list, for each accepted friend:
  - If their `privacy_level` is `friends_training_days` or `friends_training_and_summary`: fetch their latest `session_day_anchor` from `workout_sessions` where `gym_id = activeGymId` and `status = 'finished'`.
  - If `private`: show nothing (null is correct).
- Best approach: one supplemental query after loading friendships, batching all friend user_ids. A Supabase RPC `get_friend_training_days(friend_ids uuid[], gym_id uuid)` that checks privacy_level server-side and returns only permitted data.
- Render in `_FriendTile`: "Last trained: 2 days ago" or "Today" using relative date formatting.

#### 2b — User search scoped to same gym
- `userSearchProvider` must join against `gym_memberships` where `gym_id = activeGymId`.
- Change the query from `user_profiles` directly to:
  ```sql
  user_profiles WHERE id IN (
    SELECT user_id FROM gym_memberships WHERE gym_id = :gymId AND status = 'active'
  ) AND username ILIKE :query AND id != :currentUserId
  ```
- This also prevents cross-gym friend discovery, which violates the gym-internal community model in the spec.

#### 2c — Leaderboard privacy filter (see section 1e above)
- Covered in 1e — the ranking RPC filters out `privacy_level = 'private'` users.

#### 2d — `friends_training_and_summary` — session summary visibility
- When a friend has `privacy_level = 'friends_training_and_summary'`, their friend tile should show a summary of their last session (exercise count, total sets) on tap — not inline.
- Implement as a tappable friend tile that opens a bottom sheet with the session summary.
- Server-side: RPC that returns session summary only if `privacy_level = 'friends_training_and_summary'` for the requested user.
- The summary must NOT include set-level detail (weight, reps) — only exercise names and counts.

---

## 3. Progress Screen — Visual Upgrades

### Current state
- Training calendar heatmap: implemented, looks good.
- XP Overview card: shows `training_day` axis only (level, progress bar, total XP, XP to next level).
- "Top Equipment" section: text list of top 5 exercise keys with level + XP — no progress bars per item, no visual hierarchy.
- "Muscle Groups" section: same plain text list pattern as equipment — no visual representation.
- No XP progress bar for the `exercise_equipment` axis or `muscle_group` axis in the overview.
- Recent sessions: list of sessions, tappable for detail — OK.

### What needs to be built

#### 3a — XP Axis Overview: all three axes, not just training_day
Replace the single XP overview card with a card that shows all three axes:

```
[ CONSISTENCY LVL 7 ]  ████████████░░  14,200 XP  → 800 to LVL 8
[ EQUIPMENT   LVL 4 ]  ████░░░░░░░░░░   3,840 XP  → 1,160 to LVL 5
[ MUSCLE GRP  LVL 2 ]  ██░░░░░░░░░░░░   1,200 XP  → 800 to LVL 3
```

Each axis has:
- Axis name + accent color (cyan / magenta / yellow).
- Current level badge.
- Progress bar to next level.
- Total XP and XP remaining.

The `exercise_equipment` axis total = sum of `user_exercise_xp.total_xp` for the user in this gym.
The `muscle_group` axis total = sum of `user_muscle_group_xp.total_xp` for the user in this gym.
Both need a provider (they may already exist in `xp_provider.dart` — verify and wire up).

#### 3b — Muscle Group visualization (replace text list)
Replace the plain `_XpRow` list for muscle groups with a horizontal bar chart:

```
CHEST       ██████████████░░░░░░  LVL 4  4,200 XP
BACK        ████████████░░░░░░░░  LVL 3  3,100 XP
SHOULDERS   ████████░░░░░░░░░░░░  LVL 3  2,800 XP
LEGS        █████░░░░░░░░░░░░░░░  LVL 2  1,500 XP
ARMS        ███░░░░░░░░░░░░░░░░░  LVL 1    900 XP
```

- Bars proportional to the highest muscle group XP.
- Each bar uses the neonYellow accent with alpha fill.
- Sorted descending by total_xp.
- Tapping a muscle group row shows a detail card: top 3 exercises contributing to that muscle group XP.

Note: Muscle group XP data (`user_muscle_group_xp`) is only populated if `muscle_group_weights` are defined for the user's exercises. Until gym owners add weights, this section shows an empty state with a message: "Muscle group tracking activates once your gym's equipment is configured."

#### 3c — Equipment XP: progress bars per item
Replace the plain text rows in "Top Equipment" with progress bar rows:
- Show progress bar from current level to next level per exercise key.
- Top 5 items, "Show all" button that expands or navigates to a detail screen.
- Exercise key label: resolve to human-readable name (equipment name for `fixed_machine`, exercise name for `open_station`) — requires joining `gym_equipment` or `exercise_templates` by exercise_key.

---

## 4. Equipment Manufacturer — Smart Foundation for Future Cross-Gym Leaderboards

### Current state
- `gym_equipment` table has `manufacturer TEXT` and `model TEXT` — both free text, nullable.
- `GymEquipment` entity in Flutter has `manufacturer` and `model` fields.
- Existing seeded equipment (migrations 00008–00014) has manufacturer data populated as free text.
- Problem: "Life Fitness Leg Press" at Gym A and "Life Fitness Leg Press" at Gym B are two separate rows with no connection. Future cross-gym leaderboard by equipment is impossible without normalization.

### What needs to be built

#### 4a — DB: `global_equipment_catalog` table (new migration)
```sql
CREATE TABLE public.global_equipment_catalog (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  manufacturer      TEXT NOT NULL,
  model_name        TEXT NOT NULL,
  model_number      TEXT,        -- optional OEM model number
  equipment_type    equipment_type NOT NULL,
  canonical_exercise_key TEXT,   -- for fixed_machine entries
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (manufacturer, model_name)
);
```

Key design decisions:
- `(manufacturer, model_name)` unique constraint — the normalization key.
- `model_number` is optional but useful for future barcode/NFC equipment identification.
- `canonical_exercise_key` mirrors the field on `gym_equipment` — for fixed machines that have one canonical exercise globally.
- This table is managed by the platform operator (service role), not by gym owners. Gym owners can request additions via the admin feedback flow.

#### 4b — DB: Add `catalog_id` FK to `gym_equipment`
```sql
ALTER TABLE public.gym_equipment
  ADD COLUMN catalog_id UUID REFERENCES public.global_equipment_catalog(id) ON DELETE SET NULL;
```

- Nullable — not all equipment will be in the catalog immediately.
- When `catalog_id` is set, `manufacturer` and `model` on `gym_equipment` are redundant but kept for local display override (e.g. a gym calls a Life Fitness machine by a custom name).
- Index: `CREATE INDEX idx_gym_equipment_catalog_id ON gym_equipment(catalog_id) WHERE catalog_id IS NOT NULL;`

#### 4c — Seed `global_equipment_catalog` with existing equipment data
Create a migration that:
1. Inserts distinct `(manufacturer, model_name)` combinations from existing `gym_equipment` rows where manufacturer is not null.
2. Updates `gym_equipment.catalog_id` to reference the new catalog rows.
3. Covers migrations 00008–00014 (Lifthouse, FitSevenEleven, Club Aktiv, KSV Eisenschmiede).

#### 4d — Flutter: no changes needed for launch
The `GymEquipment` entity already has `manufacturer` and `model` fields. Just add `catalogId` as a nullable field to the entity and map it from the DB. No UI changes needed — this is purely infrastructure.

#### Why this matters for the future
When you have 50 gyms, a user at any gym can see "I'm rank 12 globally on the Life Fitness Leg Press among all Tap'em users." The `catalog_id` FK on `gym_equipment` is the join key that makes that query trivial. Without it, you'd need retroactive fuzzy name matching across thousands of rows — expensive and error-prone.

---

## 5. Username Validation — Spec Mismatch

### Current state (code)
- Allowed chars: `[a-zA-Z0-9_]` — uppercase allowed, no dot.
- Max length: 24 chars.
- No rename rate limit enforcement.
- No reserved words list.

### Spec (Decision 11 in `15_OPEN_QUESTIONS_AND_DECISIONS.md`)
- Allowed chars: `[a-z0-9_.]` — lowercase only, dot allowed.
- Length: 3–20 chars.
- Rename: max 1x per 30 days.
- Reserved words blocked: `admin`, `support`, `tapem`, `system` (and others).

### What needs to be built

#### 5a — Fix Flutter validator in `username_setup_screen.dart`
- Regex: `^[a-z0-9_.]{3,20}$`
- Error messages: "Only lowercase letters, numbers, _ and . allowed" / "3–20 characters".
- If user types uppercase: auto-lowercase the input (transform on `onChanged`).

#### 5b — Fix DB-level constraint
```sql
ALTER TABLE public.user_profiles
  DROP CONSTRAINT IF EXISTS username_format;
ALTER TABLE public.user_profiles
  ADD CONSTRAINT username_format CHECK (username ~ '^[a-z0-9_.]{3,20}$');
```

#### 5c — Reserved words check (DB function)
```sql
CREATE OR REPLACE FUNCTION public.is_reserved_username(uname TEXT) RETURNS BOOLEAN AS $$
BEGIN
  RETURN LOWER(uname) = ANY(ARRAY['admin','support','tapem','system','tapem_admin','api','root','null']);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

ALTER TABLE public.user_profiles
  ADD CONSTRAINT username_not_reserved CHECK (NOT is_reserved_username(username));
```

#### 5d — Rename rate limit
Add `username_changed_at TIMESTAMPTZ` to `user_profiles`. In the username change RPC/function, check:
```sql
IF existing.username_changed_at > NOW() - INTERVAL '30 days' THEN
  RAISE EXCEPTION 'username_cooldown';
END IF;
```
Flutter: show "You can change your username again on [date]" if cooldown error returned.

Note: Existing users created with the old rules (uppercase, longer names) are grandfathered — do not force migration, only enforce on new registrations and future changes.

---

## 6. Friends Activity — `lastTrainingDay` Currently Always Null

### Current state
- `FriendUser.lastTrainingDay` is hardcoded `null` in the provider.
- The `_FriendTile` already has the rendering logic (`l10n.lastTrained(friend.lastTrainingDay!)`).
- This means the friends list shows usernames with no activity indication at all.

### What needs to be built

#### 6a — Supabase RPC: `get_friends_last_training(p_viewer_id, p_gym_id, p_friend_ids)`
```sql
-- Returns: friend_user_id, last_training_day (DATE or null)
-- Only returns last_training_day if the friend's privacy_level allows it.
-- privacy_level 'private' → null
-- privacy_level 'friends_training_days' or 'friends_training_and_summary' → date
```
Call once after loading the friends list, batch all friend IDs in one RPC call.

#### 6b — Wire into `friendsProvider`
After fetching the friendship rows, call the RPC with all accepted friend IDs, then merge the returned training days into the `FriendUser` list.

#### 6c — Relative date display
"Today", "Yesterday", "3 days ago", "Last week", "2 weeks ago" — no absolute date shown.
German / English localized via existing l10n system.

---

## 7. Community Screen — Minor UX Gaps

### 7a — Friend search must not show users already in a pending state
Currently, the search filters out `accepted` friends but not `pending_sent` or `pending_received` ones. A user can send duplicate requests.
- Fix: include pending friendships in the `friendIds` set used to filter search results. Already partially done — verify the filter covers `status = 'pending'` in both directions.

### 7b — Friend removal
Currently no way to remove an accepted friend. Users expect this.
- Add a long-press or swipe action on `_FriendTile` that triggers a confirmation dialog → calls `DELETE FROM friendships WHERE id = :id`.
- Also add it as a menu option inside a future friend profile sheet.

### 7c — Empty state on Rankings when privacy hides everyone
If the current user is the only non-private user in their gym, the leaderboard shows just one entry or nothing. Add a graceful empty state: "Be the first on the board — invite gym members to Tap'em."

---

## 8. Progress Screen — Minor UX Gaps

### 8a — Session detail: show equipment names, not exercise keys
Currently `SessionSummary` and the session detail sheet likely show raw exercise keys (`canonical:bench_press`) instead of human-readable names. Resolve exercise keys to equipment/exercise names before display.

### 8b — Heatmap: show training streak
Below the heatmap, show current streak (consecutive training days) and longest streak. These are derivable from the `trainingDays` set already loaded.

### 8c — Pull-to-refresh on Progress screen
Currently there is no `RefreshIndicator` on the progress ListView. Add one that invalidates `userGymXpProvider`, `trainingDaysProvider`, `userExerciseXpProvider`, `userMuscleGroupXpProvider`.

---

## 9. App Store Readiness (required for TestFlight / Play Internal Track)

### 9a — App icons: all required sizes
iOS currently has only `Icon-App-1024x1024@1x.png` plus a few small sizes. Generate the full icon set from the 1024px master:
- iOS: all sizes per `Contents.json` spec (20@1x/2x/3x, 29@1x/2x/3x, 40@1x/2x/3x, 60@2x/3x, 76@1x/2x, 83.5@2x, 1024@1x).
- Android: mipmap-hdpi/mdpi/xhdpi/xxhdpi/xxxhdpi foreground + background layers (adaptive icon).

### 9b — Launch/splash screen
Replace the default Flutter splash with the Tap'em cyberpunk splash:
- Dark background (`surface900`).
- Tap'em wordmark in neonCyan.
- Optionally: a brief scan-pulse animation (< 1s).
- iOS: `LaunchScreen.storyboard`.
- Android: `launch_background.xml` with the same design.

### 9c — App metadata
- iOS `Info.plist`: NFC usage description ("Tap'em scans NFC tags to identify gym equipment"), camera (if any), location (if any).
- Android `AndroidManifest.xml`: NFC permission declared.
- Both platforms: correct bundle ID, version number, copyright string.

---

## 10. Performance — Must Validate Before Launch

### 10a — Set-log p95 < 150ms locally
The spec requires `AC-LAUNCH-01`: set entry to visible confirmation p95 < 150ms.
- Measure: stopwatch around the Drift insert in `workoutProvider` → widget rebuild.
- Drift writes are synchronous-ish in isolates — should be fast, but must be verified with a profiling run on a real device (not simulator).
- If slow: ensure the Drift database is opened with `NativeDatabase.createInBackground`.

### 10b — App cold start < 700ms (spec) / warm start
- Profile with Flutter DevTools timeline on a mid-range Android device (e.g. Pixel 4a equivalent).
- The main risk: Supabase client init + GoRouter + Riverpod container all in `main()`. If slow, defer non-critical init after first frame.

### 10c — Leaderboard query performance
- The new privacy-aware ranking RPCs must have proper indexes:
  - `user_gym_xp(gym_id, total_xp DESC)` — already needed for ranking.
  - `user_profiles(id, privacy_level)` — for the join filter.
  - `user_exercise_xp(gym_id, user_id)` — for equipment XP aggregation.
- Test with 500+ simulated users in Supabase (load seed script).

---

## 11. Correctness Fixes — Must Not Ship Broken

### 11a — `gymRankingsProvider` XP axis label is wrong
The existing leaderboard queries `user_gym_xp` and labels it as a general "GYM XP LEADERBOARD" — but `user_gym_xp.total_xp` is specifically the `training_day` axis. The label must be corrected when the axis split is implemented (section 1).

### 11b — User search can return the current user
`userSearchProvider` calls `.neq('id', user.id)` — this is correct. But verify this also excludes already-sent requests (see 7a).

### 11c — Rank calculation assumes no ties
Current rank: `rank++` in a simple loop. With ties (two users at same XP), both should receive the same rank number. Use `RANK() OVER (ORDER BY total_xp DESC)` in the DB RPC instead of client-side incrementing.

### 11d — `acceptRequest` / `declineRequest` have no gym scope check
Currently any user can accept/decline any friendship by ID if they guess the UUID. The `friendships` table RLS policy must ensure only `addressee_id = auth.uid()` can update the status. Verify this policy exists in `00002_rls_policies.sql` or add it.

---

## Implementation Sequence (recommended)

```
Sprint 1 — Correctness & Privacy Foundation
  1. Fix user search to be gym-scoped (2b)
  2. Implement lastTrainingDay via RPC (6a, 6b)
  3. Fix leaderboard privacy filter via DB view/RPC (1e)
  4. Verify + fix friendships RLS (11d)
  5. Fix username validation (5a, 5b)

Sprint 2 — Leaderboard Redesign
  1. Build training day leaderboard with podium + privacy filter (1a)
  2. Build equipment experience leaderboard (1b)
  3. Add muscle group placeholder tab (1c)
  4. Segmented leaderboard tab control (1d)

Sprint 3 — Progress Screen Upgrades
  1. All-three-axis XP overview card (3a)
  2. Equipment XP progress bars (3c)
  3. Muscle group bar chart (3b)
  4. Training streak display (8b)
  5. Pull-to-refresh (8c)
  6. Session detail: resolve exercise keys to names (8a)

Sprint 4 — Equipment Manufacturer Foundation
  1. global_equipment_catalog migration (4a)
  2. catalog_id FK on gym_equipment (4b)
  3. Seed catalog from existing data (4c)
  4. Add catalogId to Flutter GymEquipment entity (4d)

Sprint 5 — Community Polish
  1. Friend removal (7b)
  2. Duplicate request prevention (7a)
  3. Empty leaderboard graceful state (7c)
  4. friends_training_and_summary session summary sheet (2d)

Sprint 6 — App Store Readiness & Perf
  1. App icons all sizes (9a)
  2. Splash screen (9b)
  3. Info.plist / Manifest metadata (9c)
  4. Perf profiling set-log + cold start (10a, 10b)
  5. Leaderboard query indexes + load test (10c)
```

---

## Open Questions

1. **Muscle group weights for existing equipment** — who populates `muscle_group_weights`? This must be done by the platform operator (or gym owner via admin screen) before the muscle group axis produces any data. The muscle group leaderboard and muscle group progress visualization are both blocked on this.

2. **Cross-gym friend requests** — should a user be able to add a friend from another gym? The spec says "gym-internal friends" for V1. The current code allows cross-gym. This document recommends gym-scoped search (section 2b), but a product decision is needed: after the user joins a second gym, do cross-gym friendships appear in both gym contexts?

3. **Equipment XP axis level formula** — `user_gym_xp` has `current_level` materialized. `user_exercise_xp` has `current_level` per exercise key. The Equipment Leaderboard in section 1b needs a *total* equipment XP level for ranking. Options:
   a. Sum all `user_exercise_xp.total_xp` per user+gym → derive a single level from that sum using the same XP formula.
   b. Show "Top equipment level" (max `current_level` across all of the user's exercise keys).
   Option A is more meaningful. Decide before implementing.
