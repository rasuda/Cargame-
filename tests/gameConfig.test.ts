import { describe, expect, it } from "vitest";
import { metersPerSecondToKmh } from "../src/config/gameConfig";

describe("metersPerSecondToKmh", () => {
  it("converte velocidade e arredonda para o HUD", () => {
    expect(metersPerSecondToKmh(10)).toBe(36);
    expect(metersPerSecondToKmh(-5)).toBe(18);
  });
});
