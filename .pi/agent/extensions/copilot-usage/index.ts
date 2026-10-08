import {
  readStoredCredential,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent"
import { formatUsage, readUsage, UsageError } from "./usage.ts"

const STATUS_KEY = "copilot-usage"
const REFRESH_INTERVAL_MS = 60_000
const MIN_REFRESH_INTERVAL_MS = 30_000
const REQUEST_TIMEOUT_MS = 15_000

export default function (pi: ExtensionAPI) {
  let timer: ReturnType<typeof setInterval> | undefined
  let controller: AbortController | undefined
  let generation = 0
  let refreshing = false
  let lastAttempt = 0
  let retryAt = 0

  const stop = (ctx: ExtensionContext) => {
    generation++
    if (timer !== undefined) clearInterval(timer)
    timer = undefined
    controller?.abort()
    controller = undefined
    refreshing = false
    lastAttempt = 0
    retryAt = 0
    if (ctx.mode === "tui") ctx.ui.setStatus(STATUS_KEY, undefined)
  }

  const refresh = async (ctx: ExtensionContext, manual = false) => {
    if (ctx.mode !== "tui") return
    if (refreshing) {
      if (manual) ctx.ui.notify("Copilot usage refresh already in progress", "info")
      return
    }

    const now = Date.now()
    if (now < Math.max(retryAt, lastAttempt + MIN_REFRESH_INTERVAL_MS)) {
      if (manual) ctx.ui.notify("Please wait before refreshing Copilot usage again", "info")
      return
    }

    refreshing = true
    lastAttempt = now
    const requestGeneration = generation
    const requestController = new AbortController()
    controller = requestController

    try {
      // The private usage endpoint needs GitHub's OAuth refresh token, not Copilot's API access token.
      const usage = await readUsage(
        AbortSignal.any([requestController.signal, AbortSignal.timeout(REQUEST_TIMEOUT_MS)]),
        { readCredential: () => readStoredCredential("github-copilot") },
      )
      if (requestGeneration !== generation || requestController.signal.aborted) return
      const status = formatUsage(usage)
      ctx.ui.setStatus(STATUS_KEY, status)
      retryAt = 0
      if (manual) ctx.ui.notify(status, "info")
    } catch (error) {
      if (requestGeneration !== generation || requestController.signal.aborted) return
      const usageError = error instanceof UsageError ? error : new UsageError("Copilot usage unavailable")
      ctx.ui.setStatus(STATUS_KEY, "Copilot: Unavailable")
      retryAt = usageError.retryAt
      if (manual) ctx.ui.notify(usageError.message, "warning")
    } finally {
      if (requestGeneration === generation) {
        refreshing = false
        if (controller === requestController) controller = undefined
      }
    }
  }

  pi.registerCommand("copilot-usage", {
    description: "Refresh GitHub Copilot usage",
    handler: async (_args, ctx) => refresh(ctx, true),
  })

  pi.on("session_start", (_event, ctx) => {
    stop(ctx)
    if (ctx.mode !== "tui") return
    ctx.ui.setStatus(STATUS_KEY, "Copilot: Loading…")
    timer = setInterval(() => void refresh(ctx), REFRESH_INTERVAL_MS)
    void refresh(ctx)
  })

  pi.on("session_shutdown", (_event, ctx) => stop(ctx))
}
