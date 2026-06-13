import { createNoise2D } from 'simplex-noise';
import type { ITerrainConfig, ITerrainFeature, RegionPosition, FeaturePath } from '../ai/types';
import { CHUNK_WORLD_SIZE, MAX_HEIGHT, WATER_LEVEL } from '../utils/constants';
import { clamp } from '../utils/mathUtils';

function seededRandom(seed: number): () => number {
  let s = seed;
  return () => {
    s = (s * 16807) % 2147483647;
    return s / 2147483647;
  };
}

const noise2D = createNoise2D(seededRandom(12345));
const detailNoise = createNoise2D(seededRandom(54321));

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/** The world-space radius of the "region" that a blueprint covers. */
const REGION_RADIUS = CHUNK_WORLD_SIZE * 1.5;

// ---------------------------------------------------------------------------
// Helpers — position / path → world coordinates
// ---------------------------------------------------------------------------

interface Vec2 {
  x: number;
  z: number;
}

/**
 * Converts a compass-style `RegionPosition` to normalised coordinates
 * in the range [-1, 1] relative to the region centre.
 */
function positionToNorm(pos: RegionPosition): Vec2 {
  const map: Record<RegionPosition, Vec2> = {
    center:         { x:  0,    z:  0    },
    north:          { x:  0,    z: -0.6  },
    south:          { x:  0,    z:  0.6  },
    east:           { x:  0.6,  z:  0    },
    west:           { x: -0.6,  z:  0    },
    northeast:      { x:  0.5,  z: -0.5  },
    northwest:      { x: -0.5,  z: -0.5  },
    southeast:      { x:  0.5,  z:  0.5  },
    southwest:      { x: -0.5,  z:  0.5  },
    center_north:   { x:  0,    z: -0.35 },
    center_south:   { x:  0,    z:  0.35 },
    center_east:    { x:  0.35, z:  0    },
    center_west:    { x: -0.35, z:  0    },
    northeast_edge: { x:  0.85, z: -0.85 },
    northwest_edge: { x: -0.85, z: -0.85 },
    southeast_edge: { x:  0.85, z:  0.85 },
    southwest_edge: { x: -0.85, z:  0.85 },
    north_edge:     { x:  0,    z: -0.9  },
    south_edge:     { x:  0,    z:  0.9  },
    east_edge:      { x:  0.9,  z:  0    },
    west_edge:      { x: -0.9,  z:  0    },
  };
  return map[pos] ?? { x: 0, z: 0 };
}

/**
 * Returns a start and end normalised position for a `FeaturePath`.
 */
function pathToEndpoints(path: FeaturePath): { start: Vec2; end: Vec2 } {
  const map: Record<FeaturePath, { start: Vec2; end: Vec2 }> = {
    north_to_south:          { start: { x:  0,   z: -1 }, end: { x:  0,   z:  1   } },
    south_to_north:          { start: { x:  0,   z:  1 }, end: { x:  0,   z: -1   } },
    east_to_west:            { start: { x:  1,   z:  0 }, end: { x: -1,   z:  0   } },
    west_to_east:            { start: { x: -1,   z:  0 }, end: { x:  1,   z:  0   } },
    north_to_southeast:      { start: { x: -0.3, z: -1 }, end: { x:  0.8, z:  0.8 } },
    north_to_southwest:      { start: { x:  0.3, z: -1 }, end: { x: -0.8, z:  0.8 } },
    northwest_to_southeast:  { start: { x: -0.9, z: -0.9 }, end: { x: 0.9, z: 0.9 } },
    northeast_to_southwest:  { start: { x:  0.9, z: -0.9 }, end: { x: -0.9, z: 0.9 } },
    west_to_southeast:       { start: { x: -1,   z: -0.2 }, end: { x: 0.8, z: 0.8 } },
    east_to_southwest:       { start: { x:  1,   z: -0.2 }, end: { x: -0.8, z: 0.8 } },
  };
  return map[path] ?? { start: { x: 0, z: -1 }, end: { x: 0, z: 1 } };
}

/**
 * Returns the shortest distance from a point to a line segment.
 */
