// =============================================================================
// Tap'em — Sync Workout Edge Function
//
// Receives a complete workout payload (session + exercises + sets) from the
// offline-first Flutter client and persists it to Postgres via the service-role
// key. All DB writes are idempotent: client-generated UUIDs are used as primary
// keys, and upserts use ON CONFLICT DO NOTHING / DO UPDATE where appropriate.
//
// If the session is finished (finished_at set), XP events are inserted inline.
// XP aggregate recomputation (user_gym_xp / user_exercise_xp) is handled by
// the DB trigger on xp_events — no explicit RPC call is needed here.
//
// Error contract:
//   200 — session + XP fully persisted
//   400 — malformed request body
//   401 — missing or invalid JWT
//   403 — user is not the session owner, or has no active membership
//   404 — (unused — kept for future use)
//   500 — DB write failure (client should mark session sync_failed and retry)
// =============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Request schema ───────────────────────────────────────────────────────────

interface SyncWorkoutRequest {
  request_id: string;       // client-generated UUID — used for audit/idempotency
  session: SessionPayload;
  exercises: ExercisePayload[];
}

interface SessionPayload {
  id: string;
  gym_id: string;
  user_id: string;
  equipment_id: string;
  session_day_anchor: string; // yyyy-MM-dd
  started_at: string;         // ISO 8601
  finished_at: string | null;
  idempotency_key: string;
  notes: string | null;
}

interface ExercisePayload {
  session_exercise_id: string;
  exercise_key: string;
  display_name: string;
  sort_order: number;
  custom_exercise_id: string | null;
  equipment_id: string | null;  // per-exercise machine attribution (may be 'freestyle' sentinel)
  sets: SetPayload[];
}

interface SetPayload {
  set_entry_id: string;
  set_number: number;
  reps: number | null;
  weight_kg: number | null;
  duration_seconds: number | null;
  distance_meters: number | null;
  idempotency_key: string;
}

// ─── XP event shape (matches xp_events table columns) ────────────────────────

interface XpEvent {
  gym_id: string;
  user_id: string;
  axis: "training_day" | "exercise_equipment" | "muscle_group";
  xp_amount: number;
  source_type: string;
  source_id: string;
  idempotency_key: string;
  exercise_key?: string;
  muscle_group?: string;
  occurred_at: string;
}

// ─── XP constants (mirror XpRules in Flutter) ────────────────────────────────

const XP_TRAINING_DAY = 25;
// Flat XP per exercise per session — matches XpRules.exerciseSessionBase = 25.
// Awarded once per exercise regardless of set count. Not variable per set.
const XP_EXERCISE_BASE = 25;

