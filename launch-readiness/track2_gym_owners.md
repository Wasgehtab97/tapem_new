# Track 2 — Gym Owners: Launch Readiness Checklist

> Scope: Everything required to bring the gym-owner / admin experience from current state (navigation shell with stubs) to enterprise-grade launch quality.
> Status: 2026-03-30
> Priority: Items within each section are ordered highest → lowest priority.
> Companion: `track1_gym_members.md` covers the member side.

---

## Legend

| Symbol | Meaning |
|--------|---------|
| 🔴 | Hard launch blocker — without this the gym cannot operate at all |
| 🟡 | High value — ships in V1 but non-fatal if slightly delayed |
| 🔵 | Quality / analytics — target for V1.1 or first patch |

---

## Current State Summary

The `AdminScreen` is a fully-structured navigation menu with 9 sections. The **only** implemented sub-screen is `admin_nfc_screen.dart` (NFC tag assignment). Every other menu item shows a `SnackBar("noch nicht implementiert")` on tap. The admin area is effectively non-functional except for NFC.

Working today:
- ✅ NFC tag assignment to equipment
- ✅ Deals creation/management (separate flow via Supabase, Firestore rules fixed)
- ✅ Role-based tab visibility (admin tab hidden for regular members)
- ✅ Admin screen localization

---

## 1. Gym Settings & Onboarding — CRITICAL PATH (🔴 BLOCKER)

> Without this, a gym owner cannot invite a single member. This is the absolute first screen to build.

### Route: `/admin/gym-settings`

### What Must Be Built

#### 1a — Gym Code Display & Share
- Fetch the gym's unique `gym_code` from Supabase `gyms` table.
- Display as a large, readable code (e.g. `LIFTHOUSE-7X4K`) with a copy-to-clipboard button.
- **Share button**: triggers native share sheet with pre-composed text:
  > "Join [Gym Name] on Tap'em! Download the app and use code: LIFTHOUSE-7X4K to connect to our gym."
- QR code variant: generate a QR code from the invite deep-link (`tapem://join?code=LIFTHOUSE-7X4K`) — display inline, tappable to open full-screen, shareable as image.

#### 1b — Gym Profile Edit
- Edit fields: `gym_name` (text), `description` (multi-line, optional), `logo_url` (image picker + Supabase Storage upload).
- Save via RPC with admin role check:
  ```sql
  CREATE OR REPLACE FUNCTION public.update_gym_profile(
    p_gym_id     UUID,
    p_name       TEXT,
    p_description TEXT
  ) RETURNS VOID SECURITY DEFINER LANGUAGE plpgsql AS $$
  BEGIN
    -- Verify caller is admin of this gym
    IF NOT EXISTS (
      SELECT 1 FROM gym_memberships
      WHERE gym_id = p_gym_id AND user_id = auth.uid()
        AND role IN ('owner','admin')
    ) THEN RAISE EXCEPTION 'not_admin'; END IF;
    UPDATE gyms SET name = p_name, description = p_description
    WHERE id = p_gym_id;
  END;
  $$;
  ```
- Inline form validation — gym name 3–60 chars, required.

#### 1c — Join Request Flow (if gym uses approval)
- Toggle: "Require approval for new members" (stored on `gyms.requires_approval`).
- If enabled: new members who enter the gym code land in a `pending` state in `gym_memberships`.
- Admin sees a badge on the Members menu item when pending requests exist.

---

## 2. Equipment Manager (🔴 BLOCKER)

> Core onboarding step. Without equipment, there is nothing to track and no NFC to assign.

### Route: `/admin/equipment`

### What Must Be Built

#### 2a — Equipment List Screen
- Fetch all `gym_equipment` rows for `activeGymId` from Supabase.
- Display as a segmented list by type: `FIXED MACHINES` · `OPEN STATIONS` · `CARDIO`.
- Each row: equipment name, device type icon, NFC badge (green if tag assigned, grey if not), active/inactive indicator.
- Search bar at top (client-side filter by name).
- FAB: "Add Equipment" → opens equipment form (2b).
- Long-press or swipe-to-reveal: Edit / Deactivate actions.

