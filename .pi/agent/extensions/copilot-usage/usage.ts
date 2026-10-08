export type Usage = {
  used?: number
  allowance?: number
  approximate: boolean
  unit: "AI credits" | "premium requests"
}

export class UsageError extends Error {
  retryAt: number

  constructor(message: string, retryAt = 0) {
    super(message)
    this.retryAt = retryAt
  }
}

type Dependencies = {
  readCredential: () => unknown | Promise<unknown>
  fetch?: typeof fetch
}

function object(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {}
}

function number(value: unknown): number | undefined {
  if (typeof value !== "number" && (typeof value !== "string" || !value.trim())) return
  const result = Number(value)
  return Number.isFinite(result) && result >= 0 ? result : undefined
}

function isGitHubCom(value: unknown): boolean {
  if (value === undefined || value === null || value === "") return true
  if (typeof value !== "string") return false
  try {
    const url = new URL(value.includes("://") ? value : `https://${value}`)
    return url.hostname.toLowerCase() === "github.com"
  } catch {
    return false
  }
}

export function parseUsage(data: unknown): Usage {
  const account = object(data)
  const snapshots = object(account.quota_snapshots)
  const quota = object(snapshots.premium_interactions)
  const unit = account.token_based_billing === true ? "AI credits" : "premium requests"
  const allowance = number(quota.entitlement)

  // Pooled accounts report consumption without a per-user denominator.
  if (quota.unlimited === true) {
    return {
      used: quota.has_quota === false ? undefined : number(quota.credits_used),
      approximate: false,
      unit,
    }
  }
  if (allowance === undefined || allowance === 0) {
    throw new UsageError("GitHub did not report a personal quota")
  }

  // Credits and legacy requests can use different accounting bases.
  const remaining = number(quota.quota_remaining)
    ?? (account.token_based_billing === true ? undefined : number(quota.remaining))
  if (remaining !== undefined) {
    if (remaining > allowance) throw new UsageError("GitHub returned invalid quota data")
    return { used: allowance - remaining, allowance, approximate: false, unit }
  }

  const percent = number(quota.percent_remaining)
  if (percent !== undefined && percent <= 100) {
    return { used: allowance * (100 - percent) / 100, allowance, approximate: true, unit }
  }
  return { allowance, approximate: false, unit }
}

const format = new Intl.NumberFormat("en-US", { maximumFractionDigits: 2 })

export function formatUsage(usage: Usage): string {
  if (usage.used === undefined) return "Copilot: Unavailable"
  const used = `${usage.approximate ? "~" : ""}${format.format(usage.used)}`
  const amount = usage.allowance === undefined
    ? used
    : `${used} / ${format.format(usage.allowance)}`
  return `Copilot: ${amount} ${usage.unit}`
}

export async function readUsage(signal: AbortSignal, dependencies: Dependencies): Promise<Usage> {
  try {
    const credential = object(await dependencies.readCredential())
    if (credential.type !== "oauth" || typeof credential.refresh !== "string" || !credential.refresh.trim()) {
      throw new UsageError("Connect GitHub Copilot in Pi first")
    }
    if (!isGitHubCom(credential.enterpriseUrl)) throw new UsageError("Only GitHub.com accounts are supported")

    signal.throwIfAborted()
    const response = await (dependencies.fetch ?? fetch)("https://api.github.com/copilot_internal/user", {
      headers: {
        Authorization: `token ${credential.refresh}`,
        Accept: "application/json",
        "User-Agent": "pi-copilot-usage/1.0",
        "X-GitHub-Api-Version": "2025-04-01",
      },
      redirect: "error",
      signal,
    })
    if (!response.ok) {
      const retry = response.headers.get("retry-after")
      const seconds = retry === null ? undefined : number(retry)
      const retryAt = seconds !== undefined ? Date.now() + seconds * 1000 : Date.parse(retry ?? "")
      const reset = number(response.headers.get("x-ratelimit-reset"))
      const limited = response.status === 429 || (response.status === 403 &&
        (retry !== null || response.headers.get("x-ratelimit-remaining") === "0"))
      // Never expose response bodies, request headers, or underlying errors.
      throw new UsageError(
        limited ? "GitHub usage rate limited" : `GitHub usage unavailable (HTTP ${response.status})`,
        limited ? Math.max(Date.now() + 300_000, Number.isFinite(retryAt) ? retryAt : 0, (reset ?? 0) * 1000) : 0,
      )
    }
    return parseUsage(await response.json())
  } catch (error) {
    if (error instanceof UsageError) throw error
    throw new UsageError("Copilot usage unavailable")
  }
}