function distToSegment(px: number, pz: number, ax: number, az: number, bx: number, bz: number): number {
  const dx = bx - ax;
  const dz = bz - az;
  const lenSq = dx * dx + dz * dz;
  if (lenSq === 0) return Math.sqrt((px - ax) ** 2 + (pz - az) ** 2);

  let t = ((px - ax) * dx + (pz - az) * dz) / lenSq;
  t = clamp(t, 0, 1);

  const projX = ax + t * dx;
  const projZ = az + t * dz;
  return Math.sqrt((px - projX) ** 2 + (pz - projZ) ** 2);
}

// ---------------------------------------------------------------------------
// Fractal Brownian Motion helper
// ---------------------------------------------------------------------------

/**
 * Multi-octave fBm using the module-level noise2D.
 */
function fbm(x: number, z: number, octaves: number, frequency: number, persistence: number, lacunarity: number): number {
  let value = 0;
  let amplitude = 1;
  let maxAmp = 0;
  let freq = frequency;

  for (let i = 0; i < octaves; i++) {
    value += amplitude * noise2D(x * freq, z * freq);
    maxAmp += amplitude;
    amplitude *= persistence;
    freq *= lacunarity;
  }

  // Normalise to [0, 1]
  return (value / maxAmp + 1) / 2;
}

// ---------------------------------------------------------------------------
// TerrainShaper
// ---------------------------------------------------------------------------

/**
 * `TerrainShaper` replaces the raw Perlin/Simplex heightmap with terrain
 * generation guided by an AI-authored `ITerrainConfig`.
 *
 * The terrain type determines the base heightmap algorithm, and terrain
 * features (rivers, hills, clearings, etc.) are applied as modifiers on
 * top of the base.
 *
 * Usage:
 * ```ts
 * const shaper = new TerrainShaper(blueprint.terrain);
 * const h = shaper.getHeight(worldX, worldZ);
 * ```
 */
export class TerrainShaper {
  public config: ITerrainConfig;

  /** Elevation offset derived from baseElevation */
  private elevationOffset: number;

  constructor(config: ITerrainConfig) {
    this.config = config;

    // Map baseElevation to a height offset
    switch (config.baseElevation) {
      case 'low':    this.elevationOffset = 0; break;
      case 'medium': this.elevationOffset = MAX_HEIGHT * 0.15; break;
      case 'high':   this.elevationOffset = MAX_HEIGHT * 0.35; break;
    }
  }

  // -----------------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------------

  /**
   * Returns the terrain height at the given world-space position.
   * Combines base terrain type heightmap + feature modifications.
   */
  public getHeight(worldX: number, worldZ: number): number {
    let height = this.getBaseHeight(worldX, worldZ);

    // Apply each feature modifier
    for (const feature of this.config.features) {
      height = this.applyFeature(feature, worldX, worldZ, height);
    }

    return clamp(height, 0, MAX_HEIGHT);
  }

  // -----------------------------------------------------------------------
  // Base terrain type heightmap generators
  // -----------------------------------------------------------------------

  private getBaseHeight(x: number, z: number): number {
    switch (this.config.type) {
      case 'flat_plains':      return this.flatPlains(x, z);
      case 'rolling_hills':    return this.rollingHills(x, z);
      case 'mountain_valley':  return this.mountainValley(x, z);
      case 'dense_forest':     return this.denseForest(x, z);
      case 'coastal':          return this.coastal(x, z);
      case 'river_delta':      return this.riverDelta(x, z);
      case 'highland_plateau': return this.highlandPlateau(x, z);
      case 'canyon':           return this.canyon(x, z);
      case 'swamp':            return this.swamp(x, z);
      case 'volcanic':         return this.volcanic(x, z);
    }
  }

  /**
   * Flat plains — very low amplitude noise producing gentle undulations.
   * Max height ≈ 3–4.
   */
  private flatPlains(x: number, z: number): number {
    const base = fbm(x, z, 3, 0.008, 0.4, 2.0);
    const detail = fbm(x, z, 2, 0.03, 0.3, 2.0);
    return this.elevationOffset + WATER_LEVEL + 0.5 + base * 3.0 + detail * 0.5;
  }

  /**
   * Rolling hills — smooth, medium-amplitude curves. Max height ≈ 8–10.
   */
  private rollingHills(x: number, z: number): number {
    const broad = fbm(x, z, 4, 0.006, 0.5, 2.0);
    const medium = fbm(x, z, 3, 0.015, 0.4, 2.2);
    const detail = fbm(x, z, 2, 0.04, 0.25, 2.0);
    return this.elevationOffset + WATER_LEVEL + 1.0 + broad * 6.0 + medium * 2.5 + detail * 0.5;
  }

