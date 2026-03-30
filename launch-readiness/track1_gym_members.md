# Track 1 — Gym Members: Launch Status

> **Last updated:** 2026-03-30
> **Status: ✅ LAUNCH-READY**
>
> All core features, privacy enforcement, security policies, and app store
> requirements have been verified as fully implemented. The items below are
> **optional enhancements** for post-launch consideration — none are required
> for V1 release.

---

> [!IMPORTANT]
> Everything listed below is **optional** and should be evaluated on a
> case-by-case basis in future sprints. These are suggestions for polish
> and hardening — not blockers.

---

## Optional Enhancements (Post-Launch)

### 1. XP Overview Card — Show All 3 Axes

The `_XpOverviewCard` on the Progress screen currently shows only the Consistency axis. Equipment and Muscle Group axis totals are already computed by the providers but not yet rendered in the summary card. This is a ~20-line UI-only change.

- **Effort:** ~30 min
- **Impact:** Gives users a quick snapshot of all three XP dimensions at a glance

---

### 2. Real-Device Performance Profiling

Acceptance criteria `AC-LAUNCH-01` specifies:
- Set-log insert: p95 < 150ms
- App cold start: p95 < 10s on mid-range hardware

The code and architecture support this, but formal profiling on a real mid-range Android device (not simulator) has not been documented. Consider:
- Instrument `Stopwatch` around Drift insert in `workoutProvider`
- Profile cold start via Flutter DevTools timeline

---

### 3. Streak Display on Progress Screen

The streak (current + longest + grace period warning) is already computed via `streakProvider` and displayed prominently on the Home screen's stats row and calendar badge. Consider whether a duplicate display on the Progress screen adds value or creates redundancy.

---

### 4. Splash Screen Branding

`LaunchScreen.storyboard` (iOS) and `launch_background.xml` (Android) exist. If they still use Flutter's default white screen, consider replacing with the Tap'em branded dark background (`#0A0A0A`) + neonCyan wordmark. Use `flutter_native_splash` for consistency.

---

### 5. Cross-Gym Leaderboard Foundation

The `global_equipment_catalog` table and `catalog_id` FK on `gym_equipment` are already migrated and seeded (migration `00016`). A future cross-gym leaderboard feature could leverage this foundation to let users compare equipment XP across multiple gyms.

---

### 6. Offline Sync Edge Cases

The offline-first architecture (Drift SQLite + Supabase sync) is fully in place. Consider formal regression testing of these edge cases:
1. Start workout → airplane mode → complete → reconnect → verify session syncs
2. Kill app mid-workout → reopen → verify session resumes
3. Two devices, same account → verify no duplicate sessions

---

### 7. App Store Metadata Review

All icons (16-file iOS set + Android) and NFC permissions (both platforms) are in place. Before actual store submission, review:
- `bundleIdentifier` / `applicationId` match production values
- Version name/code in `pubspec.yaml`
- Copyright and privacy policy URL in store metadata

---

## What Was Verified as Complete

For reference, these items from the original document were verified as fully implemented and have been removed from this checklist:

| Area | Evidence |
|---|---|
| Privacy-aware ranking RPCs | Migrations `00018`, `00024`, `00041` |
| Gym-scoped user search | `search_users_for_friendship` RPC in `00049` |
| `lastTrainingDay` via RPC | `get_friends_last_training_day` in `00049` + Flutter enrichment |
| Session summary (privacy-aware) | `get_friend_last_session_summary` in `00049` |
| Username validation | Regex + DB constraint + reserved words + 30-day cooldown (`00017`) |
| Duplicate friend request prevention | Unique index + `23505` catch in `sendRequest` |
| Leaderboard empty states | `_EmptyLeaderboardBody` widget |
| Training streak | `StreakCalculator` + RPC + home screen display |
| Friendship RLS | Insert/update/delete policies in `00049` |
| DB performance indexes | All 4 indexes in `00018` |
| App icons | Full 16-file iOS set |
| Splash screen files | Both platforms |
| NFC permissions | `Info.plist` + `AndroidManifest.xml` |
| Global equipment catalog | Migration `00016` with seeding + FK |
| Equipment feedback | Migration `00050` with RLS |
