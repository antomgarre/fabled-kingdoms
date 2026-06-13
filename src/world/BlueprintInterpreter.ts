import type { IRegionBlueprint, ILocation, INPC, IQuest, IAmbient, IConnection } from '../ai/types';
import { TerrainShaper } from './TerrainShaper';

/**
 * `BlueprintInterpreter` is the bridge between an AI-authored Region Blueprint
 * and the 3D engine. It takes the full `IRegionBlueprint` JSON and makes all
 * of its data available to the various engine systems:
 *
 * - **TerrainShaper** — for heightmap generation
 * - **Locations / NPCs / Quests** — for future placement and interaction
 * - **Ambient** — for atmosphere and audio systems
 *
 * Usage:
 * ```ts
 * const interpreter = new BlueprintInterpreter(blueprint);
 * const height = interpreter.getHeightAt(worldX, worldZ);
 * const locations = interpreter.getLocations();
 * ```
 */
export class BlueprintInterpreter {
  /** The original blueprint data */
  private blueprint: IRegionBlueprint;

  /** The terrain shaper created from the blueprint's terrain config */
  private terrainShaper: TerrainShaper;

  constructor(blueprint: IRegionBlueprint) {
    this.blueprint = blueprint;
    this.terrainShaper = new TerrainShaper(blueprint.terrain);
  }

  // -----------------------------------------------------------------------
  // Terrain
  // -----------------------------------------------------------------------

  /**
   * Returns the terrain height at the given world coordinates.
   * Delegates to the internal TerrainShaper.
   */
  public getHeightAt(worldX: number, worldZ: number): number {
    return this.terrainShaper.getHeight(worldX, worldZ);
  }

  /**
   * Returns the TerrainShaper instance for direct use by TerrainChunk
   * and TerrainGenerator.
   */
  public getTerrainShaper(): TerrainShaper {
    return this.terrainShaper;
  }

  // -----------------------------------------------------------------------
  // Region metadata
  // -----------------------------------------------------------------------

  /** Returns the unique region ID */
  public getRegionId(): string {
    return this.blueprint.regionId;
  }

  /** Returns the display name of the region */
  public getRegionName(): string {
    return this.blueprint.name;
  }

  /** Returns the narrative description of the region */
  public getDescription(): string {
    return this.blueprint.description;
  }

  /** Returns the deep lore text */
  public getLore(): string {
    return this.blueprint.lore;
  }

  // -----------------------------------------------------------------------
  // Locations
  // -----------------------------------------------------------------------

  /** Returns all locations in the region */
  public getLocations(): ReadonlyArray<ILocation> {
    return this.blueprint.locations;
  }

  /** Finds a location by name (case-insensitive) */
  public getLocationByName(name: string): ILocation | undefined {
    const lower = name.toLowerCase();
    return this.blueprint.locations.find(l => l.name.toLowerCase() === lower);
  }

  /** Returns locations of a specific type */
  public getLocationsByType(type: ILocation['type']): ReadonlyArray<ILocation> {
    return this.blueprint.locations.filter(l => l.type === type);
  }

  // -----------------------------------------------------------------------
  // NPCs
  // -----------------------------------------------------------------------

  /** Returns all NPCs in the region */
  public getNPCs(): ReadonlyArray<INPC> {
    return this.blueprint.npcs;
  }

  /** Finds an NPC by name (case-insensitive) */
  public getNPCByName(name: string): INPC | undefined {
    const lower = name.toLowerCase();
    return this.blueprint.npcs.find(n => n.name.toLowerCase() === lower);
  }

  /** Returns NPCs at a given location name */
  public getNPCsAtLocation(locationName: string): ReadonlyArray<INPC> {
    const lower = locationName.toLowerCase();
    return this.blueprint.npcs.filter(n => n.location.toLowerCase() === lower);
  }

  // -----------------------------------------------------------------------
  // Quests
  // -----------------------------------------------------------------------

  /** Returns all quests in the region */
  public getQuests(): ReadonlyArray<IQuest> {
    return this.blueprint.quests;
  }

  /** Returns quests given by a specific NPC name */
  public getQuestsByGiver(giverName: string): ReadonlyArray<IQuest> {
    const lower = giverName.toLowerCase();
    return this.blueprint.quests.filter(q => q.giver.toLowerCase() === lower);
  }

  // -----------------------------------------------------------------------
  // Ambient & Connections
  // -----------------------------------------------------------------------

  /** Returns the ambient atmosphere settings */
  public getAmbient(): Readonly<IAmbient> {
    return this.blueprint.ambient;
  }

  /** Returns the connections to neighboring regions */
  public getConnections(): Readonly<IConnection> {
    return this.blueprint.connections;
  }
}
