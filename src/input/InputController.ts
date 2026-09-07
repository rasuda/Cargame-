export type Control = "left" | "right" | "throttle" | "brake";

const KEY_TO_CONTROL: Record<string, Control> = {
  ArrowLeft: "left",
  KeyA: "left",
  ArrowRight: "right",
  KeyD: "right",
  ArrowUp: "throttle",
  KeyW: "throttle",
  ArrowDown: "brake",
  KeyS: "brake",
};

export class InputController {
  private readonly active = new Set<Control>();
  private readonly debugEvents: string[] = [];
  private readonly inputMode = navigator.maxTouchPoints > 0 ? "touch" : "pointer";
  private resetRequested = false;

  constructor() {
    window.addEventListener("keydown", this.onKeyDown, { passive: false });
    window.addEventListener("keyup", this.onKeyUp);
    document.addEventListener("visibilitychange", this.onVisibilityChange);

    document.querySelectorAll<HTMLButtonElement>("[data-control]").forEach((button) => {
      const control = button.dataset.control as Control;

      if (navigator.maxTouchPoints > 0) {
        const touchIds = new Set<number>();
        const press = (event: TouchEvent) => {
          event.preventDefault();
          if (control === "brake") this.releaseControl("throttle");
          for (const touch of event.changedTouches) touchIds.add(touch.identifier);
          this.active.add(control);
          button.classList.add("active");
          this.recordEvent(`touchstart ${control} total:${event.touches.length}`);
        };
        const release = (event: TouchEvent) => {
          event.preventDefault();
          for (const touch of event.changedTouches) touchIds.delete(touch.identifier);
          if (touchIds.size === 0) {
            this.active.delete(control);
            button.classList.remove("active");
          }
          this.recordEvent(`touchend ${control} total:${event.touches.length}`);
        };

        button.addEventListener("touchstart", press, { passive: false });
        button.addEventListener("touchend", release, { passive: false });
        button.addEventListener("touchcancel", (event) => {
          event.preventDefault();
          touchIds.clear();
          if (control !== "throttle") this.releaseControl(control);
          this.recordEvent(`touchcancel ${control} total:${event.touches.length}`);
        }, { passive: false });
        button.addEventListener("touchmove", (event) => event.preventDefault(), { passive: false });
        button.addEventListener("contextmenu", (event) => event.preventDefault());
        return;
      }

      const press = (event: PointerEvent) => {
        event.preventDefault();
        if (control === "brake") this.releaseControl("throttle");
        button.setPointerCapture(event.pointerId);
        this.active.add(control);
        button.classList.add("active");
        this.recordEvent(`pointerdown ${control} type:${event.pointerType}`);
      };
      const release = (event: PointerEvent) => {
        event.preventDefault();
        this.active.delete(control);
        button.classList.remove("active");
        this.recordEvent(`pointerup ${control} type:${event.pointerType}`);
      };
      const cancel = (event: PointerEvent) => {
        event.preventDefault();
        if (control !== "throttle") this.releaseControl(control);
        this.recordEvent(`pointercancel ${control} type:${event.pointerType}`);
      };
      button.addEventListener("pointerdown", press);
      button.addEventListener("pointerup", release);
      button.addEventListener("pointercancel", cancel);
      button.addEventListener("contextmenu", (event) => event.preventDefault());
    });

    document.querySelector<HTMLButtonElement>("#reset")?.addEventListener("click", () => {
      this.resetRequested = true;
    });
  }

  get steering(): number {
    return Number(this.active.has("right")) - Number(this.active.has("left"));
  }

  get throttle(): number {
    return Number(this.active.has("throttle"));
  }

  get brake(): number {
    return Number(this.active.has("brake"));
  }

  consumeReset(): boolean {
    const requested = this.resetRequested;
    this.resetRequested = false;
    return requested;
  }

  get debugText(): string {
    const active = [...this.active].join(",") || "nenhum";
    return [
      `entrada: ${this.inputMode} | toques: ${navigator.maxTouchPoints}`,
      `ativos: ${active}`,
      `T:${this.throttle} B:${this.brake} S:${this.steering}`,
      `página: ${document.visibilityState}`,
      ...this.debugEvents,
    ].join("\n");
  }

  dispose(): void {
    window.removeEventListener("keydown", this.onKeyDown);
    window.removeEventListener("keyup", this.onKeyUp);
    document.removeEventListener("visibilitychange", this.onVisibilityChange);
  }

  private readonly onKeyDown = (event: KeyboardEvent): void => {
    if (event.code === "KeyR") {
      this.resetRequested = true;
      return;
    }
    const control = KEY_TO_CONTROL[event.code];
    if (control) {
      event.preventDefault();
      this.active.add(control);
    }
  };

  private readonly onKeyUp = (event: KeyboardEvent): void => {
    const control = KEY_TO_CONTROL[event.code];
    if (control) this.active.delete(control);
  };

  private readonly releaseAll = (): void => {
    this.active.clear();
    document.querySelectorAll<HTMLButtonElement>("[data-control]").forEach((button) => {
      button.classList.remove("active");
    });
  };

  private readonly onVisibilityChange = (): void => {
    this.recordEvent(`visibility ${document.visibilityState}`);
    if (document.hidden) this.releaseAll();
  };

  private releaseControl(control: Control): void {
    this.active.delete(control);
    document.querySelector<HTMLButtonElement>(`[data-control="${control}"]`)?.classList.remove("active");
  }

  private recordEvent(message: string): void {
    this.debugEvents.unshift(`${Math.round(performance.now())}ms ${message}`);
    this.debugEvents.length = Math.min(this.debugEvents.length, 4);
  }
}
