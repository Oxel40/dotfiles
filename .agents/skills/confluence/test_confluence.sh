#!/usr/bin/env bash
# Offline contract check: exported curl function replaces network access.
set -euo pipefail
HELPER="$(dirname "${BASH_SOURCE[0]}")/confluence.sh"
export CONFLUENCE_TOKEN=offline-test-token
export CONFLUENCE_BASE_URL=https://wiki.example.com/
export MODE=normal
# Compressed draw.io model (base64 raw-deflate of URL-encoded XML), as older diagrams store it.
export ZMODEL="$(python3 -c 'import base64,urllib.parse,zlib
x="<mxGraphModel><root><mxCell id=\"0\"/><mxCell id=\"1\" parent=\"0\"/><mxCell id=\"a\" value=\"Svc &lt;b&gt;A&lt;/b&gt;\" vertex=\"1\" parent=\"1\"/><mxCell id=\"bar\" vertex=\"1\" parent=\"a\"/><object id=\"b\" label=\"Svc B\"><mxCell vertex=\"1\" parent=\"1\"/></object><mxCell id=\"e\" edge=\"1\" source=\"bar\" target=\"b\" parent=\"1\" style=\"startArrow=ERmandOne;endArrow=ERzeroToMany;\"/><mxCell id=\"l\" value=\"calls\" vertex=\"1\" parent=\"e\"/></root></mxGraphModel>"
c=zlib.compressobj(9,zlib.DEFLATED,-15);print(base64.b64encode(c.compress(urllib.parse.quote(x).encode())+c.flush()).decode())')"

curl() {
  local url="${!#}" header out=
  IFS= read -r header
  [[ "$header" == "Authorization: Bearer $CONFLUENCE_TOKEN" ]] || return 90
  [[ "$1" == -q && "$*" != *"$CONFLUENCE_TOKEN"* && "$*" != *--location* ]] || return 91
  if [[ "$url" == https://wiki.example.com/download/attachments/* ]]; then
    while (( $# )); do [[ "$1" == --output ]] && out="$2"; shift; done
    case "$url" in
      */30/My%20diagram.png?api=v2\&version=7) printf 'PNG' >"$out" ;;
      */30/My%20diagram?api=v2\&version=7) printf '<mxfile><diagram name="P1">%s</diagram></mxfile>' "$ZMODEL" >"$out" ;;
      *) return 22 ;;
    esac
    return
  fi
  [[ "$url" == https://wiki.example.com/rest/api/content/* ]] || return 92
  case "$MODE" in
    failure) return 22 ;;
    login) printf '<html>Login</html>'; return ;;
    malformed) printf '{}'; return ;;
  esac
  case "$url" in
    *'/30?expand='*)
      jq -n '{id:"30",type:"page",title:"D",body:{storage:{value:"<h2>4.1 <em>Model</em></h2><ac:structured-macro ac:name=\"drawio\"><ac:parameter ac:name=\"diagramName\">My diagram</ac:parameter><ac:parameter ac:name=\"revision\">7</ac:parameter></ac:structured-macro><ac:structured-macro ac:name=\"drawio\"><ac:parameter ac:name=\"diagramName\">Gone</ac:parameter></ac:structured-macro>"}}}'
      ;;
    *'/2830402104?expand='*)
      printf '%s' '{"id":"2830402104","type":"page","title":"Root","space":{"key":"TEST","name":"Test"},"version":{"number":1},"ancestors":[{"id":"9","title":"Parent"}],"body":{"view":{"value":"<table><tr><td>Requirement</td></tr></table>"},"storage":{"value":"<p>Source</p>"}}}'
      ;;
    *'/2830402104/child/page?limit=100&start=0')
      if [[ "$MODE" == cap || "$MODE" == exactcap ]]; then
        jq -n --arg mode "$MODE" '{results: [range(1; (if $mode == "cap" then 502 else 501 end)) | {id: tostring, title: "Child"}]}'
      else
        printf '%s' '{"results":[{"id":"10","title":"Child A"}],"_links":{"next":"https://untrusted.invalid/do-not-follow"}}'
      fi
      ;;
    *'/2830402104/child/page?limit=100&start=1')
      printf '%s' '{"results":[{"id":"20","title":"Child B"}],"_links":{}}'
      ;;
    *'/10/child/page?limit=100&start=0')
      if [[ "$MODE" == cycle ]]; then
        printf '%s' '{"results":[{"id":"2830402104","title":"Root"}]}'
      else
        printf '%s' '{"results":[{"id":"11","title":"Grandchild"}]}'
      fi
      ;;
    *'/11/child/page?limit=100&start=0'|*'/20/child/page?limit=100&start=0')
      printf '%s' '{"results":[],"_links":{}}'
      ;;
    *) printf 'Unexpected request: %s\n' "$url" >&2; return 93 ;;
  esac
}
export -f curl

