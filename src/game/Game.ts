import HavokPhysics from "@babylonjs/havok";
import {
  Engine,
  HavokPlugin,
  Matrix,
  Scene,
  Vector3,
} from "@babylonjs/core";
import { GAME_CONFIG, metersPerSecondToKmh } from "../config/gameConfig";
import { InputController } from "../input/InputController";
import { ArcadeCar } from "../vehicle/ArcadeCar";
import { createScene } from "./createScene";

export class Game {
  private readonly engine: Engine;
  private readonly input = new InputController();
  private scene?: Scene;
  private car?: ArcadeCar;
  private hasDriven = false;
  private cameraTouchId: number | null = null;
  private cameraTouchX = 0;
  private cameraTouchY = 0;
  private cameraYaw = 0;
  private cameraHeight: number = GAME_CONFIG.camera.height;

  constructor(private readonly canvas: HTMLCanvasElement) {
    this.engine = new Engine(canvas, true, {
      adaptToDeviceRatio: true,
      preserveDrawingBuffer: false,
      stencil: true,
    });
    this.canvas.addEventListener("touchstart", this.onCameraTouchStart, { passive: false });
    this.canvas.addEventListener("touchmove", this.onCameraTouchMove, { passive: false });
    this.canvas.addEventListener("touchend", this.onCameraTouchEnd, { passive: false });
    this.canvas.addEventListener("touchcancel", this.onCameraTouchEnd, { passive: false });
  }

  async start(): Promise<void> {
    const havok = await HavokPhysics();
    const scene = new Scene(this.engine);
    scene.enablePhysics(new Vector3(0, GAME_CONFIG.gravity, 0), new HavokPlugin(true, havok));
    scene.getPhysicsEngine()?.setTimeStep(1 / 60);

    const { camera, shadow } = createScene(scene);
    const car = new ArcadeCar(scene, this.input);
    for (const visualMesh of car.mesh.getChildMeshes()) shadow.addShadowCaster(visualMesh);

    this.scene = scene;
    this.car = car;

    const speedElement = document.querySelector<HTMLSpanElement>("#speed");
    const instructions = document.querySelector<HTMLDivElement>("#instructions");
    const loading = document.querySelector<HTMLDivElement>("#loading");
    const debugPanel = document.querySelector<HTMLPreElement>("#debug-panel");

    scene.onBeforeRenderObservable.add(() => {
      const delta = Math.min(this.engine.getDeltaTime() / 1000, 1 / 20);
      car.update(delta);

      if (this.input.consumeReset() || car.mesh.position.y < -8) car.reset();

      const forward = Vector3.TransformNormal(
        car.mesh.forward.normalize(),
        Matrix.RotationY(this.cameraYaw),
      );
      const desiredPosition = car.mesh.position
        .subtract(forward.scale(GAME_CONFIG.camera.distance))
        .add(new Vector3(0, this.cameraHeight, 0));
      camera.position.copyFrom(Vector3.Lerp(camera.position, desiredPosition, GAME_CONFIG.camera.smoothing));
      camera.setTarget(car.mesh.position.add(new Vector3(0, 0.65, 0)));

      const speed = metersPerSecondToKmh(car.forwardSpeed);
      if (speedElement) speedElement.textContent = String(speed);
      if (debugPanel) {
        const position = car.mesh.position;
        debugPanel.textContent = [
          this.input.debugText,
          "propulsão: impulso/quadro",
          `atrito carroceria: ${GAME_CONFIG.car.bodyFriction.toFixed(2)}`,
          "apoio: 4 rodas",
          "rodas: eixo X",
          `câmera: ${Math.round(this.cameraYaw * 180 / Math.PI)}° | ${this.cameraHeight.toFixed(1)}m`,
          `velocidade: ${car.forwardSpeed.toFixed(3)} m/s`,
          `posição: ${position.x.toFixed(2)}, ${position.y.toFixed(2)}, ${position.z.toFixed(2)}`,
        ].join("\n");
      }
      if (!this.hasDriven && (this.input.throttle > 0 || this.input.brake > 0)) {
        this.hasDriven = true;
        instructions?.classList.add("hidden");
      }
    });

    this.engine.runRenderLoop(() => scene.render());
    window.addEventListener("resize", this.resize);
    loading?.classList.add("done");
  }

  dispose(): void {
    window.removeEventListener("resize", this.resize);
    this.canvas.removeEventListener("touchstart", this.onCameraTouchStart);
    this.canvas.removeEventListener("touchmove", this.onCameraTouchMove);
    this.canvas.removeEventListener("touchend", this.onCameraTouchEnd);
    this.canvas.removeEventListener("touchcancel", this.onCameraTouchEnd);
    this.input.dispose();
    this.car?.dispose();
    this.scene?.dispose();
    this.engine.dispose();
  }

  private readonly resize = (): void => this.engine.resize();

  private readonly onCameraTouchStart = (event: TouchEvent): void => {
    if (this.cameraTouchId !== null) return;
    const touch = event.changedTouches[0];
    if (!touch) return;
    event.preventDefault();
    this.cameraTouchId = touch.identifier;
    this.cameraTouchX = touch.clientX;
    this.cameraTouchY = touch.clientY;
  };

  private readonly onCameraTouchMove = (event: TouchEvent): void => {
    if (this.cameraTouchId === null) return;
    const touch = Array.from(event.changedTouches).find(({ identifier }) => identifier === this.cameraTouchId);
    if (!touch) return;
    event.preventDefault();

    const deltaX = touch.clientX - this.cameraTouchX;
    const deltaY = touch.clientY - this.cameraTouchY;
    this.cameraYaw -= deltaX * 0.008;
    this.cameraHeight = Math.max(1.8, Math.min(9, this.cameraHeight + deltaY * 0.018));
    this.cameraTouchX = touch.clientX;
    this.cameraTouchY = touch.clientY;
  };

  private readonly onCameraTouchEnd = (event: TouchEvent): void => {
    if (this.cameraTouchId === null) return;
    const ended = Array.from(event.changedTouches).some(({ identifier }) => identifier === this.cameraTouchId);
    if (!ended) return;
    event.preventDefault();
    this.cameraTouchId = null;
  };
}