// ─── Handler ──────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method Not Allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  // User-scoped client — JWT verification only. All writes use service-role.
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let body: SyncWorkoutRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  // Service-role client — bypasses RLS. Ownership enforced manually below.
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── Ownership guard ──────────────────────────────────────────────────────────
  if (body.session.user_id !== user.id) {
    return jsonResponse({ error: "Forbidden" }, 403);
  }

  // ── Active membership check — upsert if missing ──────────────────────────────
  //
  // For an offline-first app, a valid JWT + session ownership is sufficient to
  // trust the data. If the membership row is missing (e.g., join_gym_with_code
  // failed silently, or the row was lost), we create it here rather than
  // blocking the sync forever. The user was physically present in the gym when
  // they recorded the session, so the membership is legitimate.
  const { data: membership } = await supabase
    .from("memberships")
    .select("id")
    .eq("user_id", user.id)
    .eq("gym_id", body.session.gym_id)
    .eq("is_active", true)
    .maybeSingle();

  if (!membership) {
    console.log(`[sync-workout] no active membership found for user=${user.id} gym=${body.session.gym_id} — creating one`);
    const { error: membershipInsertErr } = await supabase
      .from("memberships")
      .upsert(
        {
          gym_id: body.session.gym_id,
          user_id: user.id,
          role: "member",
          is_active: true,
        },
        { onConflict: "user_id,gym_id", ignoreDuplicates: false },
      );
    if (membershipInsertErr) {
      console.error("[sync-workout] membership upsert failed:", membershipInsertErr);
      return jsonResponse({ error: "No active membership for this gym" }, 403);
    }
  }

  // ── 1. Upsert workout_session ────────────────────────────────────────────────

  // 'freestyle' is a Flutter sentinel meaning "no machine scanned" — store as null in DB
  const sessionEquipmentId = isValidUuid(body.session.equipment_id)
    ? body.session.equipment_id
    : null;

  const { error: sessionErr } = await supabase
    .from("workout_sessions")
    .upsert(
      {
        id: body.session.id,
        gym_id: body.session.gym_id,
        user_id: body.session.user_id,
        equipment_id: sessionEquipmentId,
        session_day_anchor: body.session.session_day_anchor,
        started_at: body.session.started_at,
        finished_at: body.session.finished_at,
        notes: body.session.notes,
        idempotency_key: body.session.idempotency_key,
        sync_status: "sync_confirmed",
      },
      { onConflict: "id", ignoreDuplicates: false },
    );

  if (sessionErr) {
    console.error("[sync-workout] session upsert failed:", sessionErr);
    return jsonResponse({ error: "Failed to persist session" }, 500);
  }

  // ── 2. Upsert session_exercises + set_entries ────────────────────────────────

  for (const exercise of body.exercises) {
    const exerciseRow = {
      id: exercise.session_exercise_id,
      session_id: body.session.id,
      gym_id: body.session.gym_id,
      exercise_key: exercise.exercise_key,
      display_name: exercise.display_name,
      sort_order: exercise.sort_order,
      custom_exercise_id: exercise.custom_exercise_id,
    };

    let { error: exErr } = await supabase
      .from("session_exercises")
      .upsert(exerciseRow, { onConflict: "id", ignoreDuplicates: false });

    // FK miss on custom_exercise_id (e.g. the custom exercise was deleted from
    // the server while the local session still referenced it). Retry with null
    // so the session data and XP are not permanently lost.
    if (exErr?.code === "23503" && exErr.message.includes("custom_exercise_id")) {
      console.warn("[sync-workout] custom_exercise_id FK miss — retrying with null:", exercise.custom_exercise_id);
      ({ error: exErr } = await supabase
        .from("session_exercises")
        .upsert({ ...exerciseRow, custom_exercise_id: null }, { onConflict: "id", ignoreDuplicates: false }));
    }

    if (exErr) {
      console.error("[sync-workout] exercise upsert failed:", exErr);
      return jsonResponse({ error: "Failed to persist exercise", detail: exErr.message }, 500);
    }

    if (exercise.sets.length > 0) {
      const setRows = exercise.sets.map((s) => ({
        id: s.set_entry_id,
        session_exercise_id: exercise.session_exercise_id,
        gym_id: body.session.gym_id,
        set_number: s.set_number,
        // Normalise 0 and negative values to NULL — the DB enforces CHECK > 0
        // for these columns, and 0 reps/duration/distance is meaningless.
        reps: (s.reps != null && s.reps > 0) ? s.reps : null,
        weight_kg: s.weight_kg,  // 0 is valid (bodyweight)
        duration_seconds: (s.duration_seconds != null && s.duration_seconds > 0) ? s.duration_seconds : null,
        distance_meters: (s.distance_meters != null && s.distance_meters > 0) ? s.distance_meters : null,
        idempotency_key: s.idempotency_key,
        sync_status: "sync_confirmed",
      }));

      const { error: setsErr } = await supabase
        .from("set_entries")
        .upsert(setRows, { onConflict: "id", ignoreDuplicates: false });

      if (setsErr) {
        console.error("[sync-workout] set_entries upsert failed:", setsErr);
        return jsonResponse({ error: "Failed to persist sets" }, 500);
      }
    }
  }

  // ── 3. XP processing (only for finished sessions) ────────────────────────────
  //
  // XP aggregate recomputation (user_gym_xp / user_exercise_xp) is triggered
  // automatically by the DB trigger on xp_events (migration 00021). This
  // function only needs to insert the raw events.
  //
  // IMPORTANT: XP failure is fatal — we return 500 so the Flutter client marks
  // the session sync_failed and retries. xp_events upserts are idempotent via
  // idempotency_key, so retries are always safe.

  if (body.session.finished_at !== null) {
    const xpErr = await insertXpEvents(supabase, user.id, body, sessionEquipmentId);
    if (xpErr) {
      console.error("[sync-workout] XP insert failed:", xpErr);
      // Session data is already persisted at this point. The client will retry
      // the full sync, which re-upserts session/exercises/sets (no-ops) and
      // retries XP insertion.
      return jsonResponse({ error: "XP processing failed" }, 500);
    }
  }

  return jsonResponse({
    ok: true,
    request_id: body.request_id,
    session_id: body.session.id,
  }, 200);
});

