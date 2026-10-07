#!/usr/bin/env bash
# Read-only Confluence helper. Requires curl, jq, and CONFLUENCE_TOKEN.
set -euo pipefail

BASE="https://wiki.swedbank.net"
MAX_PAGES=500
count=0
incomplete=0
capped=0

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

normalize_id() {
  local input="$1" id pattern
  pattern='^https://wiki\.swedbank\.net/spaces/[^/?#]+/pages/([0-9]+)([/?#].*)?$'
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    id="$input"
  elif [[ "$input" =~ $pattern ]]; then
    id="${BASH_REMATCH[1]}"
  elif [[ "$input" == "$BASE/pages/viewpage.action?"* ]]; then
    input="${input#*\?}"
    input="${input%%#*}"
    if [[ "$input" =~ (^|\&)pageId=([0-9]+)(\&|$) ]]; then
      id="${BASH_REMATCH[2]}"
    else
      die "URL has no numeric pageId"
    fi
  else
    die "expected a page ID or a wiki.swedbank.net page URL"
  fi
  [[ "$id" =~ ^[1-9][0-9]*$ ]] || die "invalid page ID"
  printf '%s' "$id"
}

api() {
  local json
  # Disable curlrc and redirects; the token is sent only to this fixed host.
  json="$(printf 'Authorization: Bearer %s\n' "$CONFLUENCE_TOKEN" |
    curl -q --fail --silent --show-error --connect-timeout 10 --max-time 60 \
      --header @- --header 'Accept: application/json' "$BASE/rest/api/content/$1")" ||
    die "Confluence request failed; check VPN, token, and page permissions"
  printf '%s' "$json" | jq -e 'type == "object"' >/dev/null ||
    die "expected JSON from Confluence, not a login page or redirect"
  printf '%s' "$json"
}

page() {
  local json
  json="$(api "$1?expand=body.view,body.storage,space,version,ancestors")" || return 1
  printf '%s' "$json" | jq -e --arg id "$1" '
    .id == $id and .type == "page" and (.title | type == "string")
  ' >/dev/null || die "response is not the requested page"
  printf '%s' "$json"
}

walk() {
  local parent="$1" level="$2" start=0 json size id title
  while :; do
    json="$(api "$parent/child/page?limit=100&start=$start")"
    printf '%s' "$json" | jq -e '
      (.results | type == "array") and
      all(.results[]; (.id | type == "string" and test("^[1-9][0-9]*$"))
        and (.title | type == "string"))
    ' >/dev/null || die "invalid child-page response"
    size="$(printf '%s' "$json" | jq '.results | length')"
    if [[ "$command" == tree ]] && (( level > depth && size > 0 )); then
      printf 'Incomplete: depth limit %s reached below page %s.\n' "$depth" "$parent" >&2
      incomplete=1
      return
    fi
    while IFS=$'\t' read -r id title; do
      if (( count >= MAX_PAGES )); then
        printf 'Incomplete: page limit %s reached.\n' "$MAX_PAGES" >&2
        incomplete=1
        capped=1
        return
      fi
      if [[ "$seen" == *"|$id|"* ]]; then
        die "duplicate page $id in hierarchy; refusing to loop"
      fi
      seen="$seen$id|"
      count=$((count + 1))
      printf '%*s%s  %s  %s/pages/viewpage.action?pageId=%s\n' \
        "$((level * 2))" '' "$id" "$title" "$BASE" "$id"
      if [[ "$command" == tree ]]; then
        walk "$id" "$((level + 1))"
        (( capped == 0 )) || return 0
      fi
    done < <(printf '%s' "$json" | jq -r '.results[] | [.id, .title] | @tsv')
    [[ "$(printf '%s' "$json" | jq -r '._links.next // empty')" != '' ]] || break
    (( size > 0 )) || die "pagination made no progress"
    start=$((start + size))
  done
}

command="${1:---help}"
if [[ "$command" == --help || "$command" == -h ]]; then
  printf '%s\n' \
    'confluence.sh page <url|id>                 Metadata and rendered HTML' \
    'confluence.sh children <url|id>             Immediate child pages' \
    'confluence.sh tree <url|id> [--depth N]      Page tree (default depth 10)' \
    'confluence.sh raw <url|id>                  Expanded page JSON' \
    'Requires CONFLUENCE_TOKEN. Page cap: 500. Exit 2 means incomplete output.'
  exit 0
fi
case "$command" in page|raw|children|tree) ;; *) die "unknown command: $command" ;; esac
(( $# >= 2 )) || die "missing page URL or ID (try --help)"
id="$(normalize_id "$2")"
depth=10
if [[ "$command" == tree && $# == 4 && "$3" == --depth ]]; then
  [[ "$4" =~ ^(0|[1-9][0-9]?)$ ]] || die "depth must be an integer from 0 to 99"
  depth="$4"
elif (( $# != 2 )); then
  die "unexpected arguments (try --help)"
fi
[[ -n "${CONFLUENCE_TOKEN:-}" ]] || die "CONFLUENCE_TOKEN not set"
[[ "$CONFLUENCE_TOKEN" != *$'\n'* && "$CONFLUENCE_TOKEN" != *$'\r'* ]] || die "invalid token"
command -v curl >/dev/null || die "curl is required"
command -v jq >/dev/null || die "jq is required"

case "$command" in
  page|raw)
    json="$(page "$id")"
    if [[ "$command" == raw ]]; then
      printf '%s\n' "$json" | jq .
    else
      printf '%s' "$json" | jq -r --arg base "$BASE" '
        "Title:   \(.title)",
        "ID:      \(.id)",
        "Space:   \(.space.key // "-") (\(.space.name // "-"))",
        "Version: \(.version.number // "-")",
        "Updated: \(.version.when // "-") by \(.version.by.displayName // "-")",
        "URL:     \($base)/pages/viewpage.action?pageId=\(.id)",
        "Path:    \([.ancestors[]? | "\(.title) [\(.id)]"] | join(" > "))",
        "", "Body (rendered HTML):", (.body.view.value // error("missing rendered body"))'
    fi
    ;;
  children|tree)
    # ponytail: bounded to 500 IDs; a string avoids Bash 4 associative arrays.
    seen="|$id|"
    if [[ "$command" == tree ]]; then
      json="$(page "$id")"
      printf '%s' "$json" | jq -r --arg base "$BASE" '
        "\(.id)  \(.title)  \($base)/pages/viewpage.action?pageId=\(.id)"'
      count=1
    fi
    walk "$id" 1
    (( incomplete == 0 )) || exit 2
    ;;
esac