  /**
   * Mountain valley — high ridges along the edges, low valley in the centre.
   */
  private mountainValley(x: number, z: number): number {
    // Distance from centre (normalised)
    const nx = x / REGION_RADIUS;
    const nz = z / REGION_RADIUS;
    const distFromCenter = Math.sqrt(nx * nx + nz * nz);

    // Edges rise, centre is low
    const valleyShape = clamp(distFromCenter * 1.2, 0, 1);
    const base = fbm(x, z, 5, 0.008, 0.55, 2.1);

    const valleyFloor = WATER_LEVEL + 1.0 + base * 3.0;
    const ridgeHeight = MAX_HEIGHT * 0.7 + base * MAX_HEIGHT * 0.3;

    return this.elevationOffset + valleyFloor + (ridgeHeight - valleyFloor) * valleyShape * valleyShape;
  }

  /**
   * Dense forest — medium, irregular terrain good for thick canopy.
   */
  private denseForest(x: number, z: number): number {
    const base = fbm(x, z, 4, 0.01, 0.5, 2.0);
    const bumps = fbm(x, z, 3, 0.035, 0.45, 2.3);
    return this.elevationOffset + WATER_LEVEL + 1.5 + base * 5.0 + bumps * 2.0;
  }

  /**
   * Coastal — slopes downward toward one side (east → water).
   */
  private coastal(x: number, z: number): number {
    // Slope: western side is high, eastern side is at water level
    const slope = clamp((x / REGION_RADIUS + 1) / 2, 0, 1); // 0 = west (high), 1 = east (low)
    const base = fbm(x, z, 4, 0.012, 0.5, 2.0);
    const landHeight = WATER_LEVEL + 2.0 + base * 8.0;
    return this.elevationOffset + landHeight * (1 - slope * 0.85);
  }

  /**
   * River delta — low-lying wetland with channels.
   */
  private riverDelta(x: number, z: number): number {
    const base = fbm(x, z, 3, 0.008, 0.4, 2.0);
    const channels = Math.abs(noise2D(x * 0.02, z * 0.02));
    const channelCarve = channels < 0.3 ? (0.3 - channels) * 4 : 0;
    return this.elevationOffset + WATER_LEVEL + 0.3 + base * 2.0 - channelCarve;
  }

  /**
   * Highland plateau — elevated flat top with steep edges.
   */
  private highlandPlateau(x: number, z: number): number {
    const nx = x / REGION_RADIUS;
    const nz = z / REGION_RADIUS;
    const dist = Math.max(Math.abs(nx), Math.abs(nz));

    // Sigmoid-like edge transition
    const edge = 1 / (1 + Math.exp(-(dist - 0.7) * 12));
    const plateauHeight = MAX_HEIGHT * 0.5;
    const baseVariation = fbm(x, z, 3, 0.01, 0.4, 2.0) * 2.0;

    return this.elevationOffset + (plateauHeight + baseVariation) * (1 - edge) + (WATER_LEVEL + 1) * edge;
  }

  /**
   * Canyon — deep gorge between high walls.
   */
  private canyon(x: number, z: number): number {
    // Canyon runs roughly north-south
    const nz = z / REGION_RADIUS;
    const canyonWidth = 0.25 + 0.1 * Math.sin(nz * 3.0);
    const nx = Math.abs(x / REGION_RADIUS);

    const wallShape = clamp((nx - canyonWidth) / 0.15, 0, 1);
    const base = fbm(x, z, 4, 0.01, 0.5, 2.0);
    const floorHeight = WATER_LEVEL + 0.5 + base * 1.5;
    const wallHeight = MAX_HEIGHT * 0.6 + base * MAX_HEIGHT * 0.2;

    return this.elevationOffset + floorHeight + (wallHeight - floorHeight) * wallShape;
  }

  /**
   * Swamp — low, waterlogged terrain with hummocks.
   */
  private swamp(x: number, z: number): number {
    const base = fbm(x, z, 3, 0.01, 0.4, 2.0);
    const hummocks = fbm(x, z, 2, 0.05, 0.6, 2.5);
    const height = WATER_LEVEL - 0.3 + base * 2.5 + hummocks * 1.0;
    return this.elevationOffset + height;
  }