// ─── XP event generation ──────────────────────────────────────────────────────
//
// Builds and inserts xp_events for one finished workout session.
// Returns an error string on failure, null on success.
//
// Aggregate recomputation is NOT performed here — it is handled by the
// xp_events_recompute_on_insert trigger (migration 00021).

async function insertXpEvents(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  body: SyncWorkoutRequest,
  sessionEquipmentId: string | null,
): Promise<string | null> {
  const { gym_id: gymId, id: sessionId, session_day_anchor: dayAnchor, finished_at: finishedAt } = body.session;
  const events: XpEvent[] = [];

  // training_day XP — one award per (user, gym, day), idempotent
  events.push({
    gym_id: gymId,
    user_id: userId,
    axis: "training_day",
    xp_amount: XP_TRAINING_DAY,
    source_type: "workout_session",
    source_id: sessionId,
    idempotency_key: `training_day:workout_session:${gymId}:${userId}:${dayAnchor}`,
    occurred_at: finishedAt!,
  });

  // exercise_equipment XP + muscle_group XP per exercise
  for (const exercise of body.exercises) {
    // Flat 25 XP per exercise-session, awarded if the exercise has at least one set.
    // Mirrors XpRules.exerciseSessionBase in Flutter — no per-set/per-rep variation.
    const exerciseXp = exercise.sets.length > 0 ? XP_EXERCISE_BASE : 0;
    if (exerciseXp <= 0) continue;

    events.push({
      gym_id: gymId,
      user_id: userId,
      axis: "exercise_equipment",
      xp_amount: exerciseXp,
      source_type: "session_exercise",
      source_id: exercise.session_exercise_id,
      idempotency_key: `exercise_equipment:session_exercise:${exercise.session_exercise_id}`,
      exercise_key: exercise.exercise_key,
      // Denormalised: store equipment_id directly so leaderboard queries never
      // need to join through session_exercises → workout_sessions.
      // Priority: per-exercise equipment_id (valid UUID) > session equipment_id > null.
      // 'freestyle' sentinel is treated as null (no machine scanned).
      equipment_id: isValidUuid(exercise.equipment_id)
        ? exercise.equipment_id
        : sessionEquipmentId,
      occurred_at: finishedAt!,
    });

    // muscle_group XP derived from gym-specific weight mappings
    const { data: weights } = await supabase
      .from("muscle_group_weights")
      .select("muscle_group, weight")
      .eq("exercise_key", exercise.exercise_key)
      .eq("gym_id", gymId);

    for (const w of weights ?? []) {
      const mgXp = Math.round(exerciseXp * (w.weight as number));
      if (mgXp <= 0) continue;
      events.push({
        gym_id: gymId,
        user_id: userId,
        axis: "muscle_group",
        xp_amount: mgXp,
        source_type: "session_exercise",
        source_id: exercise.session_exercise_id,
        idempotency_key: `muscle_group:${w.muscle_group}:session_exercise:${exercise.session_exercise_id}`,
        exercise_key: exercise.exercise_key,
        muscle_group: w.muscle_group,
        occurred_at: finishedAt!,
      });
    }
  }

  const { error } = await supabase
    .from("xp_events")
    .upsert(events, { onConflict: "idempotency_key", ignoreDuplicates: true });

  return error?.message ?? null;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Returns true only for properly-formatted UUIDs. Rejects 'freestyle' and other sentinels. */
function isValidUuid(value: string | null | undefined): value is string {
  return typeof value === "string" && UUID_RE.test(value);
}
