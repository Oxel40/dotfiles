---
name: jira
description: 'Fetch and inspect JIRA (Server/Data Center) issues. Use when the user provides a JIRA ticket as a URL (.../browse/KEY-123) or a bare key/number (KEY-123), or asks to "read this jira", "look up ticket", "show issue", "fetch jira", "get the comments on", or run a JQL search. Configured via the JIRA_BASE_URL and JIRA_TOKEN env vars.'
---

# JIRA

Fetch issues, comments, attachments, and run JQL searches against
the JIRA instance at `$JIRA_BASE_URL` using the `JIRA_TOKEN` env var (bearer auth).

## Setup

All calls require two env vars:

- `JIRA_BASE_URL` — https base URL, e.g. `https://jira.example.com`
- `JIRA_TOKEN` — a personal access token (sent as a Bearer token)

Optional: `JIRA_DEFAULT_PROJECT` (see below). Verify first:

```bash
test -n "$JIRA_BASE_URL" -a -n "$JIRA_TOKEN" && echo ok || echo "JIRA_BASE_URL/JIRA_TOKEN not set"
```

If either is missing, ask the user to export it; do not proceed.

## The helper script

Use `jira.sh` in this skill directory for all operations. It handles auth,
URL/key normalization, and clean output.

```bash
# Accepts a full URL, a bare key, or just digits with a default project.
"$(dirname SKILL.md)/jira.sh" issue PROJ-123
"$(dirname SKILL.md)/jira.sh" issue "$JIRA_BASE_URL/browse/PROJ-123"
```

Resolve the script path against this skill's directory and call it with an
absolute path, e.g.:

```bash
JIRA="<this skill dir>/jira.sh"
"$JIRA" issue PROJ-123
```

## Commands

| Command | What it does |
|---------|--------------|
| `jira.sh issue <key\|url>` | Core fields: summary, type, status, priority, assignee, reporter, dates, description |
| `jira.sh full <key\|url>` | Same as `issue` plus comments and rendered description |
| `jira.sh comments <key\|url>` | Just the comments (author + body + timestamp) |
| `jira.sh attachments <key\|url>` | List attachments with filenames and download URLs |
| `jira.sh download <key\|url> [dir]` | Download all attachments (default dir: `./jira-<key>`) |
| `jira.sh raw <key\|url>` | Full raw JSON (all fields) for digging into anything else |
| `jira.sh search '<JQL>'` | Run a JQL query, list matching keys + summaries |

## Input normalization

The script accepts any of these and resolves to the issue key:

- `$JIRA_BASE_URL/browse/PROJ-123` (URL)
- `PROJ-123` (bare key)
- `123` — only with an explicit project via `JIRA_DEFAULT_PROJECT`, e.g.
  `JIRA_DEFAULT_PROJECT=PROJ jira.sh issue 123`. If no default project is
  set and only digits are given, ask the user which project.

## Rules

- Present a concise summary (table for metadata), not raw JSON, unless the user
  asks for raw output.
- For images/screenshots referenced in a description (e.g.
  `!image-...-.png!`), use `download` to fetch them, then `read` them.
- Use the returned `Pipeline build` / linked URLs as leads when diagnosing.
- Never print the token.
