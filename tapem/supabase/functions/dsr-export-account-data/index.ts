import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

  const requestId = crypto.randomUUID();

  const { data: exportPayload, error: exportError } = await userClient.rpc(
    "get_my_account_data_export",
  );

  if (exportError || !exportPayload) {
    console.error("[dsr-export-account-data] export rpc failed:", exportError);
    return jsonResponse(
      { error: "Could not create data export.", code: "export_rpc_failed" },
      500,
    );
  }

  const envelope = {
    request_id: requestId,
    exported_at: new Date().toISOString(),
    user_id: user.id,
    source: "tapem",
    data: exportPayload,
  };

  const jsonText = JSON.stringify(envelope, null, 2);
  const fileName = `export_${new Date().toISOString().replace(/[:.]/g, "-")}.json`;
  const filePath = `${user.id}/${fileName}`;

  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { error: uploadError } = await serviceClient.storage
    .from("user-exports")
    .upload(
      filePath,
      new Blob([jsonText], { type: "application/json" }),
      {
        upsert: true,
        contentType: "application/json",
      },
    );

  if (uploadError) {
    console.error("[dsr-export-account-data] upload failed:", uploadError);
    return jsonResponse(
      { error: "Could not persist export file.", code: "upload_failed" },
      500,
    );
  }

  const expiresInSeconds = 60 * 60;
  const { data: signed, error: signedError } = await serviceClient.storage
    .from("user-exports")
    .createSignedUrl(filePath, expiresInSeconds);

  if (signedError || !signed?.signedUrl) {
    console.error("[dsr-export-account-data] sign url failed:", signedError);
    return jsonResponse(
      { error: "Could not create signed export URL.", code: "signed_url_failed" },
      500,
    );
  }

  return jsonResponse(
    {
      ok: true,
      request_id: requestId,
      download_url: toAbsoluteSignedUrl(signed.signedUrl),
      expires_in_seconds: expiresInSeconds,
      file_path: filePath,
      file_size_bytes: new TextEncoder().encode(jsonText).length,
      estimated_rows: estimateRows(exportPayload),
    },
    200,
  );
});

function estimateRows(payload: unknown): number {
  if (typeof payload !== "object" || payload === null) return 0;
  let count = 0;
  for (const value of Object.values(payload as Record<string, unknown>)) {
    if (Array.isArray(value)) count += value.length;
    else if (value && typeof value === "object") count += 1;
  }
  return count;
}

function toAbsoluteSignedUrl(url: string): string {
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  if (url.startsWith("/")) {
    return `${supabaseUrl}${url}`;
  }
  return `${supabaseUrl}/storage/v1/${url}`;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
