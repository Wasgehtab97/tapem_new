// =============================================================================
// Tap'em — Finish Session Edge Function
//
// Marks a workout session as finished and inserts XP events for it.
// Called when the user ends a session that was already synced to Postgres
// (i.e. the session row exists; this function only sets finished_at and
// computes XP).
//
// XP aggregate recomputation (user_gym_xp / user_exercise_xp) is handled
// automatically by the DB trigger on xp_events (migration 00021).
//
// Error contract:
//   200 — session finished; XP inserted (or skipped if no exercises with sets)
//   400 — malformed request
//   401 — missing or invalid JWT
//   403 — caller is not the session owner
//   404 — session not found (or not owned by caller)
//   500 — DB write failure
// =============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface FinishSessionRequest {
  session_id: string;
  gym_id: string;
  finished_at: string; // ISO 8601
}

// ─── XP constants (mirror AppConfig in Flutter) ───────────────────────────────

const XP_TRAINING_DAY = 25;
const XP_PER_SET_BASE = 5;
const XP_EXERCISE_CAP = 120;

// ─── Handler ──────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method Not Allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let body: FinishSessionRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  // Service-role client — bypasses RLS. Ownership enforced below.
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── Verify session ownership ─────────────────────────────────────────────────

  const { data: session } = await supabase
    .from("workout_sessions")
    .select("id, user_id, gym_id, session_day_anchor, equipment_id")
    .eq("id", body.session_id)
    .eq("user_id", user.id)
    .maybeSingle();

  if (!session) {
    return jsonResponse({ error: "Session not found" }, 404);
  }

  // ── Mark session finished ────────────────────────────────────────────────────

  const { error: updateErr } = await supabase
    .from("workout_sessions")
    .update({ finished_at: body.finished_at })
    .eq("id", body.session_id);

  if (updateErr) {
    console.error("[finish-session] failed to update session:", updateErr);
    return jsonResponse({ error: "Failed to finish session" }, 500);
  }

  // ── Fetch exercises + sets for XP computation ────────────────────────────────

  const { data: exercises } = await supabase
    .from("session_exercises")
    .select("id, exercise_key, set_entries(id, reps, duration_seconds)")
    .eq("session_id", body.session_id);

  if (!exercises || exercises.length === 0) {
    // No exercises recorded — nothing to award XP for, but session is finished.
    return jsonResponse({ ok: true, xp_events: 0 }, 200);
  }

  // ── Build XP events ──────────────────────────────────────────────────────────

  const gymId = session.gym_id as string;
  const dayAnchor = session.session_day_anchor as string;

  const events: Record<string, unknown>[] = [
    {
      gym_id: gymId,
      user_id: user.id,
      axis: "training_day",
      xp_amount: XP_TRAINING_DAY,
      source_type: "workout_session",
      source_id: body.session_id,
      idempotency_key: `training_day:workout_session:${gymId}:${user.id}:${dayAnchor}`,
      occurred_at: body.finished_at,
    },
  ];

  for (const ex of exercises) {
    const sets = (ex.set_entries as Array<{
      id: string;
      reps: number | null;
      duration_seconds: number | null;
    }>) ?? [];

    let exerciseXp = 0;
    for (const s of sets) {
      const reps = s.reps ?? 0;
      const raw = s.duration_seconds !== null
        ? XP_PER_SET_BASE
        : XP_PER_SET_BASE + Math.floor(reps / 5);
      exerciseXp += raw;
    }
    exerciseXp = Math.min(exerciseXp, XP_EXERCISE_CAP);
    if (exerciseXp <= 0) continue;

    events.push({
      gym_id: gymId,
      user_id: user.id,
      axis: "exercise_equipment",
      xp_amount: exerciseXp,
      source_type: "session_exercise",
      source_id: ex.id,
      idempotency_key: `exercise_equipment:session_exercise:${ex.id}`,
      exercise_key: ex.exercise_key,
      // Denormalised: store equipment_id directly so leaderboard queries never
      // need to join through session_exercises → workout_sessions.
      equipment_id: (session.equipment_id as string | null) ?? null,
      occurred_at: body.finished_at,
    });

    const { data: weights } = await supabase
      .from("muscle_group_weights")
      .select("muscle_group, weight")
      .eq("exercise_key", ex.exercise_key)
      .eq("gym_id", gymId);

    for (const w of weights ?? []) {
      const mgXp = Math.round(exerciseXp * (w.weight as number));
      if (mgXp <= 0) continue;
      events.push({
        gym_id: gymId,
        user_id: user.id,
        axis: "muscle_group",
        xp_amount: mgXp,
        source_type: "session_exercise",
        source_id: ex.id,
        idempotency_key: `muscle_group:${w.muscle_group}:session_exercise:${ex.id}`,
        exercise_key: ex.exercise_key,
        muscle_group: w.muscle_group,
        occurred_at: body.finished_at,
      });
    }
  }

  // ── Insert XP events ─────────────────────────────────────────────────────────
  //
  // Aggregate recomputation is handled automatically by the DB trigger
  // on xp_events (migration 00021). No explicit RPC call needed.

  const { error: xpErr } = await supabase
    .from("xp_events")
    .upsert(events, { onConflict: "idempotency_key", ignoreDuplicates: true });

  if (xpErr) {
    console.error("[finish-session] XP insert failed:", xpErr);
    return jsonResponse({ error: "XP processing failed" }, 500);
  }

  return jsonResponse({
    ok: true,
    session_id: body.session_id,
    xp_events: events.length,
  }, 200);
});

// ─── Helper ───────────────────────────────────────────────────────────────────

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
