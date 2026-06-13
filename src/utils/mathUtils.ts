import * as THREE from 'three';

/** Interpola linealmente entre a y b */
export function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

/** Clamp un valor entre min y max */
export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

/** Convierte coordenadas de mundo a coordenadas de chunk */
export function worldToChunk(worldX: number, worldZ: number, chunkWorldSize: number): { cx: number; cz: number } {
  return {
    cx: Math.floor(worldX / chunkWorldSize),
    cz: Math.floor(worldZ / chunkWorldSize),
  };
}

/** Genera una key string para identificar un chunk */
export function chunkKey(cx: number, cz: number): string {
  return `${cx},${cz}`;
}

/** Remap un valor de un rango a otro */
export function remap(value: number, inMin: number, inMax: number, outMin: number, outMax: number): number {
  return outMin + ((value - inMin) / (inMax - inMin)) * (outMax - outMin);
}