#### 2b — Equipment Form (Add / Edit)
Fields:
| Field | Type | Required |
|---|---|---|
| Name | Text (3–60 chars) | ✅ |
| Device Type | Segment selector: Fixed / Open / Cardio | ✅ |
| Canonical Exercise Key | Dropdown from `exercise_templates` (for fixed machines) | If Fixed |
| Manufacturer | Text (optional) | — |
| Model | Text (optional) | — |
| Description / Notes | Multi-line (optional) | — |
| Active / Inactive | Toggle | ✅ |

On save → `INSERT INTO gym_equipment` with `gym_id = activeGymId`, protected by admin RLS/RPC.

#### 2c — Deactivate / Reactivate Equipment
- Deactivated equipment: hidden from member-facing equipment picker.
- Still visible in admin list with `INACTIVE` badge.
- Deactivation must NOT delete historical set_logs referencing this equipment.
- Confirmation dialog before deactivation: "Members will no longer see this equipment. Historical data is preserved."

#### 2d — Equipment Detail View
On tap → detail sheet showing:
- Full metadata
- NFC tag assignment status → deep-link to NFC screen if not assigned
- Usage stats (sets logged this week/month, pulled from `set_logs` join)
- Recent feedback reports (if any)

---

## 3. Exercise Templates (🔴 BLOCKER — blocks muscle group XP axis)

### Route: `/admin/exercises`

### What Must Be Built

#### 3a — Exercise Template List
- Fetch `exercise_templates` where `gym_id = activeGymId` OR `gym_id IS NULL` (global templates).
- Display global templates in a separate section "DEFAULT EXERCISES" (read-only); gym-specific in "YOUR GYM EXERCISES" (editable).
- Each row: exercise name, primary muscle group tag, equipment type badge.

#### 3b — Exercise Template Form (Add / Edit)
Fields:
| Field | Type |
|---|---|
| Name | Text (required) |
| Primary Muscle Group | Dropdown from `MuscleGroup` enum |
| Secondary Muscle Groups | Multi-select chips |
| Equipment Type | Segment (Open / Cardio — fixed machines use canonical key) |
| Description | Multi-line (optional) |

#### 3c — Muscle Group Weight Mapping (Critical for XP Engine)
This is the data that feeds `muscle_group_weights` table and activates the muscle group XP axis for ALL members.

```
For each exercise:
  Chest:    [slider 0–100%]
  Back:     [slider 0–100%]
  Shoulders:[slider 0–100%]
  Legs:     [slider 0–100%]
  Arms:     [slider 0–100%]
  Core:     [slider 0–100%]
  Total must sum to 100% (show running total, disable save if ≠ 100%)
```

- Auto-populate with defaults for global exercises (e.g. bench press → Chest 70%, Triceps 20%, Shoulders 10%).
- Gym owner can override.
- Save → `UPSERT INTO muscle_group_weights` via admin-privileged RPC.
- **Without this data, the muscle-group leaderboard and muscle-group XP axis produce zero data for all members.**

---

## 4. Member List & Management (🔴 BLOCKER)

### Route: `/admin/members`

### What Must Be Built

#### 4a — Member List Screen
- Fetch all `gym_memberships` for `activeGymId` joined with `user_profiles` and `user_gym_xp`.
- Sort options: Alphabetical · Most Active (training days) · Highest XP · Joined Date.
- Each row: avatar, username, role badge (OWNER / ADMIN / COACH / MEMBER), XP level, last training day, join date.
- Search by username.
- Status filter tabs: `ALL` · `ACTIVE` · `INACTIVE` · `PENDING` (if approval flow enabled).

#### 4b — Member Detail Sheet
On tap → bottom sheet with:
- Avatar, username, display name
- Membership start date, last seen, training day count (this gym)
- Current role + role change action (4c below)
- XP per axis (consistency, equipment, muscle group) — read-only
- Deactivate membership action (with confirmation)

#### 4c — Pending Member Approval
If gym uses approval flow (1c):
- `PENDING` tab shows members with `status = 'pending'`.
- Each row: Approve / Decline actions.
- Approval → `UPDATE gym_memberships SET status = 'active'` via admin RPC.

---

## 5. Roles & Permissions (🔴 BLOCKER)

### Route: `/admin/roles`

### What Must Be Built

