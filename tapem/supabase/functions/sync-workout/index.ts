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
// Muscle group XP model (v2):
//   Flat rate per exercise per muscle group — independent of set count or reps.
//   primary   → 10.0 XP  (XP_MG_PRIMARY)
//   secondary →  2.5 XP  (XP_MG_SECONDARY)
//   Source table: exercise_muscle_groups (fixed machines) or
//                 user_custom_exercise_muscle_groups (open station custom exercises)
//
// Error contract:
//   200 — session + XP fully persisted
//   400 — malformed request body / validation failure
//   401 — missing or invalid JWT
//   403 — user is not the session owner, or has no active membership
//   500 — DB write failure (client should mark session sync_failed and retry)
// =============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  XP_TRAINING_DAY,
  XP_MG_PRIMARY,
  XP_MG_SECONDARY,
  calcVariableExerciseXp,
  type SetLike,
} from "../_shared/xp.ts";

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
  session_day_anchor: string; // yyyy-MM-dd — ignored; server derives from started_at
  started_at: string;         // ISO 8601 — authoritative source for day anchor
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
  equipment_id: string | null;
  sets: SetPayload[];
  /** Muscle groups from the local cache for this exercise (custom exercises only). */
  custom_muscle_groups?: Array<{ muscle_group: string; role: "primary" | "secondary" }>;
}

interface SetPayload extends SetLike {
  set_entry_id: string;
  set_number: number;
  reps: number | null;
  weight_kg: number | null;
  duration_seconds: number | null;
  distance_meters: number | null;
  idempotency_key: string;
}

// ─── Validation constants ─────────────────────────────────────────────────────

/** exercise_key must match this pattern — rejects anything outside a-z0-9:_.- */
const EXERCISE_KEY_RE = /^[a-z0-9_:.-]{1,120}$/;

/** display_name is silently truncated to this length at write time. */
const DISPLAY_NAME_MAX = 120;

