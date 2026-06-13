import { describe, it, expect, vi, beforeEach } from 'vitest';
import * as THREE from 'three';
import { Game } from '../../../src/engine/Game';
import { AudioEngine } from '../../../src/engine/AudioEngine';
import { EnemyManager } from '../../../src/ai/EnemyManager';

describe('Audio Stress Test (Tier 4 Scenario 5)', () => {
  let enemyManager: EnemyManager;
  
  beforeEach(() => {
    const scene = new THREE.Scene();
    enemyManager = new EnemyManager(scene);
    
    Game.instance.audioEngine = new AudioEngine();
    Game.instance.enemyManager = enemyManager;
  });

  it('handles many simultaneous audio calls without crashing', () => {
    const playHitSpy = vi.spyOn(Game.instance.audioEngine, 'playEnemyHit').mockImplementation(() => {});
    
    enemyManager.init();
    const activeEnemies = enemyManager['activeEnemies'];
    const count = activeEnemies.length;
    expect(count).toBeGreaterThan(0);

    const center = new THREE.Vector3(0, 0, 0);
    for (const enemy of activeEnemies) {
        enemy.worldPosition.copy(center);
    }

    const playerPos = new THREE.Vector3(0, 0, 1);
    const playerDir = new THREE.Vector3(0, 0, -1);
    
    expect(() => {
        enemyManager.checkMeleeHit(playerPos, playerDir, 100, Math.PI * 2);
    }).not.toThrow();

    expect(playHitSpy).toHaveBeenCalledTimes(count);
  });
});