#### 5a — Role Management Screen
Display current gym team:
```
OWNER
  • @danielk  (you) — cannot be changed

ADMINS (2)
  • @trainer_max  [Demote → Member]
  • @coach_anna   [Demote → Member]

COACHES (1)
  • @assistant_leo  [Promote → Admin]  [Demote → Member]

MEMBERS
  [Search member to promote...]
```

#### 5b — Role Change Flow
- Promotion: Owner → promotes member to Coach or Admin.
- Demotion: Admin → demotes Coach or Admin to Member.
- Owner role: only one per gym; transfer requires explicit "Transfer Ownership" confirmation with re-auth.
- Server-side: all role changes via admin-privileged RPC that verifies the caller's role before changing.

```sql
CREATE OR REPLACE FUNCTION public.set_member_role(
  p_gym_id    UUID,
  p_target_id UUID,
  p_new_role  TEXT  -- 'member' | 'coach' | 'admin'
) RETURNS VOID SECURITY DEFINER LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM gym_memberships
    WHERE gym_id = p_gym_id AND user_id = auth.uid()
      AND role IN ('owner','admin')
  ) THEN RAISE EXCEPTION 'not_authorized'; END IF;

  -- Prevent owner downgrade via this function
  IF (SELECT role FROM gym_memberships WHERE gym_id = p_gym_id AND user_id = p_target_id) = 'owner' THEN
    RAISE EXCEPTION 'cannot_change_owner';
  END IF;

  UPDATE gym_memberships
  SET role = p_new_role
  WHERE gym_id = p_gym_id AND user_id = p_target_id;
END;
$$;
```

---

## 6. Challenges (🟡)

### Route: `/admin/challenges`

### What Must Be Built

#### 6a — Challenge List
- Fetch `gym_challenges` for `activeGymId`.
- Tabs: `ACTIVE` · `UPCOMING` · `COMPLETED`.
- Each row: title, type badge (training days / total XP / specific exercise), start/end dates, participant count.
- FAB: Create Challenge.

#### 6b — Challenge Form
Fields:
| Field | Type |
|---|---|
| Title | Text (required) |
| Description | Multi-line (optional) |
| Challenge Type | Enum: `training_days` / `total_xp` / `exercise_volume` |
| Target Metric | Number (e.g. 20 training days, 10,000 XP) |
| Start Date | Date picker |
| End Date | Date picker |
| Visibility | All members / Opt-in |

On save → `INSERT INTO gym_challenges` via admin RPC. Challenge engine awards XP/badges at end date via Edge Function.

#### 6c — Challenge Detail
- Live leaderboard of participants.
- Current user's progress vs. target.
- Stop / extend challenge (admin action, requires confirmation).

---

## 7. Analytics Dashboard (🟡)

### Route: `/admin/analytics`, `/admin/equipment-analytics`, `/admin/engagement`

### What Must Be Built

#### 7a — Activity Dashboard (`/admin/analytics`)
Key metrics cards:
- **DAU / WAU / MAU** — count of distinct `user_id` with ≥1 finished session in day / 7 days / 30 days.
- **Total Training Days This Month** — count of `session_day_anchor` distinct values.
- **New Members This Month** — count from `gym_memberships` by `created_at`.
- **Retention Rate** — members who trained at least once in week 4 vs. week 1 (cohort).

Trend charts (last 30 days): daily active members line chart, new members bar chart.

Supabase RPC pattern:
```sql
CREATE OR REPLACE FUNCTION public.get_gym_activity_stats(p_gym_id UUID)
RETURNS JSON SECURITY DEFINER LANGUAGE sql AS $$
  SELECT json_build_object(
    'dau',   (SELECT COUNT(DISTINCT user_id) FROM workout_sessions
              WHERE gym_id = p_gym_id AND status = 'finished'
                AND session_day_anchor::DATE = CURRENT_DATE),
    'wau',   (SELECT COUNT(DISTINCT user_id) FROM workout_sessions
              WHERE gym_id = p_gym_id AND status = 'finished'
                AND session_day_anchor::DATE >= CURRENT_DATE - 7),
    'mau',   (SELECT COUNT(DISTINCT user_id) FROM workout_sessions
              WHERE gym_id = p_gym_id AND status = 'finished'
                AND session_day_anchor::DATE >= CURRENT_DATE - 30)
  );
$$;
```

