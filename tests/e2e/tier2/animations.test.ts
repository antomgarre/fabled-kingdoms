import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import * as THREE from 'three';
import { PlayerController } from '../../../src/player/PlayerController';
import { InputManager } from '../../../src/engine/InputManager';
import { Game } from '../../../src/engine/Game';

describe('Player Animation States (Tier 2 Boundary/Corner Cases)', () => {
  let playerController: PlayerController;
  let inputManager: InputManager;
  let terrainGenerator: any;
  let camera: THREE.PerspectiveCamera;
  let scene: THREE.Scene;

  beforeEach(() => {
    const game = Game.instance;
    game.timeManager = { elapsedTime: 0 } as any;
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

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('Test 1: Empty State - Model initializes and smoothly transitions to Idle breathing', () => {
    // Initial height is 0.6 from constructor setup
    expect(playerController.model.bodyPivot.position.y).toBeCloseTo(0.6, 1);
    
    // Update advances breathing animation
    playerController.update(0.1);
    
    // Position should be driven by sine wave: 0.55 + sin(...) * 0.02
    expect(playerController.model.bodyPivot.position.y).toBeLessThan(0.6);
  });

  it('Test 2: Invalid State Transitions - Cannot trigger Attack animation while airborne', () => {
    playerController.isGrounded = false;
    
    vi.spyOn(inputManager, 'consumeLeftClick').mockReturnValue(true);
    
    playerController.update(0.1);
    
    // Should NOT attack because not grounded
    expect(playerController['isAttacking']).toBe(false);
    expect(playerController.model.rightArmPivot.rotation.x).toBe(0);
  });

  it('Test 3: Rapid State Changes - Attack animation cannot be interrupted by rapid clicking', () => {
    playerController.isGrounded = true;
    
    const clickSpy = vi.spyOn(inputManager, 'consumeLeftClick').mockReturnValue(true);
    
    // 1st click
    playerController.update(0.1); 
    expect(playerController['isAttacking']).toBe(true);
    const armRotation1 = playerController.model.rightArmPivot.rotation.x;
    
    // Rapid 2nd click
    clickSpy.mockReturnValue(true);
    playerController.update(0.1);
    
    // Timer should progress, not reset
    expect(playerController['attackTimer']).toBeCloseTo(0.2, 3);
    const armRotation2 = playerController.model.rightArmPivot.rotation.x;
    
    // Animation progresses naturally
    expect(armRotation1).not.toBe(armRotation2);
  });

  it('Test 4: Missing Animations / Fallback - Conflicting movements cancel out to Idle', () => {
    playerController.isGrounded = true;
    
    // W and S pressed together
    vi.spyOn(inputManager, 'isKeyDown').mockImplementation((key) => key === 'KeyW' || key === 'KeyS');
    
    playerController.update(0.1);
    playerController.update(0.1);
    
    // Velocity targets 0
    expect(playerController['currentVelZ']).toBeCloseTo(0, 3);
    
    // Legs lerp to 0 (Idle)
    expect(playerController.model.leftLegPivot.rotation.x).toBeCloseTo(0, 1);
    expect(playerController.model.rightLegPivot.rotation.x).toBeCloseTo(0, 1);
  });

  it('Test 5: Extreme Input / Rapid State Change - High velocity is capped or animates smoothly without NaN', () => {
    playerController.isGrounded = true;
    
    // Inject massive velocity
    playerController['currentVelX'] = 10000;
    playerController['currentVelZ'] = 10000;
    
    expect(() => {
        playerController.update(0.1);
    }).not.toThrow();
    
    // Math should remain valid
    expect(isNaN(playerController.model.leftLegPivot.rotation.x)).toBe(false);
    expect(isNaN(playerController.model.capePivot.rotation.x)).toBe(false);
  });
});