expect_status() {
  local expected="$1" status=0
  shift
  output="$(bash "$HELPER" "$@" 2>&1)" || status=$?
  [[ "$status" == "$expected" ]] || {
    printf 'Expected exit %s, got %s: %s\n' "$expected" "$status" "$output" >&2
    exit 1
  }
}

for input in 2830402104 \
  'https://wiki.example.com/spaces/ENTITLEMENTS/pages/2830402104/VDE40-214+-+Requirements+Customer+Access+Management+-+Trustee' \
  'https://wiki.example.com/spaces/TEST/pages/2830402104?foo=1#section' \
  'https://wiki.example.com/pages/viewpage.action?foo=1&pageId=2830402104#section'; do
  expect_status 0 page "$input"
  [[ "$output" == *'Parent [9]'* && "$output" == *'<td>Requirement</td>'* ]]
done
expect_status 0 raw 2830402104
[[ "$(printf '%s' "$output" | jq -r '.body.storage.value')" == '<p>Source</p>' ]]
expect_status 0 children 2830402104
[[ "$output" == *'Child A'* && "$output" == *'Child B'* && "$output" != *Grandchild* ]]
expect_status 0 tree 2830402104
[[ "$output" == *'    11  Grandchild'* && "$output" == *'  20  Child B'* ]]
expect_status 2 tree 2830402104 --depth 1
[[ "$output" == *'Incomplete: depth limit'* && "$output" != *Grandchild* && "$output" == *'Child B'* ]]
expect_status 2 tree 2830402104 --depth 0
[[ "$output" != *'Child A'* ]]
for input in 'https://evil.invalid/spaces/T/pages/2830402104' \
  'https://wiki.example.com.evil.invalid/spaces/T/pages/2830402104' \
  'https://wiki.example.com/pages/viewpage.action?pageId=123abc' '123abc' 0; do
  expect_status 1 page "$input"
done
expect_status 1 page
expect_status 1 tree 2830402104 --depth -1
expect_status 1 tree 2830402104 --depth 100
CONFLUENCE_TOKEN='' expect_status 0 --help
CONFLUENCE_TOKEN='' expect_status 1 page 2830402104
CONFLUENCE_BASE_URL='' expect_status 1 page 2830402104
CONFLUENCE_BASE_URL='http://wiki.example.com' expect_status 1 page 2830402104
CONFLUENCE_TOKEN=$'bad\nheader' expect_status 1 page 2830402104
MODE=failure expect_status 1 page 2830402104
MODE=login expect_status 1 page 2830402104
MODE=malformed expect_status 1 children 2830402104
MODE=cycle expect_status 1 tree 2830402104
[[ "$output" == *'refusing to loop'* ]]
MODE=cap expect_status 2 children 2830402104
[[ "$output" == *'Incomplete: page limit 500'* ]]
MODE=exactcap expect_status 0 children 2830402104
expect_status 2 diagrams 30
[[ "$output" == *'# 1. My diagram'* && "$output" == *'Section: 4.1 Model'* ]]
[[ "$output" == *'  - Svc A'* && "$output" == *'  - Svc B'* ]]
[[ "$output" == *'  - Svc A -> Svc B : calls [cardinality 1 : 0..*]'* ]]
[[ "$output" == *'# 2. Gone'*'(download failed)'* && "$output" == *'Incomplete:'* ]]
printf 'PASS: URL parsing, page/raw output, pagination, hierarchy, limits, auth, diagrams, and failures\n'