#### 7b — Equipment Usage (`/admin/equipment-analytics`)
Per-equipment row:
- Equipment name, type
- Total sets logged (all time + last 30 days)
- Unique users who used it
- Average sets per session
- Last used (relative date)

Sort by: Most Used · Least Used · Last Used. Shows which machines are popular and which are gathering dust.

#### 7c — Engagement Metrics (`/admin/engagement`)
- XP distribution: histogram of member levels (how many at LVL 1–3, 4–6, 7–10, 10+).
- Challenge participation rate: `participants / total_active_members`.
- Community activity: friend requests sent this month, leaderboard views, deals clicks.
- Top 10 most active members (training days, this month) — anonymizable toggle for DSGVO.

---

## 8. Moderation (🟡)

### Route: `/admin/moderation`

### What Must Be Built

#### 8a — Reported Items Queue
- `content_reports` table in Supabase (if not yet created):
  ```sql
  CREATE TABLE public.content_reports (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gym_id        UUID NOT NULL REFERENCES gyms(id),
    reporter_id   UUID NOT NULL REFERENCES user_profiles(id),
    target_user_id UUID REFERENCES user_profiles(id),
    report_type   TEXT NOT NULL, -- 'inappropriate_username' | 'spam' | 'harassment'
    description   TEXT,
    status        TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'resolved' | 'dismissed'
    created_at    TIMESTAMPTZ DEFAULT NOW()
  );
  ```
- Admin screen: list of pending reports with reporter, target, type, and date.
- Action buttons: Resolve (take action) / Dismiss (no action needed).

