import { TerrainShaper } from '../world/TerrainShaper';
import type { ITerrainConfig } from '../ai/types';
import { CHUNK_SIZE, CHUNK_WORLD_SIZE, MAX_HEIGHT, WATER_LEVEL, COLORS } from '../utils/constants';

let shaper: TerrainShaper | null = null;
let localXArray: Float32Array | null = null;
let localZArray: Float32Array | null = null;

// Helper para interpolar colores (equivalente a THREE.Color.lerp)
function lerpColor(c1: number, c2: number, t: number): [number, number, number] {
  const r1 = (c1 >> 16) & 255;
  const g1 = (c1 >> 8) & 255;
  const b1 = c1 & 255;

  const r2 = (c2 >> 16) & 255;
  const g2 = (c2 >> 8) & 255;
  const b2 = c2 & 255;

  return [
    ((r1 + (r2 - r1) * t) / 255),
    ((g1 + (g2 - g1) * t) / 255),
    ((b1 + (b2 - b1) * t) / 255)
  ];
}

function hexToRGB(hex: number): [number, number, number] {
  return [
    ((hex >> 16) & 255) / 255,
    ((hex >> 8) & 255) / 255,
    (hex & 255) / 255
  ];
}

function getColorForHeight(height: number): [number, number, number] {
  if (height <= WATER_LEVEL) {
    return hexToRGB(COLORS.SAND);
  } else if (height <= MAX_HEIGHT * 0.3) {
    return hexToRGB(COLORS.GRASS_LOW);
  } else if (height <= MAX_HEIGHT * 0.6) {
    const t = (height - MAX_HEIGHT * 0.3) / (MAX_HEIGHT * 0.3);
    return lerpColor(COLORS.GRASS_LOW, COLORS.GRASS_HIGH, t);
  } else if (height <= MAX_HEIGHT * 0.8) {
    const t = (height - MAX_HEIGHT * 0.6) / (MAX_HEIGHT * 0.2);
    return lerpColor(COLORS.GRASS_HIGH, COLORS.ROCK, t);
  } else {
    const t = (height - MAX_HEIGHT * 0.8) / (MAX_HEIGHT * 0.2);
    return lerpColor(COLORS.ROCK, COLORS.SNOW, t);
  }
}

self.onmessage = (e: MessageEvent) => {
  const { type, payload } = e.data;

  if (type === 'init') {
    shaper = new TerrainShaper(payload.config as ITerrainConfig);
    localXArray = payload.localX;
    localZArray = payload.localZ;
  } else if (type === 'generate') {
    if (!shaper || !localXArray || !localZArray) return;
    
    const { chunkX, chunkZ, id } = payload;
    const vertexCount = CHUNK_SIZE * CHUNK_SIZE;
    
    // Arrays que transferiremos de vuelta
    const heights = new Float32Array(vertexCount);
    const colors = new Float32Array(vertexCount * 3);
    const normals = new Float32Array(vertexCount * 3);

    for (let i = 0; i < vertexCount; i++) {
        const worldX = chunkX * CHUNK_WORLD_SIZE + localXArray[i];
        const worldZ = chunkZ * CHUNK_WORLD_SIZE + localZArray[i];

        const height = shaper.getHeight(worldX, worldZ);
        heights[i] = height;

        const color = getColorForHeight(height);
        colors[i * 3] = color[0];
        colors[i * 3 + 1] = color[1];
        colors[i * 3 + 2] = color[2];

        // Cálculo de Normal Analítica Suave
        const d = 1.0;
        const hL = shaper.getHeight(worldX - d, worldZ);
        const hR = shaper.getHeight(worldX + d, worldZ);
        const hD = shaper.getHeight(worldX, worldZ - d);
        const hU = shaper.getHeight(worldX, worldZ + d);

        const dx = hR - hL;
        const dz = hU - hD;
        const dy = 2.0 * d;
        const len = Math.sqrt(dx * dx + dy * dy + dz * dz);
        
        normals[i * 3] = -dx / len;
        normals[i * 3 + 1] = dy / len;
        normals[i * 3 + 2] = -dz / len;
    }

    const ctx = self as unknown as Worker;
    ctx.postMessage(
      { type: 'result', payload: { id, chunkX, chunkZ, heights, colors, normals } },
      [heights.buffer, colors.buffer, normals.buffer]
    );
  }
};
