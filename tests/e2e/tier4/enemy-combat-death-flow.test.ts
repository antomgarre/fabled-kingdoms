import { describe, it, expect, vi, beforeEach } from 'vitest';
import * as THREE from 'three';
import { EnemyManager } from '../../../src/ai/EnemyManager';
import { Game } from '../../../src/engine/Game';
import { AudioEngine } from '../../../src/engine/AudioEngine';

describe('Enemy Combat & Death Flow (Tier 4 Scenario 3)', () => {
  let enemyManager: EnemyManager;
  let scene: THREE.Scene;

  beforeEach(() => {
    scene = new THREE.Scene();
    enemyManager = new EnemyManager(scene);
    
    Game.instance.audioEngine = new AudioEngine();
    Game.instance.enemyManager = enemyManager;
  });

  it('AI spawns creatures, creatures die and play death animation', () => {
    enemyManager.init();
    
    const activeEnemies = enemyManager['activeEnemies'];
    expect(activeEnemies.length).toBeGreaterThan(0);
    
    const targetEnemy = activeEnemies[0];
    const initialHealth = targetEnemy.health;
    
    const hitSpy = vi.spyOn(Game.instance.audioEngine, 'playEnemyHit').mockImplementation(() => {});
    
    // Simulate player attack at enemy's position
    const playerPos = targetEnemy.worldPosition.clone().add(new THREE.Vector3(0, 0, 1));
    const playerDir = new THREE.Vector3(0, 0, -1);
    
    // Attack
    enemyManager.checkMeleeHit(playerPos, playerDir, 2.0, Math.PI);
    
    expect(hitSpy).toHaveBeenCalled();
    expect(targetEnemy.health).toBeLessThan(initialHealth);
    
    // Deal fatal damage
    while(targetEnemy.health > 0) {
        enemyManager.checkMeleeHit(playerPos, playerDir, 2.0, Math.PI);
    }
    
    expect(targetEnemy.state).toBe('die');
    
    // Advance time to verify death animation progress
    const initialDeathProgress = targetEnemy.deathProgress;
    enemyManager.update(0.1, 0, playerPos, null as any);
    
    expect(targetEnemy.deathProgress).toBeGreaterThan(initialDeathProgress);
  });
});