#### 8b — Actions Available
- Warn member (add note to their membership record).
- Deactivate membership.
- Escalate to platform operator (Tap'em support).

---

## 9. Equipment Feedback (🔵)

### Route: `/admin/equipment-feedback`

### What Must Be Built

#### 9a — Feedback List
- Fetch `equipment_feedback` table for gym.
  ```sql
  CREATE TABLE public.equipment_feedback (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gym_id        UUID NOT NULL REFERENCES gyms(id),
    equipment_id  UUID NOT NULL REFERENCES gym_equipment(id),
    reporter_id   UUID NOT NULL REFERENCES user_profiles(id),
    feedback_type TEXT NOT NULL, -- 'broken' | 'maintenance' | 'suggestion'
    note          TEXT,
    status        TEXT NOT NULL DEFAULT 'open', -- 'open' | 'in_progress' | 'resolved'
    created_at    TIMESTAMPTZ DEFAULT NOW()
  );
  ```
- List grouped by equipment name.
- Each row: type badge, reporter (anonymous option), note, date, status.

#### 9b — Status Update
Admin can change status: `open → in_progress → resolved`.
Optional: notify the reporter when status changes to `resolved`.

#### 9c — Member-Side Reporting Entry Point
In `equipment_picker_screen.dart` or the active workout screen, add a "Report Issue" overflow menu item that opens a small bottom sheet:
```
What's wrong?
  ○ Equipment broken
  ○ Needs maintenance
  ○ Other suggestion
[Note field]
[Send Report]
```

---

## 10. Security & Data Governance (🔴)

### 10a — Admin Action Audit Log
All privileged admin actions (role changes, equipment deactivation, member deactivation, challenge start/stop) must be logged:
```sql
CREATE TABLE public.admin_audit_log (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  gym_id      UUID NOT NULL REFERENCES gyms(id),
  actor_id    UUID NOT NULL REFERENCES user_profiles(id),
  action      TEXT NOT NULL,   -- 'role_change' | 'deactivate_member' | etc.
  target_id   UUID,            -- affected user or entity
  metadata    JSONB,           -- before/after state
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```
RLS: admin and owner can SELECT own gym's log; no client INSERT (written by RPCs only).

### 10b — DSGVO / Data Export & Deletion
Per `AC-DAT-02`, gym owners must be able to:
- Export a gym's member data (CSV/JSON) on request.
- Delete a member's data on request (right to erasure).

Implement as:
1. Admin dashboard button: "Export Member Data" → triggers Edge Function → returns downloadable JSON.
2. "Delete Member Data" confirmation → cascades deletes on user_profiles, workout_sessions, set_logs, xp tables for that user within the gym scope. Preserves anonymized aggregate stats.

### 10c — RLS: Admin Read Scope
Gym admins must be able to read workout stats for their own gym members, but NOT for members of other gyms. Verify:
```sql
-- workout_sessions: admin can read all sessions in their gym
CREATE POLICY workout_sessions_admin_read ON public.workout_sessions
  FOR SELECT USING (
    user_id = auth.uid()
    OR gym_id IN (
      SELECT gym_id FROM gym_memberships
      WHERE user_id = auth.uid() AND role IN ('owner','admin','coach')
    )
  );
```

---

## 11. Deals Management — Admin-Side Polish (🟡)

> Core implementation exists. Polish items only.

### 11a — Deal Expiry Indicator
In the admin deals list, show days remaining / expired status per deal. Currently deals show no expiry prominently.

### 11b — Deal Analytics
Per deal:
- View count (impressions — requires tracking event on deal card render).
- Click count (CTA taps — already partially trackable via `url_launcher`).
- Redemption estimate (if discount code used — requires affiliate partner integration, V1.1).

### 11c — Deal Categories: Custom Category
Currently hardcoded to `supplements`, `clothing`, `food`, `equipment`, `wellness`. Add ability for gym to create a custom category label (stored on the deal, not a global enum extension).

---

## 12. Gym-Level Notification Controls (🔵)

### Route: Not yet in admin menu — add under Gym Settings

### What Must Be Built
- **Send Announcement**: push notification to all gym members (admin-triggered). Text message, optionally with a deep-link.
- **Challenge Start/End Notifications**: auto-sent when admin starts or closes a challenge.
- **New Deal Notification**: optional push when a new deal is published.

Implementation: Supabase Edge Function + FCM (Firebase Cloud Messaging) or APNs direct. Notification preferences controllable per member in their profile settings.

---

## Implementation Sequence (Recommended Sprint Map)

```
Sprint 1 — Gym Onboarding Unblock (🔴 critical path)
  1. Gym Settings: gym code display + share            [1a]
  2. Gym Settings: gym profile edit (name, logo)       [1b]
  3. Equipment Manager: list + add + deactivate        [2a–2c]

Sprint 2 — People Management (🔴 critical path)
  1. Member List with filters + sort                   [4a]
  2. Member Detail sheet                               [4b]
  3. Roles & Permissions screen                        [5a–5b]

Sprint 3 — Exercise Templates + XP Engine
  1. Exercise Template list + form                     [3a–3b]
  2. Muscle group weight mapping (sliders)             [3c]
  (This unlocks muscle group XP for all members)

Sprint 4 — Challenges
  1. Challenge list + form                             [6a–6b]
  2. Challenge detail + live leaderboard               [6c]

Sprint 5 — Analytics V1
  1. Activity dashboard (DAU/WAU/MAU)                  [7a]
  2. Equipment usage table                             [7b]
  3. Engagement metrics                                [7c]

Sprint 6 — Safety, Governance & Polish
  1. Admin audit log                                   [10a]
  2. DSGVO export + deletion                           [10b]
  3. RLS admin read scope audit                        [10c]
  4. Moderation queue                                  [8a–8b]
  5. Equipment feedback flow                           [9a–9c]

Sprint 7 — Deals Polish + Notifications (🔵)
  1. Deal expiry indicator                             [11a]
  2. Deal analytics                                    [11b]
  3. Announcement push notifications                   [12]
```

---

## Acceptance Criteria Mapping

| This Document | Spec AC |
|---|---|
| 1a–1c (gym onboarding) | AC-PROD-01 |
| 2a–2d (equipment manager) | AC-PROD-01, AC-PROD-05 |
| 3a–3c (exercise templates + muscle weights) | AC-PROD-04, AC-PROD-05 |
| 4a–4c (member management) | AC-PROD-01 |
| 5a–5b (roles) | AC-PROD-01, AC-SEC-01 |
| 10a (audit log) | AC-SEC-03 |
| 10b (DSGVO) | AC-DAT-02 |
| 10c (RLS admin scope) | AC-SEC-04 |
| All RPCs (SECURITY DEFINER) | AC-SEC-01, AC-SEC-02, AC-SEC-05 |