/** Hard upper bounds for set metric fields. Values above these are rejected. */
const SET_LIMITS = {
  reps:             500,
  weight_kg:        500,
  duration_seconds: 86_400,  // 24 h
  distance_meters:  200_000, // 200 km
};

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

  // ── Input validation ─────────────────────────────────────────────────────────
  const exerciseErr = validateExercises(body.exercises);
  if (exerciseErr) {
    return jsonResponse({ error: exerciseErr }, 400);
  }

  // ── Active membership check ──────────────────────────────────────────────────
  // Membership must be pre-existing. Auto-creation is intentionally not supported:
  // users must join via the gym join-code flow before syncing workouts.
  const { data: membership } = await supabase
    .from("memberships")
    .select("id")
    .eq("user_id", user.id)
    .eq("gym_id", body.session.gym_id)
    .eq("is_active", true)
    .maybeSingle();

  if (!membership) {
    return jsonResponse({ error: "No active membership for this gym" }, 403);
  }

  // ── Derive day anchor server-side ────────────────────────────────────────────
  // The client's session_day_anchor field is ignored — we recompute it from
  // started_at to prevent backdating or future-dating of training-day XP.
  const sessionDayAnchor = deriveSessionDayAnchor(body.session.started_at);

  // ── 1. Upsert workout_session ────────────────────────────────────────────────

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
        session_day_anchor: sessionDayAnchor,
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
      display_name: exercise.display_name.slice(0, DISPLAY_NAME_MAX),
      sort_order: exercise.sort_order,
      custom_exercise_id: exercise.custom_exercise_id,
      equipment_id: isValidUuid(exercise.equipment_id)
        ? exercise.equipment_id
        : sessionEquipmentId,
    };

    let { error: exErr } = await supabase
      .from("session_exercises")
      .upsert(exerciseRow, { onConflict: "id", ignoreDuplicates: false });

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

    // Sync custom exercise muscle groups when present in the payload.
    if (exercise.custom_exercise_id && exercise.custom_muscle_groups?.length) {
      const mgRows = exercise.custom_muscle_groups.map((mg) => ({
        user_custom_exercise_id: exercise.custom_exercise_id,
        user_id: user.id,
        muscle_group: mg.muscle_group,
        role: mg.role,
      }));
      await supabase
        .from("user_custom_exercise_muscle_groups")
        .upsert(mgRows, { onConflict: "user_custom_exercise_id,muscle_group", ignoreDuplicates: false });
    }

    // ── Reconcile sets: delete orphaned Supabase rows ──────────────────────────
    // Mirrors the client's current set list — rows not in the payload were
    // unchecked (deleted from SQLite) and must be removed from the server too.
    // Without this step, re-checking a set at the same position would conflict
    // with the orphaned row's UNIQUE (session_exercise_id, set_number) constraint
    // and cause every subsequent sync to return HTTP 500.
    const currentSetIds = exercise.sets.map((s) => s.set_entry_id);
    const orphanQuery = supabase
      .from("set_entries")
      .delete()
      .eq("session_exercise_id", exercise.session_exercise_id);

    const { error: orphanErr } = await (currentSetIds.length > 0
      ? orphanQuery.not("id", "in", `(${currentSetIds.join(",")})`)
      : orphanQuery);

    if (orphanErr) {
      console.error("[sync-workout] orphan set delete failed:", orphanErr);
      return jsonResponse({ error: "Failed to persist sets" }, 500);
    }

    if (exercise.sets.length > 0) {
      // ── Validate set metrics before persisting ──────────────────────────────
      const metricErr = validateSetMetrics(exercise.sets);
      if (metricErr) {
        return jsonResponse({ error: "Set metric out of bounds", detail: metricErr }, 400);
      }

      const setRows = exercise.sets.map((s) => ({
        id: s.set_entry_id,
        session_exercise_id: exercise.session_exercise_id,
        gym_id: body.session.gym_id,
        set_number: s.set_number,
        reps: (s.reps != null && s.reps > 0) ? s.reps : null,
        weight_kg: s.weight_kg,
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

  if (body.session.finished_at !== null) {
    const xpErr = await insertXpEvents(
      supabase,
      user.id,
      body,
      sessionEquipmentId,
      sessionDayAnchor,
    );
    if (xpErr) {
      console.error("[sync-workout] XP insert failed:", xpErr);
      return jsonResponse({ error: "XP processing failed" }, 500);
    }

    // Performance leaderboard recomputation is best-effort: workout sync and XP
    // persistence stay successful even if this derived aggregate refresh fails.
    await recomputeMachinePerformance(supabase, body.session.id);
  }

  return jsonResponse({
    ok: true,
    request_id: body.request_id,
    session_id: body.session.id,
  }, 200);
});

// ─── XP event generation ──────────────────────────────────────────────────────

async function insertXpEvents(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  body: SyncWorkoutRequest,
  sessionEquipmentId: string | null,
  dayAnchor: string,
): Promise<string | null> {
  const { gym_id: gymId, id: sessionId, finished_at: finishedAt } = body.session;

  const events: Record<string, unknown>[] = [];

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

  // exercise_equipment XP + muscle_group XP — one pass per exercise
  for (const exercise of body.exercises) {
    if (exercise.sets.length === 0) continue;

    const exerciseXp = calcVariableExerciseXp(exercise.sets);
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
      equipment_id: isValidUuid(exercise.equipment_id)
        ? exercise.equipment_id
        : sessionEquipmentId,
      occurred_at: finishedAt!,
    });

    // No muscle group XP for cardio exercises.
    if (exercise.exercise_key.startsWith("cardio:")) continue;

    // ── Resolve muscle group assignments ──────────────────────────────────────
    //
    // Priority:
    //   1. custom_muscle_groups from payload  (user-defined, open station)
    //   2. exercise_muscle_groups from DB     (seeded, fixed machine)

    let mgRows: Array<{ muscle_group: string; role: string }> = [];

    if (exercise.custom_muscle_groups?.length) {
      mgRows = exercise.custom_muscle_groups;
    } else if (exercise.exercise_key && !exercise.exercise_key.startsWith("custom:")) {
      const { data } = await supabase
        .from("exercise_muscle_groups")
        .select("muscle_group, role")
        .eq("exercise_key", exercise.exercise_key)
        .eq("gym_id", gymId);
      mgRows = data ?? [];
    }

    // Fall back to DB-stored custom exercise muscle groups if payload omitted them.
    if (mgRows.length === 0 && exercise.custom_exercise_id) {
      const { data } = await supabase
        .from("user_custom_exercise_muscle_groups")
        .select("muscle_group, role")
        .eq("user_custom_exercise_id", exercise.custom_exercise_id);
      mgRows = data ?? [];
    }

    for (const mg of mgRows) {
      const xpAmount = mg.role === "primary" ? XP_MG_PRIMARY : XP_MG_SECONDARY;
      events.push({
        gym_id: gymId,
        user_id: userId,
        axis: "muscle_group",
        xp_amount: xpAmount,
        source_type: "session_exercise",
        source_id: exercise.session_exercise_id,
        idempotency_key: `mg:${mg.muscle_group}:${mg.role}:se:${exercise.session_exercise_id}`,
        exercise_key: exercise.exercise_key,
        muscle_group: mg.muscle_group,
        occurred_at: finishedAt!,
      });
    }
  }

  const { error } = await supabase
    .from("xp_events")
    .upsert(events, { onConflict: "idempotency_key", ignoreDuplicates: true });

  return error?.message ?? null;
}

