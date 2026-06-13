import { createNoise2D } from 'simplex-noise';
import {
  TERRAIN_NOISE_SCALE,
  TERRAIN_NOISE_OCTAVES,
  TERRAIN_NOISE_PERSISTENCE,
  TERRAIN_NOISE_LACUNARITY,
  MAX_HEIGHT,
} from './constants';

const noise2D = createNoise2D();

/**
 * Genera un valor de altura para una posición (x, z) del mundo.
 * Usa fractal Brownian motion (fBm) con múltiples octavas de simplex noise.
 * 
 * @param worldX - Coordenada X en el mundo
 * @param worldZ - Coordenada Z en el mundo
 * @returns Altura del terreno (0 a MAX_HEIGHT)
 */
export function getTerrainHeight(worldX: number, worldZ: number): number {
  let amplitude = 1;
  let frequency = TERRAIN_NOISE_SCALE;
  let noiseValue = 0;
  let maxAmplitude = 0;

  for (let i = 0; i < TERRAIN_NOISE_OCTAVES; i++) {
    noiseValue += amplitude * noise2D(worldX * frequency, worldZ * frequency);
    maxAmplitude += amplitude;
    amplitude *= TERRAIN_NOISE_PERSISTENCE;
    frequency *= TERRAIN_NOISE_LACUNARITY;
  }

  // Normalizar a [0, 1]
  noiseValue = (noiseValue / maxAmplitude + 1) / 2;

  return noiseValue * MAX_HEIGHT;
}
