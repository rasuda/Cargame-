import {
  Color3,
  Color4,
  DirectionalLight,
  FreeCamera,
  HemisphericLight,
  Mesh,
  MeshBuilder,
  PhysicsAggregate,
  PhysicsShapeType,
  Scene,
  ShadowGenerator,
  StandardMaterial,
  Vector3,
} from "@babylonjs/core";

function material(scene: Scene, name: string, hex: string): StandardMaterial {
  const result = new StandardMaterial(name, scene);
  result.diffuseColor = Color3.FromHexString(hex);
  result.specularColor = new Color3(0.12, 0.12, 0.12);
  return result;
}

function makeStaticBox(
  scene: Scene,
  name: string,
  size: { width: number; height: number; depth: number },
  position: Vector3,
  boxMaterial: StandardMaterial,
  rotationX = 0,
  collidable = true,
): Mesh {
  const box = MeshBuilder.CreateBox(name, size, scene);
  box.position.copyFrom(position);
  box.rotation.x = rotationX;
  box.material = boxMaterial;
  if (collidable) {
    new PhysicsAggregate(box, PhysicsShapeType.BOX, { mass: 0, friction: 0.9, restitution: 0.05 }, scene);
  }
  return box;
}

export function createScene(scene: Scene): { camera: FreeCamera; shadow: ShadowGenerator } {
  scene.clearColor = new Color4(0.53, 0.72, 0.9, 1);
  scene.fogMode = Scene.FOGMODE_LINEAR;
  scene.fogColor = new Color3(0.53, 0.72, 0.9);
  scene.fogStart = 75;
  scene.fogEnd = 150;

  const camera = new FreeCamera("chase-camera", new Vector3(0, 6, -45), scene);
  camera.minZ = 0.15;
  camera.fov = 0.88;

  const ambient = new HemisphericLight("ambient", new Vector3(0, 1, 0), scene);
  ambient.intensity = 0.72;
  ambient.groundColor = new Color3(0.22, 0.25, 0.3);

  const sun = new DirectionalLight("sun", new Vector3(-0.45, -1, 0.35), scene);
  sun.position.set(30, 50, -25);
  sun.intensity = 2.1;
  const shadow = new ShadowGenerator(1024, sun);
  shadow.usePercentageCloserFiltering = true;
  shadow.bias = 0.002;

  const asphalt = material(scene, "asphalt", "#30343b");
  const concrete = material(scene, "concrete", "#a6a49d");
  const grass = material(scene, "grass", "#567c43");
  const orange = material(scene, "barrier-orange", "#e75b1e");
  const white = material(scene, "road-white", "#e8e6dc");
  const red = material(scene, "barrier-red", "#b7372d");

  makeStaticBox(scene, "ground", { width: 180, height: 1, depth: 180 }, new Vector3(0, -0.55, 15), grass);
  makeStaticBox(scene, "road", { width: 15, height: 0.18, depth: 120 }, new Vector3(0, 0, 12), asphalt);
  makeStaticBox(scene, "cross-road", { width: 95, height: 0.2, depth: 16 }, new Vector3(0, 0.02, 32), asphalt);

  for (let z = -38; z <= 64; z += 8) {
    makeStaticBox(
      scene,
      `lane-${z}`,
      { width: 0.18, height: 0.008, depth: 4.2 },
      new Vector3(0, 0.098, z),
      white,
      0,
      false,
    );
  }

  for (let x = -42; x <= 42; x += 8) {
    makeStaticBox(
      scene,
      `cross-lane-${x}`,
      { width: 4.2, height: 0.008, depth: 0.18 },
      new Vector3(x, 0.124, 32),
      white,
      0,
      false,
    );
  }

  makeStaticBox(scene, "ramp", { width: 5.3, height: 0.7, depth: 8 }, new Vector3(0, 0.14, 17), concrete, -0.1);

  const barriers = [
    [-5.9, 0.65, 21], [5.9, 0.65, 21], [-5.9, 0.65, 27], [5.9, 0.65, 27],
    [-11, 0.65, 39], [11, 0.65, 39], [-18, 0.65, 25], [18, 0.65, 25],
  ] as const;
  barriers.forEach(([x, y, z], index) => {
    const barrier = makeStaticBox(
      scene,
      `barrier-${index}`,
      { width: 3.2, height: 1.25, depth: 0.8 },
      new Vector3(x, y, z),
      index % 2 === 0 ? orange : red,
    );
    shadow.addShadowCaster(barrier);
  });

  for (const side of [-1, 1]) {
    for (let z = -20; z <= 70; z += 18) {
      const building = makeStaticBox(
        scene,
        `building-${side}-${z}`,
        { width: 13, height: 7 + ((z + 20) % 23), depth: 11 },
        new Vector3(side * 18, 5, z),
        material(scene, `building-mat-${side}-${z}`, side > 0 ? "#667489" : "#8b715f"),
      );
      shadow.addShadowCaster(building);
    }
  }

  return { camera, shadow };
}
