import { tool } from "@opencode-ai/plugin"

// Decode HTML entities in text extracted from DDG HTML
function decodeEntities(text: string): string {
  return text
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/&#x2F;/g, "/")
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)))
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
}

// Strip all HTML tags from a string
function stripTags(html: string): string {
  return html.replace(/<[^>]+>/g, "")
}

// DDG wraps result URLs as: /l/?uddg=<url-encoded-real-url>&rut=...
// This decodes them back to the real URL.
function decodeResultUrl(href: string): string {
  if (href.startsWith("/l/?")) {
    try {
      const params = new URLSearchParams(href.slice(4))
      const uddg = params.get("uddg")
      if (uddg) return decodeURIComponent(uddg)
    } catch {
      // fall through to return href as-is
    }
  }
  // Some results may already be absolute URLs
  return href
}

export default tool({
  description:
    "Search the web using DuckDuckGo. Returns up to 10 results with titles, URLs, and descriptions. " +
    "Use this to find documentation, examples, or information on any topic.",
  args: {
    query: tool.schema.string().describe("The search query"),
  },
  async execute(args) {
    const url = `https://html.duckduckgo.com/html/?q=${encodeURIComponent(args.query)}`

    let html: string
    try {
      const res = await fetch(url, {
        headers: {
          // DDG blocks requests that look like bots without a User-Agent
          "User-Agent":
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
          "Accept-Language": "en-US,en;q=0.9",
        },
      })
      if (!res.ok) {
        return `WebSearch failed: HTTP ${res.status} ${res.statusText}`
      }
      html = await res.text()
    } catch (err) {
      return `WebSearch failed: ${err instanceof Error ? err.message : String(err)}`
    }

    // Each result block looks like:
    //   <div class="result results_links ..."> ... </div>
    // We extract result blocks, then pull title+href and snippet from each.

    const results: Array<{ title: string; url: string; snippet: string }> = []

    // Match individual result divs (non-greedy, stop at next result or end)
    const resultBlockRe = /<div[^>]+class="[^"]*result[^"]*results_links[^"]*"[^>]*>([\s\S]*?)<\/div>\s*<\/div>/g
    let blockMatch: RegExpExecArray | null

    while ((blockMatch = resultBlockRe.exec(html)) !== null && results.length < 10) {
      const block = blockMatch[0]

      // Title and href: <a class="result__a" href="...">Title text</a>
      const titleRe = /<a[^>]+class="[^"]*result__a[^"]*"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/
      const titleMatch = titleRe.exec(block)
      if (!titleMatch) continue

      const rawHref = titleMatch[1]
      const rawTitle = titleMatch[2]

      const url = decodeResultUrl(rawHref)
      const title = decodeEntities(stripTags(rawTitle)).trim()

      // Snippet: <a class="result__snippet" ...>snippet text</a>
      const snippetRe = /<a[^>]+class="[^"]*result__snippet[^"]*"[^>]*>([\s\S]*?)<\/a>/
      const snippetMatch = snippetRe.exec(block)
      const snippet = snippetMatch
        ? decodeEntities(stripTags(snippetMatch[1])).replace(/\s+/g, " ").trim()
        : ""

      if (title && url) {
        results.push({ title, url, snippet })
      }
    }

    if (results.length === 0) {
      return `No results found for: ${args.query}`
    }

    const lines = results.map((r, i) => {
      const parts = [`## ${i + 1}. ${r.title}`, `URL: ${r.url}`]
      if (r.snippet) parts.push(`> ${r.snippet}`)
      return parts.join("\n")
    })

    return lines.join("\n\n")
  },
})
