#!/usr/bin/env bash
set -Eeuo pipefail

require_env() {
  local key="$1"
  if [[ -z "${!key:-}" ]]; then
    echo "ERROR: missing required env var: ${key}" >&2
    exit 1
  fi
}

to_int() {
  local value="${1:-0}"
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s' "$value"
  else
    printf '0'
  fi
}

append_summary() {
  local text="$1"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
      printf '%s\n' "$text"
    } >>"$GITHUB_STEP_SUMMARY"
  fi
}

API_BASE="${SUPABASE_MANAGEMENT_API_BASE:-https://api.supabase.com}"
INTERVAL="${SUPABASE_USAGE_INTERVAL:-1day}"

require_env "SUPABASE_PROJECT_REF"
require_env "SUPABASE_ACCESS_TOKEN"

WARN_TOTAL="$(to_int "${SUPABASE_ALERT_WARN_TOTAL_REQUESTS:-25000}")"
CRIT_TOTAL="$(to_int "${SUPABASE_ALERT_CRIT_TOTAL_REQUESTS:-50000}")"
WARN_REST="$(to_int "${SUPABASE_ALERT_WARN_REST_REQUESTS:-20000}")"
CRIT_REST="$(to_int "${SUPABASE_ALERT_CRIT_REST_REQUESTS:-40000}")"
STRICT_WARN_FAIL="${SUPABASE_ALERT_STRICT_WARN_FAIL:-false}"
SEND_OK="${SUPABASE_ALERT_SEND_OK:-false}"
WEBHOOK_URL="${SUPABASE_USAGE_ALERT_WEBHOOK_URL:-}"

if (( WARN_TOTAL > CRIT_TOTAL )); then
  echo "ERROR: WARN_TOTAL must be <= CRIT_TOTAL" >&2
  exit 1
fi

if (( WARN_REST > CRIT_REST )); then
  echo "ERROR: WARN_REST must be <= CRIT_REST" >&2
  exit 1
fi

tmp_body="$(mktemp)"
http_code="$(
  curl -sS \
    -o "$tmp_body" \
    -w "%{http_code}" \
    -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
    -H "Accept: application/json" \
    "${API_BASE}/v1/projects/${SUPABASE_PROJECT_REF}/analytics/endpoints/usage.api-counts?interval=${INTERVAL}"
)"

if [[ ! "$http_code" =~ ^2 ]]; then
  echo "ERROR: Supabase API request failed (HTTP ${http_code})" >&2
  cat "$tmp_body" >&2
  rm -f "$tmp_body"
  exit 1
fi

if ! jq -e '.result | type == "array" and length > 0' "$tmp_body" >/dev/null; then
  echo "ERROR: Supabase usage response has no data points." >&2
  cat "$tmp_body" >&2
  rm -f "$tmp_body"
  exit 1
fi

latest_json="$(jq -c '.result[-1]' "$tmp_body")"
rm -f "$tmp_body"

timestamp="$(jq -r '.timestamp // "unknown"' <<<"$latest_json")"
auth_requests="$(jq -r '.total_auth_requests // 0 | floor' <<<"$latest_json")"
realtime_requests="$(jq -r '.total_realtime_requests // 0 | floor' <<<"$latest_json")"
rest_requests="$(jq -r '.total_rest_requests // 0 | floor' <<<"$latest_json")"
storage_requests="$(jq -r '.total_storage_requests // 0 | floor' <<<"$latest_json")"
total_requests="$((auth_requests + realtime_requests + rest_requests + storage_requests))"

severity="ok"
reason="within configured thresholds"

if (( total_requests >= CRIT_TOTAL || rest_requests >= CRIT_REST )); then
  severity="critical"
  reason="critical threshold exceeded"
elif (( total_requests >= WARN_TOTAL || rest_requests >= WARN_REST )); then
  severity="warning"
  reason="warning threshold exceeded"
fi

message="[$severity] Supabase usage proxy for ${SUPABASE_PROJECT_REF} at ${timestamp}: total=${total_requests}, rest=${rest_requests}, auth=${auth_requests}, realtime=${realtime_requests}, storage=${storage_requests} (${reason})"

printf '%s\n' "$message"

append_summary "## Supabase Usage Alert"
append_summary ""
append_summary "- Project: \`${SUPABASE_PROJECT_REF}\`"
append_summary "- Timestamp (API): \`${timestamp}\`"
append_summary "- Severity: \`${severity}\`"
append_summary "- Note: this checks request volume (`usage.api-counts`) as early-warning proxy."
append_summary ""
append_summary "| Metric | Value | Warn | Crit |"
append_summary "|---|---:|---:|---:|"
append_summary "| Total API requests | ${total_requests} | ${WARN_TOTAL} | ${CRIT_TOTAL} |"
append_summary "| REST requests | ${rest_requests} | ${WARN_REST} | ${CRIT_REST} |"
append_summary "| Auth requests | ${auth_requests} | - | - |"
append_summary "| Realtime requests | ${realtime_requests} | - | - |"
append_summary "| Storage requests | ${storage_requests} | - | - |"

should_notify="false"
if [[ "$severity" != "ok" ]]; then
  should_notify="true"
elif [[ "$SEND_OK" == "true" ]]; then
  should_notify="true"
fi

if [[ -n "$WEBHOOK_URL" && "$should_notify" == "true" ]]; then
  payload="$(
    jq -n \
      --arg text "$message" \
      '{text:$text,content:$text}'
  )"
  curl -sS -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$WEBHOOK_URL" >/dev/null
fi

if [[ "$severity" == "critical" ]]; then
  echo "::error::${message}"
  exit 2
fi

if [[ "$severity" == "warning" ]]; then
  echo "::warning::${message}"
  if [[ "$STRICT_WARN_FAIL" == "true" ]]; then
    exit 3
  fi
fi

