#!/usr/bin/env python3
"""Search the web via DuckDuckGo Lite and print clean, agent-friendly results.

Usage:
    web-search.py "your query here" [--max N] [--json]

Output (default): numbered results, each with title, URL, and snippet.
Exit codes:
    0  results printed
    2  blocked by DuckDuckGo anomaly/CAPTCHA page (retry later / change network)
    3  no results found
    4  network/HTTP error
"""
import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from html.parser import HTMLParser

ENDPOINT = "https://lite.duckduckgo.com/lite/"
UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36"
)


def fetch(query: str, retries: int = 2) -> str:
    data = urllib.parse.urlencode({"q": query}).encode()
    last_err = None
    for attempt in range(retries + 1):
        req = urllib.request.Request(
            ENDPOINT,
            data=data,  # POST avoids some rate limiting vs GET
            headers={
                "User-Agent": UA,
                "Accept": "text/html",
                "Accept-Language": "en-US,en;q=0.9",
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                return resp.read().decode("utf-8", "replace")
        except Exception as e:  # noqa: BLE001
            last_err = e
            if attempt < retries:
                time.sleep(1.5 * (attempt + 1))
    print(f"error: network/HTTP failure: {last_err}", file=sys.stderr)
    sys.exit(4)


class ResultParser(HTMLParser):
    """Extract (title, url, snippet) tuples from DuckDuckGo Lite HTML."""

    def __init__(self):
        super().__init__()
        self.results = []
        self._in_link = False
        self._in_snippet = False
        self._cur_title = []
        self._cur_url = None
        self._snippet_buf = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "a" and "result-link" in (a.get("class") or ""):
            self._in_link = True
            self._cur_title = []
            self._cur_url = self._decode_url(a.get("href", ""))
        elif tag == "td" and "result-snippet" in (a.get("class") or ""):
            self._in_snippet = True
            self._snippet_buf = []

    def handle_endtag(self, tag):
        if tag == "a" and self._in_link:
            self._in_link = False
            title = " ".join("".join(self._cur_title).split())
            if title and self._cur_url:
                self.results.append({"title": title, "url": self._cur_url, "snippet": ""})
        elif tag == "td" and self._in_snippet:
            self._in_snippet = False
            snippet = " ".join("".join(self._snippet_buf).split())
            # attach snippet to the most recent result lacking one
            if self.results and not self.results[-1]["snippet"]:
                self.results[-1]["snippet"] = snippet

    def handle_data(self, data):
        if self._in_link:
            self._cur_title.append(data)
        elif self._in_snippet:
            self._snippet_buf.append(data)

    @staticmethod
    def _decode_url(href: str) -> str:
        if not href:
            return ""
        m = re.search(r"[?&]uddg=([^&]+)", href)
        if m:
            return urllib.parse.unquote(m.group(1))
        if href.startswith("//"):
            return "https:" + href
        return href


def main():
    ap = argparse.ArgumentParser(description="DuckDuckGo web search for agents")
    ap.add_argument("query", nargs="+", help="search terms")
    ap.add_argument("--max", type=int, default=8, help="max results (default 8)")
    ap.add_argument("--json", action="store_true", help="emit JSON instead of text")
    args = ap.parse_args()

    query = " ".join(args.query)
    html = fetch(query)

    if "anomaly-modal" in html or "anomaly.js" in html:
        print(
            "error: DuckDuckGo served an anti-bot CAPTCHA page (not a 'no results' "
            "condition). Wait ~30s and retry, or try a different network/query.",
            file=sys.stderr,
        )
        sys.exit(2)

    parser = ResultParser()
    parser.feed(html)
    results = parser.results[: args.max]

    if not results:
        print(f"error: no results for: {query}", file=sys.stderr)
        sys.exit(3)

    if args.json:
        print(json.dumps(results, indent=2, ensure_ascii=False))
        return

    for i, r in enumerate(results, 1):
        print(f"{i}. {r['title']}")
        print(f"   {r['url']}")
        if r["snippet"]:
            print(f"   {r['snippet']}")
        print()


if __name__ == "__main__":
    main()
