import {
  CustomEditor,
  keyText,
  type ExtensionAPI,
  type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import type { EditorTheme, TUI } from "@earendil-works/pi-tui";

const INTERRUPT_WINDOW_MS = 500;
const STATUS_KEY = "double-escape-interrupt";

class DoubleEscapeInterruptEditor extends CustomEditor {
  private readonly appKeybindings: KeybindingsManager;
  private readonly isAgentRunActive: () => boolean;
  private readonly setPendingStatus: (pending: boolean) => void;
  private pendingKey: string | undefined;
  private pendingAt: number | undefined;
  private pendingTimer: ReturnType<typeof setTimeout> | undefined;

  constructor(
    tui: TUI,
    theme: EditorTheme,
    keybindings: KeybindingsManager,
    isAgentRunActive: () => boolean,
    setPendingStatus: (pending: boolean) => void,
  ) {
    super(tui, theme, keybindings);
    this.appKeybindings = keybindings;
    this.isAgentRunActive = isAgentRunActive;
    this.setPendingStatus = setPendingStatus;
  }

  handleInput(data: string): void {
    const isInterrupt = this.appKeybindings.matches(data, "app.interrupt");

    // Keep autocomplete dismissal and all non-interrupt input on Pi's normal path.
    if (
      !isInterrupt ||
      this.isShowingAutocomplete() ||
      !this.isAgentRunActive()
    ) {
      this.clearPendingInterrupt();
      super.handleInput(data);
      return;
    }

    const now = Date.now();
    if (
      this.pendingKey === data &&
      this.pendingAt !== undefined &&
      now - this.pendingAt < INTERRUPT_WINDOW_MS
    ) {
      this.clearPendingInterrupt();
      // Let Pi's own Escape handler abort the run and restore queued messages.
      super.handleInput(data);
      return;
    }

    this.clearPendingInterrupt();
    this.pendingKey = data;
    this.pendingAt = now;
    this.setPendingStatus(true);
    this.pendingTimer = setTimeout(
      () => this.clearPendingInterrupt(),
      INTERRUPT_WINDOW_MS,
    );
  }

  clearPendingInterrupt(): void {
    const wasPending = this.pendingKey !== undefined;
    this.pendingKey = undefined;
    this.pendingAt = undefined;

    if (this.pendingTimer !== undefined) {
      clearTimeout(this.pendingTimer);
      this.pendingTimer = undefined;
    }

    if (wasPending) {
      this.setPendingStatus(false);
    }
  }
}

export default function (pi: ExtensionAPI) {
  let agentRunActive = false;
  let clearPendingInterrupt = () => {};

  pi.on("agent_start", () => {
    agentRunActive = true;
    clearPendingInterrupt();
  });

  pi.on("agent_end", () => {
    agentRunActive = false;
    clearPendingInterrupt();
  });

  pi.on("agent_settled", () => {
    agentRunActive = false;
    clearPendingInterrupt();
  });

  pi.on("session_start", (_event, ctx) => {
    agentRunActive = false;
    clearPendingInterrupt();

    if (ctx.mode !== "tui") return;

    ctx.ui.setStatus(STATUS_KEY, undefined);
    const interruptKey = keyText("app.interrupt") || "Esc";

    ctx.ui.setEditorComponent((tui, theme, keybindings) => {
      const editor = new DoubleEscapeInterruptEditor(
        tui,
        theme,
        keybindings,
        () => agentRunActive,
        (pending) => {
          ctx.ui.setStatus(
            STATUS_KEY,
            pending
              ? `Press ${interruptKey} again within ${INTERRUPT_WINDOW_MS} ms to interrupt`
              : undefined,
          );
        },
      );
      clearPendingInterrupt = () => editor.clearPendingInterrupt();
      return editor;
    });
  });

  pi.on("session_shutdown", (_event, ctx) => {
    agentRunActive = false;
    clearPendingInterrupt();
    ctx.ui.setStatus(STATUS_KEY, undefined);
  });
}
