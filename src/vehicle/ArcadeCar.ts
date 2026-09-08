import {
  Axis,
  Color3,
  Mesh,
  MeshBuilder,
  PhysicsAggregate,
  PhysicsPrestepType,
  PhysicsShapeType,
  Quaternion,
  Scene,
  StandardMaterial,
  Vector3,
} from "@babylonjs/core";
import { GAME_CONFIG } from "../config/gameConfig";
import type { InputController } from "../input/InputController";

const ZERO = Vector3.Zero();

export class ArcadeCar {
  readonly mesh: Mesh;
  private readonly physics: PhysicsAggregate;
  private readonly input: InputController;
  private readonly velocity = Vector3.Zero();
  private readonly angularVelocity = Vector3.Zero();
  private readonly wheelMeshes: Mesh[] = [];

  constructor(scene: Scene, input: InputController) {
    this.input = input;
    this.mesh = MeshBuilder.CreateBox("player-car", { width: 2.05, height: 0.72, depth: 4.25 }, scene);
    this.mesh.position.set(GAME_CONFIG.spawn.x, GAME_CONFIG.spawn.y, GAME_CONFIG.spawn.z);
    this.mesh.rotationQuaternion = Quaternion.Identity();

    const bodyMaterial = new StandardMaterial("car-body-material", scene);
    bodyMaterial.diffuseColor = Color3.FromHexString("#f05a28");
    bodyMaterial.specularColor = new Color3(0.55, 0.55, 0.55);
    this.mesh.material = bodyMaterial;

    this.createVisualDetails(scene);

    this.physics = new PhysicsAggregate(
      this.mesh,
      PhysicsShapeType.BOX,
      {
        mass: GAME_CONFIG.car.mass,
        friction: 0.82,
        restitution: 0.08,
      },
      scene,
    );
    this.physics.body.setLinearDamping(GAME_CONFIG.car.linearDamping);
    this.physics.body.setAngularDamping(GAME_CONFIG.car.angularDamping);
  }

  update(deltaSeconds: number): void {
    const body = this.physics.body;
    body.getLinearVelocityToRef(this.velocity);
    body.getAngularVelocityToRef(this.angularVelocity);

    const forward = this.mesh.getDirection(Axis.Z).normalize();
    const right = this.mesh.getDirection(Axis.X).normalize();
    const forwardSpeed = Vector3.Dot(this.velocity, forward);
    const lateralSpeed = Vector3.Dot(this.velocity, right);

    if (this.input.throttle > 0 && forwardSpeed < GAME_CONFIG.car.maxSpeed) {
      body.applyImpulse(
        forward.scale(GAME_CONFIG.car.acceleration * this.input.throttle * deltaSeconds),
        this.mesh.getAbsolutePosition(),
      );
    }

    if (this.input.brake > 0) {
      const force = forwardSpeed > 1.2
        ? -GAME_CONFIG.car.brakeForce
        : -GAME_CONFIG.car.reverseAcceleration;
      if (forwardSpeed > -GAME_CONFIG.car.maxReverseSpeed) {
        body.applyImpulse(forward.scale(force * deltaSeconds), this.mesh.getAbsolutePosition());
      }
    }

    const gripImpulse = right.scale(-lateralSpeed * GAME_CONFIG.car.lateralGrip * deltaSeconds);
    body.applyImpulse(gripImpulse, this.mesh.getAbsolutePosition());

    const speedRatio = Math.min(Math.abs(forwardSpeed) / 8, 1);
    const steeringDirection = forwardSpeed >= -0.2 ? 1 : -1;
    this.angularVelocity.y = this.input.steering
      * GAME_CONFIG.car.steeringStrength
      * speedRatio
      * steeringDirection;
    body.setAngularVelocity(this.angularVelocity);

    body.applyImpulse(
      new Vector3(0, -GAME_CONFIG.car.downforce * Math.abs(forwardSpeed) * deltaSeconds, 0),
      this.mesh.getAbsolutePosition(),
    );

    const wheelRotation = forwardSpeed * deltaSeconds / 0.42;
    for (const wheel of this.wheelMeshes) wheel.rotate(Axis.X, wheelRotation);
  }

  reset(): void {
    const body = this.physics.body;
    body.setLinearVelocity(ZERO);
    body.setAngularVelocity(ZERO);
    body.setPrestepType(PhysicsPrestepType.TELEPORT);
    this.mesh.position.set(GAME_CONFIG.spawn.x, GAME_CONFIG.spawn.y, GAME_CONFIG.spawn.z);
    this.mesh.rotationQuaternion?.copyFrom(Quaternion.Identity());
    this.mesh.computeWorldMatrix(true);

    window.setTimeout(() => body.setPrestepType(PhysicsPrestepType.DISABLED), 0);
  }

  get forwardSpeed(): number {
    this.physics.body.getLinearVelocityToRef(this.velocity);
    return Vector3.Dot(this.velocity, this.mesh.getDirection(Axis.Z));
  }

  dispose(): void {
    this.physics.dispose();
    this.mesh.dispose(false, true);
  }

  private createVisualDetails(scene: Scene): void {
    const glass = MeshBuilder.CreateBox("car-cabin", { width: 1.72, height: 0.58, depth: 1.85 }, scene);
    glass.parent = this.mesh;
    glass.position.set(0, 0.58, -0.2);
    const glassMaterial = new StandardMaterial("car-glass-material", scene);
    glassMaterial.diffuseColor = Color3.FromHexString("#172033");
    glassMaterial.specularColor = new Color3(0.9, 0.9, 0.95);
    glass.material = glassMaterial;

    const wheelMaterial = new StandardMaterial("wheel-material", scene);
    wheelMaterial.diffuseColor = new Color3(0.035, 0.035, 0.045);
    const positions = [
      [-1.05, -0.25, 1.35],
      [1.05, -0.25, 1.35],
      [-1.05, -0.25, -1.35],
      [1.05, -0.25, -1.35],
    ] as const;

    positions.forEach(([x, y, z], index) => {
      const wheel = MeshBuilder.CreateCylinder(
        `wheel-${index}`,
        { diameter: 0.82, height: 0.34, tessellation: 18 },
        scene,
      );
      wheel.parent = this.mesh;
      wheel.position.set(x, y, z);
      wheel.rotation.z = Math.PI / 2;
      wheel.material = wheelMaterial;
      this.wheelMeshes.push(wheel);
    });
  }
}
