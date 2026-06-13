import { describe, it, expect, beforeEach, afterAll } from 'vitest';
import * as THREE from 'three';
import fs from 'fs';
import path from 'path';
import { Persistence } from '../../../src/ai/GameMaster';
import { TerrainGenerator } from '../../../src/world/TerrainGenerator';
import { PlayerController } from '../../../src/player/PlayerController';
import { InputManager } from '../../../src/engine/InputManager';
import { MOCK_BLUEPRINT } from '../../../src/ai/mockBlueprint';
import { Game } from '../../../src/engine/Game';

// Mock Web Worker
global.Worker = class {
  postMessage() {}
  onmessage() {}
} as any;

describe('Player Enters Saved Region (Tier 4 Scenario 4)', () => {
  const testRegionId = 'tier4-enter-region-test';

  beforeEach(() => {
    Game.instance.vegetation = { treePositions: [] } as any;
    Game.instance.locationPlacer = { buildingBoxes: [] } as any;
  });

  afterAll(() => {
    const filePath = path.join(process.cwd(), 'data', `${testRegionId}.json`);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  });

  it('Player loads saved region and enters it', () => {
    Persistence.saveRegion(testRegionId, MOCK_BLUEPRINT);
    const loadedRegion = Persistence.loadRegion(testRegionId);
    expect(loadedRegion).toBeDefined();

    const scene = new THREE.Scene();
    
    const terrainShaper = {
        getHeight: () => 15,
        getBiomeMask: () => 0,
        config: {}
    };
    
    const terrainGenerator = new TerrainGenerator(scene, terrainShaper as any);
    
    const mockCanvas = document.createElement('canvas');
    const inputManager = new InputManager(mockCanvas);
    const camera = new THREE.PerspectiveCamera();
    
    const playerController = new PlayerController(scene, inputManager, terrainGenerator, camera);
    
    // Ground player
    playerController.update(0.1);
    
    expect(playerController.position.y).toBeCloseTo(15, 0);
    expect(playerController.isGrounded).toBe(true);
  });
});
