// =============================================================================
// Tap'em — Finish Session Edge Function
//
// Marks a workout session as finished and inserts XP events for it.
// Called when the user ends a session that was already synced to Postgres.
//
// Muscle group XP model (v2):
//   Flat rate per exercise per muscle group — independent of set count or reps.
//   primary   → 10.0 XP  (XP_MG_PRIMARY)
//   secondary →  2.5 XP  (XP_MG_SECONDARY)
//
// Error contract:
//   200 — session finished; XP inserted (or skipped if no exercises with sets)
//   400 — malformed request
//   401 — missing or invalid JWT
//   403 — caller is not the session owner
//   404 — session not found
//   500 — DB write failure
// =============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  XP_TRAINING_DAY,
  XP_MG_PRIMARY,
  XP_MG_SECONDARY,
  calcVariableExerciseXp,
} from "../_shared/xp.ts";

interface FinishSessionRequest {
  session_id: string;
  gym_id: string;
  // finished_at is intentionally absent — the server stamps it with now()
  // to prevent clients from backdating session completion timestamps.
}

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

  // Server-authoritative finish timestamp — not accepted from the client.
  const finishedAt = new Date().toISOString();

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
    .update({ finished_at: finishedAt })
    .eq("id", body.session_id);

  if (updateErr) {
    console.error("[finish-session] failed to update session:", updateErr);
    return jsonResponse({ error: "Failed to finish session" }, 500);
  }

  // ── Fetch exercises + sets for XP computation ────────────────────────────────

  const { data: exercises } = await supabase
    .from("session_exercises")
    .select("id, exercise_key, custom_exercise_id, set_entries(id, reps, duration_seconds)")
    .eq("session_id", body.session_id);

  if (!exercises || exercises.length === 0) {
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
      occurred_at: finishedAt,
    },
  ];

  for (const ex of exercises) {
    const sets = (ex.set_entries as Array<{
      id: string;
      reps: number | null;
      duration_seconds: number | null;
    }>) ?? [];

    if (sets.length === 0) continue;

    const exerciseXp = calcVariableExerciseXp(sets);
    if (exerciseXp <= 0) continue;

    const isCardio = (ex.exercise_key as string).startsWith("cardio:");

    events.push({
      gym_id: gymId,
      user_id: user.id,
      axis: "exercise_equipment",
      xp_amount: exerciseXp,
      source_type: "session_exercise",
      source_id: ex.id,
      idempotency_key: `exercise_equipment:session_exercise:${ex.id}`,
      exercise_key: ex.exercise_key,
      equipment_id: (session.equipment_id as string | null) ?? null,
      occurred_at: finishedAt,
    });

    if (isCardio) continue;

    // ── Muscle group XP (flat rate v2) ────────────────────────────────────────

    let mgRows: Array<{ muscle_group: string; role: string }> = [];

    if (ex.custom_exercise_id) {
      const { data } = await supabase
        .from("user_custom_exercise_muscle_groups")
        .select("muscle_group, role")
        .eq("user_custom_exercise_id", ex.custom_exercise_id);
      mgRows = data ?? [];
    }

    if (mgRows.length === 0 && ex.exercise_key && !(ex.exercise_key as string).startsWith("custom:")) {
      const { data } = await supabase
        .from("exercise_muscle_groups")
        .select("muscle_group, role")
        .eq("exercise_key", ex.exercise_key)
        .eq("gym_id", gymId);
      mgRows = data ?? [];
    }

    for (const mg of mgRows) {
      const xpAmount = mg.role === "primary" ? XP_MG_PRIMARY : XP_MG_SECONDARY;
      events.push({
        gym_id: gymId,
        user_id: user.id,
        axis: "muscle_group",
        xp_amount: xpAmount,
        source_type: "session_exercise",
        source_id: ex.id,
        idempotency_key: `mg:${mg.muscle_group}:${mg.role}:se:${ex.id}`,
        exercise_key: ex.exercise_key,
        muscle_group: mg.muscle_group,
        occurred_at: finishedAt,
      });
    }
  }

  // ── Insert XP events ─────────────────────────────────────────────────────────

  const { error: xpErr } = await supabase
    .from("xp_events")
    .upsert(events, { onConflict: "idempotency_key", ignoreDuplicates: true });

  if (xpErr) {
    console.error("[finish-session] XP insert failed:", xpErr);
    return jsonResponse({ error: "XP processing failed" }, 500);
  }

  // Best-effort recompute: derived leaderboard cache should never block
  // canonical session + XP persistence.
  const { error: perfErr } = await supabase.rpc(
    "recompute_machine_performance_for_session",
    { p_session_id: body.session_id },
  );
  if (perfErr) {
    console.warn("[finish-session] machine performance recompute failed:", perfErr.message);
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
