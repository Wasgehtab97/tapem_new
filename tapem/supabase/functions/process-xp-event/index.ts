// =============================================================================
// Tap'em — XP Event Processor Edge Function
// Privileged write: runs with service-role, validates and persists XP events.
// Idempotent: duplicate idempotency_key is silently ignored (200 OK).
//
// Muscle group XP model (v2):
//   Flat rate per exercise per muscle group — independent of set count or reps.
//   primary   → 10.0 XP  (XP_MG_PRIMARY)
//   secondary →  2.5 XP  (XP_MG_SECONDARY)
// =============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  XP_TRAINING_DAY,
  XP_MG_PRIMARY,
  XP_MG_SECONDARY,
  calcVariableExerciseXpFromSummary,
} from "../_shared/xp.ts";

// ─── Types ───────────────────────────────────────────────────────────────────

type XpAxis = "training_day" | "exercise_equipment" | "muscle_group";

interface ProcessXpRequest {
  requestId: string;
  gymId: string;
  userId: string;
  sessionId: string;
  sessionDayAnchor: string; // yyyy-MM-dd
  exercises: SessionExerciseSummary[];
}

interface SessionExerciseSummary {
  sessionExerciseId: string;
  exerciseKey: string;
  customExerciseId?: string | null;
  sets: SetSummary[];
  /** Optional muscle groups from the Flutter client (custom exercises). */
  customMuscleGroups?: Array<{ muscleGroup: string; role: "primary" | "secondary" }>;
}

interface SetSummary {
  setEntryId: string;
  reps?: number;
  durationSeconds?: number;
  isCardio: boolean;
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
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let body: ProcessXpRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }

  if (body.userId !== user.id) {
    return jsonResponse({ error: "Forbidden" }, 403);
  }

  const { data: membership } = await supabase
    .from("memberships")
    .select("id")
    .eq("user_id", user.id)
    .eq("gym_id", body.gymId)
    .eq("is_active", true)
    .maybeSingle();

  if (!membership) {
    return jsonResponse({ error: "No active membership" }, 403);
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

  // 1. training_day XP
  events.push({
    gym_id: body.gymId,
    user_id: body.userId,
    axis: "training_day",
    xp_amount: XP_TRAINING_DAY,
    source_type: "workout_session",
    source_id: body.sessionId,
    idempotency_key: `training_day:workout_session:${body.gymId}:${body.userId}:${body.sessionDayAnchor}`,
    occurred_at: new Date().toISOString(),
  });

  // 2. exercise_equipment XP + 3. muscle_group XP
  for (const exercise of body.exercises) {
    if (exercise.sets.length === 0) continue;

    const exerciseXp = calcVariableExerciseXpFromSummary(exercise.sets);
    if (exerciseXp <= 0) continue;

    const isCardio = exercise.exerciseKey.startsWith("cardio:");

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

    if (isCardio) continue;

    // ── Resolve muscle group assignments ──────────────────────────────────────

    let mgRows: Array<{ muscle_group: string; role: string }> = [];

    if (exercise.customMuscleGroups?.length) {
      mgRows = exercise.customMuscleGroups.map((mg) => ({
        muscle_group: mg.muscleGroup,
        role: mg.role,
      }));
    } else if (exercise.customExerciseId) {
      const { data } = await supabase
        .from("user_custom_exercise_muscle_groups")
        .select("muscle_group, role")
        .eq("user_custom_exercise_id", exercise.customExerciseId);
      mgRows = data ?? [];
    }

    if (mgRows.length === 0 && !exercise.exerciseKey.startsWith("custom:")) {
      const { data } = await supabase
        .from("exercise_muscle_groups")
        .select("muscle_group, role")
        .eq("exercise_key", exercise.exerciseKey)
        .eq("gym_id", body.gymId);
      mgRows = data ?? [];
    }

    for (const mg of mgRows) {
      const xpAmount = mg.role === "primary" ? XP_MG_PRIMARY : XP_MG_SECONDARY;
      events.push({
        gym_id: body.gymId,
        user_id: body.userId,
        axis: "muscle_group",
        xp_amount: xpAmount,
        source_type: "session_exercise",
        source_id: exercise.sessionExerciseId,
        idempotency_key: `mg:${mg.muscle_group}:${mg.role}:se:${exercise.sessionExerciseId}`,
        exercise_key: exercise.exerciseKey,
        muscle_group: mg.muscle_group,
        occurred_at: new Date().toISOString(),
      });
    }
  }

  const { error: insertError } = await supabase
    .from("xp_events")
    .upsert(events, { onConflict: "idempotency_key", ignoreDuplicates: true });

  if (insertError) {
    console.error("[process-xp-event] insert error:", insertError);
    return jsonResponse({ error: "Internal error" }, 500);
  }

  await supabase.rpc("recompute_user_gym_xp", {
    p_user_id: body.userId,
    p_gym_id: body.gymId,
  });

  return jsonResponse({
    ok: true,
    requestId: body.requestId,
    eventsProcessed: events.length,
  }, 200);
});

// ─── Helper ───────────────────────────────────────────────────────────────────

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