async function recomputeMachinePerformance(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  sessionId: string,
): Promise<void> {
  const { error } = await supabase.rpc("recompute_machine_performance_for_session", {
    p_session_id: sessionId,
  });
  if (error) {
    console.warn("[sync-workout] machine performance recompute failed:", error.message);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isValidUuid(value: string | null | undefined): value is string {
  return typeof value === "string" && UUID_RE.test(value);
}

/**
 * Derives a yyyy-MM-dd day anchor from an ISO 8601 timestamp using the
 * Europe/Berlin timezone. The client-supplied session_day_anchor is ignored
 * in favour of this server-computed value to prevent backdating.
 */
function deriveSessionDayAnchor(isoTimestamp: string): string {
  // "sv-SE" locale produces YYYY-MM-DD format natively via Intl.DateTimeFormat.
  return new Intl.DateTimeFormat("sv-SE", {
    timeZone: "Europe/Berlin",
  }).format(new Date(isoTimestamp));
}

/**
 * Validates exercise_key format for every exercise in the payload.
 * Returns a human-readable error string on first violation, or null if valid.
 * display_name is handled via silent truncation at write time (no hard reject).
 */
function validateExercises(exercises: ExercisePayload[]): string | null {
  for (const ex of exercises) {
    if (!EXERCISE_KEY_RE.test(ex.exercise_key)) {
      return `Invalid exercise_key: "${ex.exercise_key}"`;
    }
  }
  return null;
}

/**
 * Validates set metric fields against upper bounds.
 * Returns a structured error object on first violation, or null if all valid.
 */
function validateSetMetrics(
  sets: SetPayload[],
): { set_entry_id: string; field: string; value: number } | null {
  for (const s of sets) {
    if (s.reps != null && s.reps > SET_LIMITS.reps) {
      return { set_entry_id: s.set_entry_id, field: "reps", value: s.reps };
    }
    if (s.weight_kg != null && s.weight_kg > SET_LIMITS.weight_kg) {
      return { set_entry_id: s.set_entry_id, field: "weight_kg", value: s.weight_kg };
    }
    if (s.duration_seconds != null && s.duration_seconds > SET_LIMITS.duration_seconds) {
      return { set_entry_id: s.set_entry_id, field: "duration_seconds", value: s.duration_seconds };
    }
    if (s.distance_meters != null && s.distance_meters > SET_LIMITS.distance_meters) {
      return { set_entry_id: s.set_entry_id, field: "distance_meters", value: s.distance_meters };
    }
  }
  return null;
}
