// ============================================================================
// AI Content Engine — Region Blueprint Types
// ============================================================================
// These interfaces define the structured JSON that the AI generates to describe
// a game region. The 3D engine interprets these blueprints to build the world.
// ============================================================================

// ---------------------------------------------------------------------------
// Union types for terrain, features, and locations
// ---------------------------------------------------------------------------

/**
 * The base terrain archetype for a region.
 * Each type maps to a distinct heightmap generation algorithm in TerrainShaper.
 */
export type TerrainType =
  | 'flat_plains'       // Gentle, nearly flat terrain with subtle undulations
  | 'rolling_hills'     // Smooth, medium-amplitude hills and valleys
  | 'mountain_valley'   // High ridges along edges with a low valley center
  | 'dense_forest'      // Irregular, medium terrain suited for thick canopy
  | 'coastal'           // Slopes from land down to water on one side
  | 'river_delta'       // Low-lying wetland terrain with branching channels
  | 'highland_plateau'  // Elevated flat top with steep edges
  | 'canyon'            // Deep gorge cut between high walls
  | 'swamp'             // Low, waterlogged terrain with hummocks
  | 'volcanic';         // Rugged, jagged terrain with a central peak

/**
 * Types of terrain features that modify the base heightmap.
 * These are applied on top of the base terrain type.
 */
export type FeatureType =
  | 'river'             // Carves a flowing path through the terrain
  | 'hill'              // Adds a localized elevated bump
  | 'lake'              // Flattens an area to water level
  | 'cliff'             // Creates a sharp vertical height transition
  | 'clearing'          // Flattens a circular area (for meadows, camps)
  | 'ravine'            // A narrow, deep cut in the terrain
  | 'plateau'           // A small flat-topped elevation
  | 'waterfall';        // A river feature that drops sharply

/**
 * Types of notable locations that can be placed in a region.
 */
export type LocationType =
  | 'village'           // A settlement with buildings and NPCs
  | 'ruins'             // Crumbling ancient structures
  | 'landmark'          // A natural or magical point of interest
  | 'cave'              // An entrance to an underground area
  | 'shrine'            // A small sacred site
  | 'camp'              // A temporary encampment
  | 'tower'             // A standing fortification or watch post
  | 'bridge'            // A constructed crossing over water or a chasm
  | 'portal';           // A magical gateway to another region

/**
 * Compass-style position identifiers used by the AI to place features
 * and locations within a region, without specifying exact coordinates.
 */
export type RegionPosition =
  | 'center'
  | 'north'
  | 'south'
  | 'east'
  | 'west'
  | 'northeast'
  | 'northwest'
  | 'southeast'
  | 'southwest'
  | 'center_north'
  | 'center_south'
  | 'center_east'
  | 'center_west'
  | 'northeast_edge'
  | 'northwest_edge'
  | 'southeast_edge'
  | 'southwest_edge'
  | 'north_edge'
  | 'south_edge'
  | 'east_edge'
  | 'west_edge';

/**
 * Path descriptors for linear features like rivers.
 * Describes the start-to-end flow direction across the region.
 */
export type FeaturePath =
  | 'north_to_south'
  | 'south_to_north'
  | 'east_to_west'
  | 'west_to_east'
  | 'north_to_southeast'
  | 'north_to_southwest'
  | 'northwest_to_southeast'
  | 'northeast_to_southwest'
  | 'west_to_southeast'
  | 'east_to_southwest';

// ---------------------------------------------------------------------------
// Feature, location, NPC, quest, ambient, and connection interfaces
// ---------------------------------------------------------------------------

/**
 * A terrain feature that modifies the base heightmap of the region.
 * Features overlay the base terrain type with localized modifications.
 */
export interface ITerrainFeature {
  /** The kind of terrain modification */
  type: FeatureType;
  /** A narrative name for this feature (e.g., "Río Aethel") */
  name: string;
  /** Where in the region this feature is located (for point features) */
  position?: RegionPosition;
  /** The path this feature follows (for linear features like rivers) */
  path?: FeaturePath;
  /** Relative height: 'low', 'medium', or 'high' */
  height?: 'low' | 'medium' | 'high';
  /** Relative size/radius: 'small', 'medium', or 'large' */
  size?: 'small' | 'medium' | 'large';
  /** A narrative description of this feature */
  description: string;
}

/**
 * Configuration for a region's terrain generation.
 * Combines a base terrain type with overlaid features and vegetation rules.
 */
export interface ITerrainConfig {
  /** The base terrain archetype */
  type: TerrainType;
  /** Base elevation level: affects the overall height offset */
  baseElevation: 'low' | 'medium' | 'high';
  /** Specific terrain features that modify the base heightmap */
  features: ITerrainFeature[];
  /** General vegetation style (e.g., 'temperate_meadow', 'boreal_forest') */
  vegetationStyle: string;
  /** How dense the vegetation is */
  vegetationDensity: 'sparse' | 'medium' | 'dense';
  /** Types of trees that dominate this region */
  dominantTrees: string[];
  /** Types of ground cover plants */
  groundCover: string[];
}

