import { describe, it, expect, vi, beforeEach } from 'vitest';
import * as THREE from 'three';
import { PlayerController } from '../../../src/player/PlayerController';
import { InputManager } from '../../../src/engine/InputManager';
import { Game } from '../../../src/engine/Game';
import { AudioEngine } from '../../../src/engine/AudioEngine';

// Mock Web Worker to avoid issues in Node/JSDOM
global.Worker = class {
  postMessage() {}
  onmessage() {}
} as any;

describe('Player Combat Flow (Tier 4 Scenario 1)', () => {
  let playerController: PlayerController;
  let inputManager: InputManager;
  let terrainGenerator: any;
  let camera: THREE.PerspectiveCamera;
  let scene: THREE.Scene;

  beforeEach(() => {
    // Inject mock dependencies into Game instance
    const game = Game.instance;
    game.audioEngine = new AudioEngine();
    game.vegetation = { treePositions: [] } as any;
    game.locationPlacer = { buildingBoxes: [] } as any;

    const mockCanvas = document.createElement('canvas');
    inputManager = new InputManager(mockCanvas);
    
    terrainGenerator = {
      getHeightAt: () => 0,
      getVisualHeightAt: () => 0
    };
    camera = new THREE.PerspectiveCamera();
    scene = new THREE.Scene();

    playerController = new PlayerController(scene, inputManager, terrainGenerator as any, camera);
  });

  it('Player moves, swings weapon, triggers audio and skeletal animations', () => {
    const footstepSpy = vi.spyOn(Game.instance.audioEngine, 'playFootstep').mockImplementation(() => {});
    const swordSwingSpy = vi.spyOn(Game.instance.audioEngine, 'playSwordSwing').mockImplementation(() => {});

    // Mock pressing 'KeyW'
    vi.spyOn(inputManager, 'isKeyDown').mockImplementation((key) => key === 'KeyW');

    // Move to build velocity and trigger walk cycle
    for (let i = 0; i < 50; i++) {
        playerController.update(0.1);
    }

    expect(playerController.velocity.length()).toBeGreaterThan(0);
    expect(footstepSpy).toHaveBeenCalled();

    // Now attack (mock pressing left click)
    vi.spyOn(inputManager, 'consumeLeftClick').mockReturnValue(true);

    playerController.update(0.1);

    expect(swordSwingSpy).toHaveBeenCalled();
    expect(playerController['isAttacking']).toBe(true);

    // Update again to advance attack progress
    playerController.update(0.1);

    // Assert animation pivot changes
    expect(playerController.model.rightArmPivot.rotation.x).not.toBe(0);
  });
});
