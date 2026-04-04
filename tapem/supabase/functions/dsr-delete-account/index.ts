import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface DeleteAccountRequest {
  confirmation_text?: string;
}

serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method Not Allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Unauthorized", code: "missing_auth_header" }, 401);
  }

  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return jsonResponse({ error: "Unauthorized", code: "invalid_token" }, 401);
  }

  let body: DeleteAccountRequest = {};
  try {
    body = await req.json();
  } catch {
    // Empty JSON body is allowed as long as confirmation is provided by caller.
  }

  const confirmation = body.confirmation_text?.trim().toUpperCase();
  if (confirmation !== "DELETE") {
    return jsonResponse(
      {
        error: "Account deletion requires explicit confirmation text DELETE.",
        code: "missing_delete_confirmation",
      },
      400,
    );
  }

  const requestId = crypto.randomUUID();
  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Best-effort cleanup for user-scoped storage objects before auth deletion.
  await cleanupUserStorage(serviceClient, "avatars", user.id);
  await cleanupUserStorage(serviceClient, "user-exports", user.id);

  const { error: deleteError } = await serviceClient.auth.admin.deleteUser(user.id);
  if (deleteError) {
    console.error("[dsr-delete-account] auth.admin.deleteUser failed:", deleteError);
    return jsonResponse(
      {
        error: "Account deletion failed on auth backend.",
        code: "auth_delete_failed",
      },
      500,
    );
  }

  return jsonResponse(
    {
      ok: true,
      request_id: requestId,
      deleted_user_id: user.id,
      deleted_at: new Date().toISOString(),
    },
    200,
  );
});

async function cleanupUserStorage(
  // deno-lint-ignore no-explicit-any
  client: any,
  bucket: string,
  userId: string,
): Promise<void> {
  const pageSize = 100;
  let offset = 0;

  for (;;) {
    const { data: entries, error: listError } = await client.storage
      .from(bucket)
      .list(userId, { limit: pageSize, offset });

    if (listError) {
      console.warn(`[dsr-delete-account] storage list failed (${bucket}):`, listError.message);
      return;
    }

    if (!entries || entries.length === 0) return;

    const filePaths = entries
      .filter((entry: { id?: string | null; name?: string | null }) =>
        entry.id != null && entry.name != null
      )
      .map((entry: { name: string }) => `${userId}/${entry.name}`);

    if (filePaths.length > 0) {
      const { error: removeError } = await client.storage
        .from(bucket)
        .remove(filePaths);
      if (removeError) {
        console.warn(`[dsr-delete-account] storage remove failed (${bucket}):`, removeError.message);
        return;
      }
    }

    if (entries.length < pageSize) return;
    offset += pageSize;
  }
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
