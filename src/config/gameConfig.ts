export const GAME_CONFIG = {
  gravity: -9.81,
  car: {
    mass: 900,
    acceleration: 8_500,
    reverseAcceleration: 4_000,
    brakeForce: 13_000,
    steeringStrength: 1.7,
    maxSpeed: 34,
    maxReverseSpeed: 10,
    lateralGrip: 3_600,
    downforce: 1_200,
    linearDamping: 0.12,
    angularDamping: 0.82,
  },
  spawn: { x: 0, y: 1.2, z: -34 },
  camera: {
    distance: 11,
    height: 4.2,
    smoothing: 0.09,
  },
} as const;

export function metersPerSecondToKmh(speed: number): number {
  return Math.max(0, Math.round(Math.abs(speed) * 3.6));
}
