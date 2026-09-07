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
  private resetRequested = false;

  constructor() {
    window.addEventListener("keydown", this.onKeyDown, { passive: false });
    window.addEventListener("keyup", this.onKeyUp);
    window.addEventListener("blur", this.releaseAll);

    document.querySelectorAll<HTMLButtonElement>("[data-control]").forEach((button) => {
      const control = button.dataset.control as Control;
      const press = (event: PointerEvent) => {
        event.preventDefault();
        button.setPointerCapture(event.pointerId);
        this.active.add(control);
        button.classList.add("active");
      };
      const release = (event: PointerEvent) => {
        event.preventDefault();
        this.active.delete(control);
        button.classList.remove("active");
      };
      button.addEventListener("pointerdown", press);
      button.addEventListener("pointerup", release);
      button.addEventListener("pointercancel", release);
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

  dispose(): void {
    window.removeEventListener("keydown", this.onKeyDown);
    window.removeEventListener("keyup", this.onKeyUp);
    window.removeEventListener("blur", this.releaseAll);
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
  };
}
