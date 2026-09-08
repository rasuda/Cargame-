import HavokPhysics from "@babylonjs/havok";
import {
  Engine,
  HavokPlugin,
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

  constructor(canvas: HTMLCanvasElement) {
    this.engine = new Engine(canvas, true, {
      adaptToDeviceRatio: true,
      preserveDrawingBuffer: false,
      stencil: true,
    });
  }

  async start(): Promise<void> {
    const havok = await HavokPhysics();
    const scene = new Scene(this.engine);
    scene.enablePhysics(new Vector3(0, GAME_CONFIG.gravity, 0), new HavokPlugin(true, havok));
    scene.getPhysicsEngine()?.setTimeStep(1 / 60);

    const { camera, shadow } = createScene(scene);
    const car = new ArcadeCar(scene, this.input);
    shadow.addShadowCaster(car.mesh);

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

      const forward = car.mesh.forward.normalize();
      const desiredPosition = car.mesh.position
        .subtract(forward.scale(GAME_CONFIG.camera.distance))
        .add(new Vector3(0, GAME_CONFIG.camera.height, 0));
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
    this.input.dispose();
    this.car?.dispose();
    this.scene?.dispose();
    this.engine.dispose();
  }

  private readonly resize = (): void => this.engine.resize();
}
