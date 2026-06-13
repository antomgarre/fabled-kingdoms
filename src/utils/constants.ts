// ===== MUNDO =====
export const CHUNK_SIZE = 64;           // Vértices por lado del chunk
export const CHUNK_WORLD_SIZE = 100;    // Tamaño del chunk en unidades del mundo
export const RENDER_DISTANCE = 2;       // Chunks a renderizar en cada dirección (2 = 5x5 grid)
export const MAX_HEIGHT = 15;           // Altura máxima del terreno
export const WATER_LEVEL = 2;           // Nivel del agua

// ===== JUGADOR =====
export const PLAYER_SPEED = 5;          // Unidades por segundo
export const PLAYER_SPRINT_MULTIPLIER = 1.6;
export const PLAYER_HEIGHT = 2;         // Altura del modelo del jugador
export const GRAVITY = 20;              // Gravedad (unidades/s²)
export const JUMP_FORCE = 8;            // Fuerza de salto

// ===== CÁMARA =====
export const CAMERA_MIN_DISTANCE = 3;
export const CAMERA_MAX_DISTANCE = 20;
export const CAMERA_DEFAULT_DISTANCE = 8;
export const CAMERA_HEIGHT_OFFSET = 2;  // Altura sobre el jugador
export const CAMERA_SENSITIVITY = 0.003;
export const CAMERA_MIN_POLAR = 0.1;    // Evitar gimbal lock arriba
export const CAMERA_MAX_POLAR = Math.PI * 0.95; // Permitir mirar hacia arriba casi al máximo

// ===== TERRENO =====
export const TERRAIN_NOISE_SCALE = 0.008;    // Escala del ruido Perlin
export const TERRAIN_NOISE_OCTAVES = 4;      // Capas de ruido
export const TERRAIN_NOISE_PERSISTENCE = 0.4;
export const TERRAIN_NOISE_LACUNARITY = 2.0;

// ===== VEGETACIÓN =====
export const TREES_PER_CHUNK = 25;
export const TREE_MIN_HEIGHT = 3;
export const TREE_MAX_HEIGHT = 7;
export const TREE_MIN_TERRAIN_HEIGHT = 3;   // No poner árboles bajo el agua
export const TREE_MAX_TERRAIN_HEIGHT = 20;  // No poner árboles en cimas nevadas

// ===== COLORES (HSL convertidos a Three.js Color) =====
export const COLORS = {
  // Terreno por altura
  SAND: 0xc2b280,
  GRASS_LOW: 0x4a7c3f,
  GRASS_HIGH: 0x2d5a1e,
  ROCK: 0x6b6b6b,
  SNOW: 0xf0f0f0,
  // Agua
  WATER: 0x1a6b8a,
  WATER_DEEP: 0x0d4f6b,
  // Cielo
  SKY_TOP: 0x0a1628,
  SKY_BOTTOM: 0x4a90d9,
  SUN: 0xfff4e0,
  // Niebla
  FOG: 0x8fb8d9,
  // Árboles
  TRUNK: 0x5c3a1e,
  LEAVES: 0x2d7a2d,
} as const;
