#!/usr/bin/env bash
# JIRA helper for Jira Server/Data Center. Auth via $JIRA_TOKEN (bearer) against $JIRA_BASE_URL.
# Usage: jira.sh <command> <key|url> [args]
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

[[ "${JIRA_BASE_URL:-}" =~ ^https://[^/?#[:space:]]+(/[^?#[:space:]]*)?$ ]] ||
  die "JIRA_BASE_URL must be set to an https:// URL, e.g. https://jira.example.com"
BASE="${JIRA_BASE_URL%/}"

[ -n "${JIRA_TOKEN:-}" ] || die "JIRA_TOKEN not set"

api() {
  # $1 = path (starting with /rest/...). Prints JSON; dies on HTTP errors.
  local out code
  out="$(curl -sS -w '\n%{http_code}' -H "Authorization: Bearer $JIRA_TOKEN" \
       -H "Accept: application/json" \
       "$BASE$1")" || die "request failed; check network/VPN"
  code="${out##*$'\n'}"; out="${out%$'\n'*}"
  if [ "$code" -ge 400 ]; then
    local msg; msg="$(printf '%s' "$out" | jq -r '(.errorMessages // []) + [(.errors // {})[]] | join("; ")' 2>/dev/null || true)"
    [ -n "$msg" ] || case "$code" in 401) msg="unauthorized; check JIRA_TOKEN" ;; 403) msg="forbidden; check permissions" ;; *) msg="request failed" ;; esac
    die "HTTP $code: $msg"
  fi
  printf '%s\n' "$out"
}

send() {
  # $1 = method, $2 = path, $3 = JSON body. Prints the response (may be empty); dies on HTTP errors.
  local out code msg
  out="$(printf '%s' "$3" | curl -sS -w '\n%{http_code}' -X "$1" -H "Authorization: Bearer $JIRA_TOKEN" \
       -H "Accept: application/json" -H "Content-Type: application/json" \
       --data-binary @- "$BASE$2")" || die "request failed; check network/VPN"
  code="${out##*$'\n'}"; out="${out%$'\n'*}"
  if [ "$code" -ge 400 ]; then
    msg="$(printf '%s' "$out" | jq -r '(.errorMessages // []) + [(.errors // {}) | to_entries[] | "\(.key): \(.value)"] | join("; ")' 2>/dev/null || true)"
    die "HTTP $code: ${msg:-request failed}"
  fi
  printf '%s\n' "$out"
}

# Normalize a key from URL / bare key / digits.
normalize_key() {
  local in="$1" key
  case "$in" in
    http*://*/browse/*) key="${in##*/browse/}"; key="${key%%\?*}"; key="${key%%/*}" ;;
    *[A-Za-z]*-[0-9]*)  key="$in" ;;
    [0-9]*)
      [ -n "${JIRA_DEFAULT_PROJECT:-}" ] || \
        die "got digits only ('$in') but JIRA_DEFAULT_PROJECT is not set"
      key="${JIRA_DEFAULT_PROJECT}-$in" ;;
    *) key="$in" ;;
  esac
  printf '%s' "$key"
}

jqcheck() { command -v jq >/dev/null 2>&1; }

