---
name: web-search
description: 'Search the web using DuckDuckGo to find information, documentation, articles, or answers. Use proactively when local knowledge is insufficient, information may be outdated, or the task requires researching a topic, library, API, error message, or current event. Triggers: "search for", "look up", "find online", "google", "what is", "how do I", "latest version", "web search".'
---

# Web Search

Run a DuckDuckGo search to gather context needed to answer a question or complete a task.

## Command

Run the script with your query (quote it). Resolve the path relative to this skill file:

```bash
"$(dirname SKILL.md)/web-search.py" "QUERY"
```

In practice, invoke it with the skill directory path, e.g.:

```bash
/Users/p901vln/.agents/skills/web-search/web-search.py "rust async runtime comparison"
```

Output is a clean numbered list — each result has a title, the real destination
URL (already decoded, ready for `WebFetch`), and a snippet.

### Options

- `--max N` — limit number of results (default 8).
- `--json` — emit structured JSON (`[{title, url, snippet}, ...]`) for programmatic use.

### Exit codes

- `0` — results printed.
- `2` — DuckDuckGo served an anti-bot CAPTCHA page. This is **not** "no results";
  it usually means too many requests in a short window. Wait ~30–60s and retry,
  or slow down between searches.
- `3` — no results found (try a different / more specific query).
- `4` — network or HTTP error.

## Rules

- Use results as context to inform your response — do not present raw output unless the user asks.
- Prefer specific queries. Refine and retry if the first results are not relevant.
- Follow up with `WebFetch` on promising URLs to get full page content.
- Avoid firing many searches in rapid succession; space them out to avoid the CAPTCHA (exit code 2).

## Fallback (no Python available)

If the script can't run, use this raw pipeline (requires `curl` + `pandoc`). Note
it leaves URLs as DuckDuckGo redirect links and returns empty output for both
"no results" and "blocked":

```bash
curl -s -G 'https://lite.duckduckgo.com/lite/' --url-query 'q=QUERY' \
  -H 'accept: text/html' \
  -H 'accept-language: en-US,en' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36 Edg/149.0.0.0' \
  | pandoc -f html -t markdown | grep -E '^\|.*\w' | sed 's/  //g'
```
