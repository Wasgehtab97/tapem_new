# Contributing

> Status: Finalisiert fuer V1-Buildstart
> Stand: 2026-03-18
> Geltung: Verbindliche Arbeitsgrundlage


## Branching
- Default branch: `main`
- Feature branches: `feat/<short-name>`
- Fix branches: `fix/<short-name>`
- Docs branches: `docs/<short-name>`
- Experimental work that is not merge-ready must stay outside `main`.

## Commit Style
- Use concise, imperative commit messages.
- Prefix recommendation: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`.

## Pull Requests
- Keep PRs focused and small.
- Include context, risk assessment, and rollback notes.
- Link affected acceptance criteria from `14_ACCEPTANCE_CRITERIA.md` when relevant.
- If no `AC-*` mapping is needed, explain explicitly why.

## Technology Baseline
- Mobile-Frontend changes target Flutter (Dart) code paths.
- Backend changes follow the Supabase-first architecture.

## AI-Assisted Development
- AI-generated changes require the same review quality as human-written changes.
- Every PR must document assumptions, risks, and validation evidence.
- Security-relevant changes need explicit reviewer attention in PR notes.

## Quality Gate
- CI must be green before merge.
- No secrets, keys, or credentials in commits.
- Security- oder data-relevante PRs require at least one reviewer with domain ownership.