/**
 * A building within a location (village, etc.).
 */
export interface IBuilding {
  /** The function of this building */
  type: 'tavern' | 'shop' | 'elder_house' | 'blacksmith' | 'temple' | 'barracks' | 'stable' | 'warehouse' | 'house';
  /** The name of this building */
  name: string;
}

/**
 * A notable location within the region — a point of interest
 * that the player can discover and interact with.
 */
export interface ILocation {
  /** The category of this location */
  type: LocationType;
  /** A proper name for this location */
  name: string;
  /** Where in the region this location sits */
  position: RegionPosition;
  /** Relative size of this location */
  size?: 'small' | 'medium' | 'large';
  /** Narrative description of the location */
  description: string;
  /** The race or faction that inhabits this location (if any) */
  population?: string;
  /** The general feeling of this place */
  atmosphere?: string;
  /** Buildings present at this location (primarily for villages) */
  buildings?: IBuilding[];
  /** Danger level from 1-10 */
  dangerLevel?: number;
  /** Quality of loot found here */
  lootQuality?: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';
}

/**
 * A non-player character that inhabits the region.
 * NPCs have personality, dialogue, and purpose.
 */
export interface INPC {
  /** The NPC's name */
  name: string;
  /** The NPC's functional role in the world */
  role: 'quest_giver' | 'merchant' | 'guard' | 'wanderer' | 'elder' | 'craftsman' | 'healer' | 'bard' | 'warrior';
  /** The NPC's race/species */
  race: 'human' | 'elf' | 'dwarf' | 'halfling' | 'orc' | 'fae' | 'dragonborn' | 'tiefling';
  /** Where this NPC can be found (building name or location name) */
  location: string;
  /** Comma-separated personality traits */
  personality: string;
  /** The first thing this NPC says when the player approaches */
  greeting: string;
  /** A short backstory that informs the NPC's behavior */
  backstory: string;
}

/**
 * A quest or mission available in this region.
 * Quests connect to the region's lore and NPCs.
 */
export interface IQuest {
  /** The quest's display name */
  name: string;
  /** The category of quest */
  type: 'exploration' | 'combat' | 'fetch' | 'escort' | 'mystery' | 'delivery' | 'defense';
  /** The name of the NPC who gives this quest */
  giver: string;
  /** A narrative description of the quest objective */
  description: string;
  /** How challenging this quest is */
  difficulty: 'easy' | 'medium' | 'hard' | 'legendary';
  /** Reward identifiers (items, reputation, lore unlocks, etc.) */
  rewards: string[];
}

/**
 * Ambient atmosphere settings for the region.
 * Controls the mood through lighting, sound, weather, and effects.
 */
export interface IAmbient {
  /** Preferred time-of-day lighting (e.g., 'eternal_golden_hour', 'midnight') */
  timeOfDayPreference: string;
  /** Weather conditions (e.g., 'clear_with_warm_breeze', 'light_rain') */
  weather: string;
  /** Ambient sound descriptions */
  sounds: string[];
  /** The musical mood for this region's soundtrack */
  musicMood: string;
  /** Visual particle effects active in this region */
  particleEffects: string[];
}

/**
 * PvP rules for a region.
 */
export interface IPvPRules {
  /** The PvP zone type */
  type: 'safe_zone' | 'contested' | 'free_pvp' | 'arena';
  /** Narrative explanation of the PvP rules */
  description: string;
}

/**
 * Connections from this region to neighboring regions.
 * Each cardinal direction can reference another region.
 */
export interface IConnection {
  /** What lies to the north */
  north?: string;
  /** What lies to the south */
  south?: string;
  /** What lies to the east */
  east?: string;
  /** What lies to the west */
  west?: string;
}

// ---------------------------------------------------------------------------
// The main Region Blueprint interface
// ---------------------------------------------------------------------------

/**
 * A complete Region Blueprint — the structured JSON output from the AI
 * Content Engine. This is the primary data structure that drives world
 * generation: every aspect of a region (terrain, locations, NPCs, quests,
 * lore, atmosphere) is defined here.
 *
 * The AI writes these like a game designer, and the 3D engine interprets
 * them into a living, explorable world.
 */
export interface IRegionBlueprint {
  /** Unique identifier for this region (snake_case) */
  regionId: string;
  /** Display name of the region */
  name: string;
  /** A rich narrative description of the region */
  description: string;
  /** Terrain generation configuration */
  terrain: ITerrainConfig;
  /** Notable locations within the region */
  locations: ILocation[];
  /** Non-player characters inhabiting the region */
  npcs: INPC[];
  /** Quests available in this region */
  quests: IQuest[];
  /** Ambient atmosphere settings */
  ambient: IAmbient;
  /** PvP rules for this region */
  pvpRules: IPvPRules;
  /** Deep lore and history of this region */
  lore: string;
  /** What lies in each cardinal direction */
  connections: IConnection;
}
