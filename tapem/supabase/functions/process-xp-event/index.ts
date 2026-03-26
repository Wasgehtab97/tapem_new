// =============================================================================
// Tap'em — XP Event Processor Edge Function
// Privileged write: runs with service-role, validates and persists XP events.
// Idempotent: duplicate idempotency_key is silently ignored (200 OK).
// =============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Types ───────────────────────────────────────────────────────────────────

type XpAxis = "training_day" | "exercise_equipment" | "muscle_group";

interface ProcessXpRequest {
  requestId: string;        // client-generated UUID for audit
  gymId: string;
  userId: string;
  sessionId: string;
  sessionDayAnchor: string; // yyyy-MM-dd
  exercises: SessionExerciseSummary[];
}

interface SessionExerciseSummary {
  sessionExerciseId: string;
  exerciseKey: string;
  sets: SetSummary[];
}

interface SetSummary {
  setEntryId: string;
  reps?: number;
  durationSeconds?: number; // cardio
  isCardio: boolean;
}

// ─── XP Calculation (mirrors AppConfig constants) ─────────────────────────────

const XP_TRAINING_DAY = 25;
const XP_PER_SET_BASE = 5;
const XP_EXERCISE_CAP = 120;

function calcExerciseXp(sets: SetSummary[]): number {
  let total = 0;
  for (const set of sets) {
    const reps = set.reps ?? 0;
    const raw = set.isCardio ? XP_PER_SET_BASE : XP_PER_SET_BASE + Math.floor(reps / 5);
    total += raw;
  }
  return Math.min(total, XP_EXERCISE_CAP);
}

// ─── Handler ──────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  // Verify calling user
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body: ProcessXpRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Validate caller is the session owner
  if (body.userId !== user.id) {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Validate membership
  const { data: membership } = await supabase
    .from("memberships")
    .select("id")
    .eq("user_id", user.id)
    .eq("gym_id", body.gymId)
    .eq("is_active", true)
    .maybeSingle();

  if (!membership) {
    return new Response(JSON.stringify({ error: "No active membership" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  const events: {
    gym_id: string;
    user_id: string;
    axis: XpAxis;
    xp_amount: number;
    source_type: string;
    source_id: string;
    idempotency_key: string;
    exercise_key?: string;
    muscle_group?: string;
    occurred_at: string;
  }[] = [];

  // 1. training_day XP — 100 XP once per session_day_anchor per gym
  const trainingDayKey = `training_day:workout_session:${body.gymId}:${body.userId}:${body.sessionDayAnchor}`;
  events.push({
    gym_id: body.gymId,
    user_id: body.userId,
    axis: "training_day",
    xp_amount: XP_TRAINING_DAY,
    source_type: "workout_session",
    source_id: body.sessionId,
    idempotency_key: trainingDayKey,
    occurred_at: new Date().toISOString(),
  });

  // 2. exercise_equipment XP + 3. muscle_group XP
  for (const exercise of body.exercises) {
    const exerciseXp = calcExerciseXp(exercise.sets);

    if (exerciseXp > 0) {
      events.push({
        gym_id: body.gymId,
        user_id: body.userId,
        axis: "exercise_equipment",
        xp_amount: exerciseXp,
        source_type: "session_exercise",
        source_id: exercise.sessionExerciseId,
        idempotency_key: `exercise_equipment:session_exercise:${exercise.sessionExerciseId}`,
        exercise_key: exercise.exerciseKey,
        occurred_at: new Date().toISOString(),
      });

      // muscle_group XP from exercise template weights
      const { data: weights } = await supabase
        .from("muscle_group_weights")
        .select("muscle_group, weight")
        .eq("exercise_key", exercise.exerciseKey)
        .eq("gym_id", body.gymId);

      for (const w of weights ?? []) {
        const mgXp = Math.round(exerciseXp * w.weight);
        if (mgXp > 0) {
          events.push({
            gym_id: body.gymId,
            user_id: body.userId,
            axis: "muscle_group",
            xp_amount: mgXp,
            source_type: "session_exercise",
            source_id: exercise.sessionExerciseId,
            idempotency_key: `muscle_group:${w.muscle_group}:session_exercise:${exercise.sessionExerciseId}`,
            exercise_key: exercise.exerciseKey,
            muscle_group: w.muscle_group,
            occurred_at: new Date().toISOString(),
          });
        }
      }
    }
  }

  // Upsert events — ON CONFLICT (idempotency_key) DO NOTHING
  const { error: insertError } = await supabase
    .from("xp_events")
    .upsert(events, { onConflict: "idempotency_key", ignoreDuplicates: true });

  if (insertError) {
    console.error("XP insert error:", insertError);
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Recompute user_gym_xp totals (service role — bypasses RLS)
  await supabase.rpc("recompute_user_gym_xp", {
    p_user_id: body.userId,
    p_gym_id: body.gymId,
  });

  return new Response(
    JSON.stringify({
      ok: true,
      requestId: body.requestId,
      eventsProcessed: events.length,
    }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    }
  );
});
