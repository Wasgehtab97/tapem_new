# Supabase Usage Alerting

This repository includes an automated usage alert job:

- Workflow: `.github/workflows/supabase-usage-alert.yml`
- Script: `scripts/monitor/supabase_usage_alert.sh`

## What this checks

The script calls the official Supabase Management API endpoint:

- `GET /v1/projects/{ref}/analytics/endpoints/usage.api-counts`

It evaluates the latest data point and alerts on:

- Total API requests (`auth + realtime + rest + storage`)
- REST requests (PostgREST proxy signal)

## Important limitation

As of April 4, 2026, the public Management API exposes request-count usage metrics,
but not direct egress byte totals. This alarm is therefore an early-warning proxy,
not the final source of truth for billing egress.

Keep Supabase billing emails and the Usage Dashboard as the canonical quota source.

## How you get alerted

1. If a webhook URL is configured, the script posts a message immediately.
2. On critical threshold breach, the workflow fails (`exit != 0`).
3. Failed scheduled workflows can trigger GitHub email/in-app notifications (depending on your GitHub notification settings).
4. Every run writes a structured summary to the GitHub Actions run page.

## Required GitHub secrets

- `SUPABASE_PROJECT_REF` (your project ref, e.g. `abcdefghijklmnopqrst`)
- `SUPABASE_ACCESS_TOKEN` (Supabase Personal Access Token with access to project analytics)

Optional:

- `SUPABASE_USAGE_ALERT_WEBHOOK_URL` (Slack/Discord-compatible webhook)

## Optional GitHub repository variables

- `SUPABASE_ALERT_WARN_TOTAL_REQUESTS` (default: `25000`)
- `SUPABASE_ALERT_CRIT_TOTAL_REQUESTS` (default: `50000`)
- `SUPABASE_ALERT_WARN_REST_REQUESTS` (default: `20000`)
- `SUPABASE_ALERT_CRIT_REST_REQUESTS` (default: `40000`)
- `SUPABASE_ALERT_STRICT_WARN_FAIL` (`true|false`, default: `false`)
- `SUPABASE_ALERT_SEND_OK` (`true|false`, default: `false`)
- `SUPABASE_USAGE_INTERVAL` (default: `1day`)

## Local test

```bash
cd tapem
export SUPABASE_PROJECT_REF=abcdefghijklmnopqrst
export SUPABASE_ACCESS_TOKEN=sbp_...
make supabase-usage-check
```
