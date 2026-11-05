#!/usr/bin/env bash
# Confluence helper: reads, plus explicit write commands. Requires curl, jq, and CONFLUENCE_TOKEN.
set -euo pipefail

BASE="${CONFLUENCE_BASE_URL%/}"
MAX_PAGES=500
count=0
incomplete=0
capped=0

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

normalize_id() {
  local input="$1" id pattern
  pattern='^/spaces/[^/?#]+/pages/([0-9]+)([/?#].*)?$'
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    id="$input"
  elif [[ "$input" == "$BASE/spaces/"* && "${input#"$BASE"}" =~ $pattern ]]; then
    id="${BASH_REMATCH[1]}"
  elif [[ "$input" == "$BASE/x/"* ]]; then
    input="${input#"$BASE/x/"}"
    input="${input%%[?#]*}"
    [[ "$input" =~ ^[A-Za-z0-9_-]{1,11}$ ]] || die "invalid short link"
    command -v python3 >/dev/null || die "python3 is required for short links"
    # Tiny URL = little-endian page ID, base64 with -/_ for /+ and trailing A/= stripped.
    id="$(python3 -c 'import base64,sys
s=sys.argv[1].replace("-","/").replace("_","+")
print(int.from_bytes(base64.b64decode((s+"A"*11)[:11]+"="),"little"))' "$input")"
  elif [[ "$input" == "$BASE/pages/viewpage.action?"* ]]; then
    input="${input#*\?}"
    input="${input%%#*}"
    if [[ "$input" =~ (^|\&)pageId=([0-9]+)(\&|$) ]]; then
      id="${BASH_REMATCH[2]}"
    else
      die "URL has no numeric pageId"
    fi
  else
    die "expected a page ID, a $BASE page URL, or a $BASE/x/ short link"
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

send() {
  # send METHOD PATH [curl args...]: write call with the same token guard as api().
  local method="$1" path="$2" json
  shift 2
  json="$(printf 'Authorization: Bearer %s\n' "$CONFLUENCE_TOKEN" |
    curl -q --fail-with-body --silent --show-error --connect-timeout 10 --max-time 120 \
      --header @- --header 'Accept: application/json' --header 'X-Atlassian-Token: no-check' \
      --request "$method" "$@" "$BASE/rest/api/content/$path")" ||
    die "Confluence $method failed: $(printf '%s' "$json" | jq -r '.message // empty' 2>/dev/null || true)"
  printf '%s' "$json" | jq -e 'type == "object"' >/dev/null ||
    die "expected JSON from Confluence, not a login page or redirect"
  printf '%s' "$json"
}

update() {
  # update ID STORAGE_FILE [TITLE] [MESSAGE]: fetch the current version, then PUT version + 1.
  local cur body
  [[ -s "$2" ]] || die "storage file is empty or missing: $2"
  cur="$(api "$1?expand=version")"
  # stdin carries the auth header, so the body goes through a file.
  body="$(mktemp "${TMPDIR:-/tmp}/confluence-update.XXXXXX")"
  jq -n --rawfile v "$2" --arg id "$1" --argjson cur "$cur" --arg title "${3:-}" --arg msg "${4:-}" '
    {id: $id, type: "page", title: (if $title == "" then $cur.title else $title end),
     version: {number: ($cur.version.number + 1), message: $msg},
     body: {storage: {value: $v, representation: "storage"}}}' >"$body"
  send PUT "$1" --header 'Content-Type: application/json' --data-binary "@$body" | jq -r --arg base "$BASE" '
    "Updated \(.title) to version \(.version.number)", "\($base)/pages/viewpage.action?pageId=\(.id)"'
  rm -f "$body"
}