  /**
   * Volcanic — rugged, jagged terrain with a central peak.
   */
  private volcanic(x: number, z: number): number {
    const nx = x / REGION_RADIUS;
    const nz = z / REGION_RADIUS;
    const distFromCenter = Math.sqrt(nx * nx + nz * nz);

    // Central cone
    const cone = Math.max(0, 1 - distFromCenter * 1.5) * MAX_HEIGHT * 0.8;
    // Jagged detail
    const jagged = fbm(x, z, 5, 0.02, 0.6, 2.3) * 4.0;
    // Crater at very top
    const craterDip = distFromCenter < 0.15 ? (0.15 - distFromCenter) * MAX_HEIGHT * 2 : 0;

    return this.elevationOffset + WATER_LEVEL + 1.0 + cone + jagged - craterDip;
  }

  // -----------------------------------------------------------------------
  // Feature modifiers
  // -----------------------------------------------------------------------

  /**
   * Applies a single terrain feature modification to the current height.
   */
  private applyFeature(feature: ITerrainFeature, worldX: number, worldZ: number, currentHeight: number): number {
    switch (feature.type) {
      case 'river':     return this.applyRiver(feature, worldX, worldZ, currentHeight);
      case 'hill':      return this.applyHill(feature, worldX, worldZ, currentHeight);
      case 'lake':      return this.applyLake(feature, worldX, worldZ, currentHeight);
      case 'cliff':     return this.applyCliff(feature, worldX, worldZ, currentHeight);
      case 'clearing':  return this.applyClearing(feature, worldX, worldZ, currentHeight);
      case 'ravine':    return this.applyRavine(feature, worldX, worldZ, currentHeight);
      case 'plateau':   return this.applyPlateau(feature, worldX, worldZ, currentHeight);
      case 'waterfall': return this.applyRiver(feature, worldX, worldZ, currentHeight); // Similar to river
      default:          return currentHeight;
    }
  }

  /**
   * River — carves a path between two region edges, lowering terrain along it.
   */
  private applyRiver(feature: ITerrainFeature, worldX: number, worldZ: number, currentHeight: number): number {
    if (!feature.path) return currentHeight;

    const { start, end } = pathToEndpoints(feature.path);
    const sx = start.x * REGION_RADIUS;
    const sz = start.z * REGION_RADIUS;
    const ex = end.x * REGION_RADIUS;
    const ez = end.z * REGION_RADIUS;

    // Add some winding to the river using noise
    const windX = detailNoise(worldZ * 0.01, 0) * REGION_RADIUS * 0.15;
    const windZ = detailNoise(0, worldX * 0.01) * REGION_RADIUS * 0.15;

    const dist = distToSegment(worldX + windX, worldZ + windZ, sx, sz, ex, ez);
    const riverWidth = 12; // world units
    const bankWidth = 8;   // soft transition zone

    if (dist < riverWidth) {
      // Inside the river — carve down to water level
      const t = dist / riverWidth;
      const carveDepth = (1 - t * t) * 3.0; // parabolic profile
      return Math.min(currentHeight, WATER_LEVEL - carveDepth * 0.3);
    } else if (dist < riverWidth + bankWidth) {
      // Bank zone — blend smoothly toward the river
      const t = (dist - riverWidth) / bankWidth;
      const bankHeight = WATER_LEVEL + 0.5;
      return currentHeight * t + bankHeight * (1 - t);
    }

    return currentHeight;
  }

  /**
   * Hill — adds a gaussian bump at a position.
   */
  private applyHill(feature: ITerrainFeature, worldX: number, worldZ: number, currentHeight: number): number {
    const pos = positionToNorm(feature.position ?? 'center');
    const cx = pos.x * REGION_RADIUS;
    const cz = pos.z * REGION_RADIUS;

    const heightMult = feature.height === 'high' ? 1.0 : feature.height === 'low' ? 0.4 : 0.65;
    const radius = 40;
    const peakAdd = MAX_HEIGHT * 0.25 * heightMult;

    const dx = worldX - cx;
    const dz = worldZ - cz;
    const distSq = dx * dx + dz * dz;
    const radiusSq = radius * radius;

    if (distSq < radiusSq * 4) {
      const gauss = Math.exp(-distSq / (2 * radiusSq));
      return currentHeight + peakAdd * gauss;
    }

    return currentHeight;
  }