cmd_issue() {
  local key; key="$(normalize_key "$1")"
  local json; json="$(api "/rest/api/2/issue/$key?fields=summary,status,assignee,reporter,priority,issuetype,description,created,updated,labels")"
  if jqcheck; then
    echo "$json" | jq -r '
      "Key:         '"$key"'",
      "Summary:     \(.fields.summary)",
      "Type:        \(.fields.issuetype.name)",
      "Status:      \(.fields.status.name)",
      "Priority:    \(.fields.priority.name // "-")",
      "Assignee:    \(.fields.assignee.displayName // "Unassigned")",
      "Reporter:    \(.fields.reporter.displayName // "-")",
      "Labels:      \((.fields.labels // []) | join(", "))",
      "Created:     \(.fields.created)",
      "Updated:     \(.fields.updated)",
      "URL:         '"$BASE"'/browse/'"$key"'",
      "",
      "Description:",
      (.fields.description // "(none)")'
  else
    echo "$json"
  fi
}

cmd_comments() {
  local key; key="$(normalize_key "$1")"
  local json; json="$(api "/rest/api/2/issue/$key/comment")"
  if jqcheck; then
    echo "$json" | jq -r '.comments[] |
      "--- \(.author.displayName) @ \(.created) ---\n\(.body)\n"'
  else
    echo "$json"
  fi
}

cmd_full() {
  cmd_issue "$1"
  echo
  echo "=== Comments ==="
  cmd_comments "$1"
}

cmd_attachments() {
  local key; key="$(normalize_key "$1")"
  local json; json="$(api "/rest/api/2/issue/$key?fields=attachment")"
  if jqcheck; then
    echo "$json" | jq -r '.fields.attachment[]? |
      "\(.filename)\t\(.size) bytes\t\(.content)"'
  else
    echo "$json"
  fi
}

cmd_download() {
  local key; key="$(normalize_key "$1")"
  local dir="${2:-./jira-$key}"
  mkdir -p "$dir"
  jqcheck || die "download requires jq"
  local json; json="$(api "/rest/api/2/issue/$key?fields=attachment")"
  echo "$json" | jq -r '.fields.attachment[]? | "\(.content)\t\(.filename)"' |
  while IFS=$'\t' read -r url name; do
    [ -n "$url" ] || continue
    [[ "$url" == "$BASE/"* ]] || { echo "skipping $name: not on $BASE"; continue; }
    echo "downloading $name"
    curl -sS -L -H "Authorization: Bearer $JIRA_TOKEN" "$url" -o "$dir/$name"
  done
  echo "saved to $dir"
}

cmd_raw() {
  local key; key="$(normalize_key "$1")"
  api "/rest/api/2/issue/$key"
}

cmd_search() {
  local jql="$1"
  local json; json="$(api "/rest/api/2/search?maxResults=50&fields=summary,status,assignee&jql=$(jqurlencode "$jql")")"
  if jqcheck; then
    echo "$json" | jq -r '.issues[] |
      "\(.key)\t[\(.fields.status.name)]\t\(.fields.summary)"'
  else
    echo "$json"
  fi
}

cmd_transitions() {
  local key; key="$(normalize_key "$1")"
  api "/rest/api/2/issue/$key/transitions" | jq -r '.transitions[] | "\(.id)\t\(.name)\t-> \(.to.name)"'
}

cmd_transition() {
  [ $# -eq 2 ] || die "usage: transition <key|url> <transition or status name|id>"
  local key want json id
  key="$(normalize_key "$1")"; want="$2"
  json="$(api "/rest/api/2/issue/$key/transitions")"
  # Exact (case-insensitive) match on transition id, name, or target status; no guessing.
  id="$(printf '%s' "$json" | jq -r --arg w "$want" '
    [.transitions[] | select(.id == $w or (.name | ascii_downcase) == ($w | ascii_downcase)
      or (.to.name | ascii_downcase) == ($w | ascii_downcase)) | .id] | unique |
    if length == 1 then .[0] else empty end')"
  if [ -z "$id" ]; then
    echo "No single transition matches '$want'. Available from $key:" >&2
    printf '%s' "$json" | jq -r '.transitions[] | "  \(.id)\t\(.name)\t-> \(.to.name)"' >&2
    exit 1
  fi
  send POST "/rest/api/2/issue/$key/transitions" "$(jq -n --arg id "$id" '{transition: {id: $id}}')" >/dev/null
  cmd_issue "$key" | grep -E '^(Key|Status):'
}

cmd_create_subtask() {
  [ $# -ge 2 ] || die "usage: create-subtask <parent key|url> <summary> [--desc TEXT | --desc-file FILE]"
  local parent summary desc="" pjson project type body
  parent="$(normalize_key "$1")"; summary="$2"; shift 2
  while [ $# -gt 0 ]; do
    [ $# -ge 2 ] || die "missing value for $1"
    case "$1" in
      --desc) desc="$2" ;;
      --desc-file) [ -f "$2" ] || die "no such file: $2"; desc="$(cat "$2")" ;;
      *) die "unexpected argument: $1" ;;
    esac
    shift 2
  done
  pjson="$(api "/rest/api/2/issue/$parent?fields=project,issuetype")"
  [ "$(printf '%s' "$pjson" | jq -r '.fields.issuetype.subtask')" != true ] || die "$parent is itself a sub-task"
  project="$(printf '%s' "$pjson" | jq -r '.fields.project.id')"
  type="$(api "/rest/api/2/issue/createmeta/$project/issuetypes" | jq -r '[.values[] | select(.subtask)][0].id // empty')"
  [ -n "$type" ] || die "project has no sub-task issue type"
  body="$(jq -n --arg p "$parent" --arg pid "$project" --arg t "$type" --arg s "$summary" --arg d "$desc" '
    {fields: ({project: {id: $pid}, parent: {key: $p}, issuetype: {id: $t}, summary: $s}
      + (if $d == "" then {} else {description: $d} end))}')"
  send POST "/rest/api/2/issue" "$body" | jq -r --arg base "$BASE" '"\(.key)\t\($base)/browse/\(.key)"'
}

# URL-encode using jq if available, else curl --data-urlencode trick.
jqurlencode() {
  if jqcheck; then
    printf '%s' "$1" | jq -sRr @uri
  else
    printf '%s' "$1" | curl -Gso /dev/null -w '%{url_effective}' \
      --data-urlencode @- '' | sed 's/^.*?//'
  fi
}

main() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    issue)       cmd_issue "$@" ;;
    full)        cmd_full "$@" ;;
    comments)    cmd_comments "$@" ;;
    attachments) cmd_attachments "$@" ;;
    download)    cmd_download "$@" ;;
    raw)         cmd_raw "$@" ;;
    search)      cmd_search "$@" ;;
    transitions) cmd_transitions "$@" ;;
    transition)  cmd_transition "$@" ;;
    create-subtask) cmd_create_subtask "$@" ;;
    ""|-h|--help)
      cat <<EOF
jira.sh <command> <key|url> [args]
  issue <key|url>         core fields + description
  full <key|url>          fields + comments
  comments <key|url>      comments only
  attachments <key|url>   list attachments
  download <key|url> [dir] download attachments
  raw <key|url>           full raw JSON
  search '<JQL>'          run a JQL query
Write commands (only when the user asked for the change):
  transitions <key|url>                 list available transitions
  transition <key|url> <name|status|id> move the issue (exact match, else lists options)
  create-subtask <parent> <summary> [--desc TEXT | --desc-file FILE]
                                        create a sub-task (wiki markup description)
EOF
      ;;
    *) die "unknown command: $sub (try --help)" ;;
  esac
}

main "$@"