attach() {
  # attach ID FILE NAME MIME: new attachment, or a new version of the one with the same name.
  local existing path
  [[ -f "$2" ]] || die "no such file: $2"
  existing="$(api "$1/child/attachment?filename=$(jq -rn --arg s "$3" '$s | @uri')" | jq -r '.results[0].id // empty')"
  path="$1/child/attachment${existing:+/$existing/data}"
  send POST "$path" --form "file=@$2;type=$4;filename=$3" --form minorEdit=true |
    jq -r '(.results[0] // .) | "\(.id)\t\(.version.number)\t\(.title)"'
}

download() {
  # Same token guard as api(): fixed host, no curlrc, no redirects.
  printf 'Authorization: Bearer %s\n' "$CONFLUENCE_TOKEN" |
    curl -q --fail --silent --show-error --connect-timeout 10 --max-time 120 \
      --header @- --output "$2" "$BASE/download/attachments/$1"
}

diagrams() {
  local out n=0 failed=0 src name rev heading enc file query
  out="$(mktemp -d "${TMPDIR:-/tmp}/confluence-diagrams.XXXXXX")"
  printf 'Diagrams on page %s (files in %s)\n\n' "$1" "$out"
  # \x1f separator: tab IFS would collapse empty fields.
  while IFS=$'\x1f' read -r src name rev heading; do
    n=$((n + 1))
    if [[ -z "$name" ]]; then
      printf '# %s. (macro without diagramName; skipped)\n\n' "$n"; failed=1; continue
    fi
    src="${src:-$1}"
    enc="$(jq -rn --arg s "$name" '$s | @uri')"
    file="$out/$n-$(printf '%s' "$name" | tr -c 'A-Za-z0-9._-' '_')"
    query="api=v2${rev:+&version=$rev}"
    printf '# %s. %s\nSection: %s\nSource:  %s/download/attachments/%s/%s?%s\n' \
      "$n" "$name" "${heading:--}" "$BASE" "$src" "$enc" "$query"
    if download "$src/$enc.png?$query" "$file.png" 2>/dev/null; then
      printf 'Image:   %s.png\n' "$file"
    else
      printf 'Image:   (download failed)\n'; failed=1
    fi
    if ! download "$src/$enc?$query" "$file.drawio" 2>/dev/null; then
      printf 'XML:     (download failed)\n\n'; failed=1
    elif python3 "$HERE/drawio.py" summary "$file.drawio" >"$file.txt" 2>&1; then
      printf 'XML:     %s.drawio\n\n' "$file"; cat "$file.txt"
    else
      printf 'XML:     %s.drawio (parse failed: %s)\n\n' "$file" "$(tail -1 "$file.txt")"; failed=1
    fi
  done < <(printf '%s' "$json" | jq -r '.body.storage.value' | python3 "$HERE/drawio.py" macros)
  (( n > 0 )) || printf 'No draw.io diagrams found.\n'
  (( failed == 0 )) || { printf 'Incomplete: some diagrams could not be read.\n' >&2; exit 2; }
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
    'confluence.sh diagrams <url|id>             draw.io diagrams: text summary + PNG paths' \
    'confluence.sh search <CQL>                  Pages matching CQL (max 50)' \
    'Write commands (only when the user asked for the change):' \
    'confluence.sh update <url|id> <storage.html> [--title T] [--message M]' \
    '                                            Replace the body (storage format); bumps the version' \
    'confluence.sh attach <url|id> <file> [--name N] [--type MIME]' \
    '                                            Upload, or add a version to the same-named attachment' \
    'confluence.sh drawio-publish <url|id> <file.drawio> <diagramName> [--after <storage snippet>]' \
    '                                            Render PNG, upload both, point/insert the macro' \
    'Page inputs: ID, page URL, viewpage.action?pageId= URL, or /x/ short link.' \
    'Requires CONFLUENCE_BASE_URL (e.g. https://wiki.example.com) and CONFLUENCE_TOKEN. Page cap: 500. Exit 2 means incomplete output.'
  exit 0
fi
[[ "${CONFLUENCE_BASE_URL:-}" =~ ^https://[^/?#[:space:]]+(/[^?#[:space:]]*)?$ ]] ||
  die "CONFLUENCE_BASE_URL must be set to an https:// URL, e.g. https://wiki.example.com"
case "$command" in page|raw|children|tree|diagrams|search|update|attach|drawio-publish) ;; *) die "unknown command: $command" ;; esac
(( $# >= 2 )) || die "missing argument (try --help)"
[[ "$command" == search ]] || id="$(normalize_id "$2")"
depth=10
title='' message='' name='' mime='' after=''
if [[ "$command" =~ ^(update|attach|drawio-publish)$ ]]; then
  if [[ "$command" == drawio-publish ]]; then
    (( $# >= 4 )) || die "usage: drawio-publish <url|id> <file.drawio> <diagramName> [--after SNIPPET]"
    file="$3" name="$4"; shift 4
  else
    (( $# >= 3 )) || die "missing file (try --help)"
    file="$3"; shift 3
  fi
  while (( $# )); do
    (( $# >= 2 )) || die "missing value for $1"
    case "$command:$1" in
      update:--title) title="$2" ;; update:--message) message="$2" ;;
      attach:--name) name="$2" ;; attach:--type) mime="$2" ;;
      drawio-publish:--after) after="$2" ;;
      *) die "unexpected argument: $1 (try --help)" ;;
    esac
    shift 2
  done
elif [[ "$command" == search ]]; then
  (( $# == 2 )) || die "quote the CQL as one argument"
elif [[ "$command" == tree && $# == 4 && "$3" == --depth ]]; then
  [[ "$4" =~ ^(0|[1-9][0-9]?)$ ]] || die "depth must be an integer from 0 to 99"
  depth="$4"
elif (( $# != 2 )); then
  die "unexpected arguments (try --help)"
fi
[[ -n "${CONFLUENCE_TOKEN:-}" ]] || die "CONFLUENCE_TOKEN not set"
[[ "$CONFLUENCE_TOKEN" != *$'\n'* && "$CONFLUENCE_TOKEN" != *$'\r'* ]] || die "invalid token"
command -v curl >/dev/null || die "curl is required"
command -v jq >/dev/null || die "jq is required"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ ! "$command" =~ ^(diagrams|drawio-publish)$ ]] || command -v python3 >/dev/null || die "python3 is required"

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
  diagrams)
    json="$(page "$id")"
    diagrams "$id"
    ;;
  search)
    api "search?limit=50&expand=space&cql=$(jq -rn --arg s "$2" '$s | @uri')" | jq -r --arg base "$BASE" '
      .results[] | "\(.id)  [\(.space.key // "-")] \(.title)  \($base)/pages/viewpage.action?pageId=\(.id)"'
    ;;
  update)
    update "$id" "$file" "$title" "$message"
    ;;
  attach)
    attach "$id" "$file" "${name:-$(basename "$file")}" "${mime:-application/octet-stream}"
    ;;
  drawio-publish)
    [[ -f "$file" ]] || die "no such file: $file"
    work="$(mktemp -d "${TMPDIR:-/tmp}/drawio-publish.XXXXXX")"
    read -r width height < <(python3 "$HERE/drawio.py" render "$file" "$work/diagram.png") || die "render failed"
    rev="$(attach "$id" "$file" "$name" application/vnd.jgraph.mxfile | cut -f2)"
    attach "$id" "$work/diagram.png" "$name.png" image/png >/dev/null
    api "$id?expand=body.storage" | jq -r '.body.storage.value' >"$work/old.html"
    python3 "$HERE/drawio.py" set-macro "$name" "$rev" "$width" "$height" ${after:+"$after"} \
      <"$work/old.html" >"$work/new.html" || die "could not place the diagram macro"
    update "$id" "$work/new.html" '' "Publish diagram $name (revision $rev)"
    printf 'PNG: %s/diagram.png\n' "$work"
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