  /**
   * Lake — flattens an area to water level.
   */
  private applyLake(feature: ITerrainFeature, worldX: number, worldZ: number, currentHeight: number): number {
    const pos = positionToNorm(feature.position ?? 'center');
    const cx = pos.x * REGION_RADIUS;
    const cz = pos.z * REGION_RADIUS;

    const radius = feature.size === 'large' ? 50 : feature.size === 'small' ? 20 : 35;
    const bankWidth = 10;

    const dx = worldX - cx;
    const dz = worldZ - cz;
    const dist = Math.sqrt(dx * dx + dz * dz);

    if (dist < radius) {
      return WATER_LEVEL - 0.5;
    } else if (dist < radius + bankWidth) {
      const t = (dist - radius) / bankWidth;
      return WATER_LEVEL - 0.5 + (currentHeight - WATER_LEVEL + 0.5) * t;
    }

    return currentHeight;
  }

  /**
   * Cliff — creates a sharp height transition at a position.
   */
  private applyCliff(feature: ITerrainFeature, worldX: number, worldZ: number, currentHeight: number): number {
    const pos = positionToNorm(feature.position ?? 'center');
    const cx = pos.x * REGION_RADIUS;

    // Cliff runs perpendicular to the position's x — a vertical wall
    const dist = worldX - cx;
    const cliffHeight = MAX_HEIGHT * 0.3;
    const transition = 5; // very narrow for sharpness

    const sigmoid = 1 / (1 + Math.exp(-dist / transition));
    return currentHeight + cliffHeight * sigmoid;
  }

  /**
   * Clearing — flattens a circular area to a smooth, level surface.
   */
  private applyClearing(feature: ITerrainFeature, worldX: number, worldZ: number, currentHeight: number): number {
    const pos = positionToNorm(feature.position ?? 'center');
    const cx = pos.x * REGION_RADIUS;
    const cz = pos.z * REGION_RADIUS;

    const radius = feature.size === 'large' ? 40 : feature.size === 'small' ? 15 : 25;
    const blendWidth = 10;

    const dx = worldX - cx;
    const dz = worldZ - cz;
    const dist = Math.sqrt(dx * dx + dz * dz);

    if (dist < radius + blendWidth) {
      // The clearing flattens to the average height (approximate with a fixed comfortable value)
      const clearingHeight = currentHeight > WATER_LEVEL + 2 ? WATER_LEVEL + 3 : currentHeight;

      if (dist < radius) {
        return clearingHeight;
      }
      const t = (dist - radius) / blendWidth;
      return clearingHeight + (currentHeight - clearingHeight) * t;
    }

    return currentHeight;
  }

  /**
   * Ravine — a narrow, deep cut in the terrain.
   */
  private applyRavine(feature: ITerrainFeature, worldX: number, worldZ: number, currentHeight: number): number {
    // Similar to river but deeper and narrower
    if (!feature.path && !feature.position) return currentHeight;

    if (feature.path) {
      const { start, end } = pathToEndpoints(feature.path);
      const sx = start.x * REGION_RADIUS;
      const sz = start.z * REGION_RADIUS;
      const ex = end.x * REGION_RADIUS;
      const ez = end.z * REGION_RADIUS;

      const dist = distToSegment(worldX, worldZ, sx, sz, ex, ez);
      const ravineWidth = 6;

      if (dist < ravineWidth) {
        const t = dist / ravineWidth;
        const depth = (1 - t * t) * MAX_HEIGHT * 0.25;
        return currentHeight - depth;
      }
    }

    return currentHeight;
  }

  /**
   * Plateau — a small flat-topped elevation.
   */
  private applyPlateau(feature: ITerrainFeature, worldX: number, worldZ: number, currentHeight: number): number {
    const pos = positionToNorm(feature.position ?? 'center');
    const cx = pos.x * REGION_RADIUS;
    const cz = pos.z * REGION_RADIUS;

    const radius = feature.size === 'large' ? 50 : feature.size === 'small' ? 20 : 35;
    const blendWidth = 8;
    const plateauHeight = currentHeight + MAX_HEIGHT * 0.15;

    const dx = worldX - cx;
    const dz = worldZ - cz;
    const dist = Math.sqrt(dx * dx + dz * dz);

    if (dist < radius) {
      return plateauHeight;
    } else if (dist < radius + blendWidth) {
      const t = (dist - radius) / blendWidth;
      return plateauHeight + (currentHeight - plateauHeight) * t;
    }

    return currentHeight;
  }
}
