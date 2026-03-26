# Security Policy

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


## Supported Versions
Security fixes are applied on `main`.

## Reporting a Vulnerability
- Do not open public issues for security vulnerabilities.
- Report privately via GitHub Security Advisories if enabled.
- If advisories are unavailable, contact repository owner directly and include:
  - impact
  - reproduction steps
  - affected files/areas
  - suggested mitigation
- Include whether tenant isolation, authentication, or privilege boundaries are affected.

## Severity Guidance
- Include estimated severity (`low`, `medium`, `high`, `critical`) in reports.
- Include exploitability and potential data impact.
- If tenant isolation could be affected, treat as `critical` by default.

## Response Targets
- Initial triage: within 72 hours
- Status update: within 7 days
- Critical findings that risk tenant isolation must be escalated immediately.
