import * as THREE from 'three';
import { Game } from '../engine/Game';
import { EnemyModel } from './EnemyModel';
import { TerrainGenerator } from '../world/TerrainGenerator';
import { lerp } from '../utils/mathUtils';

interface EnemyEntity {
  id: string;
  model: EnemyModel;
  worldPosition: THREE.Vector3;
  state: 'idle' | 'chase' | 'attack' | 'die';
  deathProgress: number;
  health: number;
  attackTimer: number;
}

export class EnemyManager {
  private activeEnemies: EnemyEntity[] = [];
  
  constructor(private scene: THREE.Scene) {}

  public init() {
    this.spawnEnemies();
  }

  private spawnEnemies() {
    // Generate 20 goblins scattered around the world, outside the village exclusion zone
    const numEnemies = 20;
    const spawnRadius = 80;
    const safeRadius = 30; // Village is safe
    
    for (let i = 0; i < numEnemies; i++) {
      let x = 0;
      let z = 0;
      let dist = 0;
      
      // Retry until we find a spot outside the safe radius
      let tries = 0;
      do {
        x = (Math.random() - 0.5) * spawnRadius * 2;
        z = (Math.random() - 0.5) * spawnRadius * 2;
        dist = Math.sqrt(x*x + z*z);
        tries++;
      } while (dist < safeRadius && tries < 100);

      if (dist >= safeRadius) {
        const model = new EnemyModel();
        model.mesh.position.set(x, 0, z); // Y will be updated by terrain
        this.scene.add(model.mesh);

        this.activeEnemies.push({
          id: `goblin_${i}`,
          model,
          worldPosition: new THREE.Vector3(x, 0, z),
          state: 'idle',
          deathProgress: 0,
          health: 1,
          attackTimer: 0
        });
      }
    }
  }

  public update(dt: number, time: number, playerPos: THREE.Vector3, terrainGenerator: TerrainGenerator) {
    const CHASE_RADIUS = 15;
    const SPEED = 3.0;
    const STOP_DIST = 1.5;

    for (let i = this.activeEnemies.length - 1; i >= 0; i--) {
      const enemy = this.activeEnemies[i];

      // Update model animation mixer
      enemy.model.update(dt);

      if (enemy.state === 'die') {
        enemy.deathProgress += dt * 0.2; // Dies in ~5s
        enemy.model.playState('death'); // or 'die'
        
        if (enemy.deathProgress >= 1.0) {
          this.scene.remove(enemy.model.mesh);
          this.activeEnemies.splice(i, 1);
        }
        continue;
      }

      // 1. Terrain Height Adjust
      if (terrainGenerator) {
        const visualHeight = terrainGenerator.getVisualHeightAt(enemy.worldPosition.x, enemy.worldPosition.z);
        if (visualHeight !== null) {
          enemy.worldPosition.y = lerp(enemy.worldPosition.y, visualHeight, 10 * dt);
        }
      }

      // 2. IA Logic
      const distToPlayer = enemy.worldPosition.distanceTo(playerPos);
      
      if (distToPlayer <= STOP_DIST) {
        enemy.state = 'attack';
      } else if (distToPlayer < CHASE_RADIUS) {
        enemy.state = 'chase';
      } else {
        enemy.state = 'idle';
      }

      if (enemy.state === 'attack') {
        enemy.model.playState('attack');
        
        // Look at player
        const dir = new THREE.Vector3().subVectors(playerPos, enemy.worldPosition);
        dir.y = 0;
        if (dir.lengthSq() > 0) dir.normalize();
        const lookTarget = enemy.worldPosition.clone().add(dir);
        enemy.model.mesh.lookAt(lookTarget);

        // Attack Animation
        enemy.attackTimer += dt;
        if (enemy.attackTimer > 1.0) { // 1 attack per second
          enemy.attackTimer = 0;
          // Trigger Damage
          const hud = document.getElementById('damage-overlay');
          if (!hud) {
            const div = document.createElement('div');
            div.id = 'damage-overlay';
            div.style.position = 'absolute';
            div.style.top = '0';
            div.style.left = '0';
            div.style.width = '100vw';
            div.style.height = '100vh';
            div.style.backgroundColor = 'rgba(255, 0, 0, 0.4)';
            div.style.pointerEvents = 'none';
            div.style.transition = 'opacity 0.2s';
            div.style.opacity = '1';
            document.body.appendChild(div);
            setTimeout(() => { div.style.opacity = '0'; }, 100);
            setTimeout(() => { document.body.removeChild(div); }, 300);
          }
        }

      } else if (enemy.state === 'chase') {
        enemy.attackTimer = 0;
        enemy.model.playState('walk'); // Maps to walk/run
        
        // Move towards player
        const dir = new THREE.Vector3().subVectors(playerPos, enemy.worldPosition);
        dir.y = 0;
        if (dir.lengthSq() > 0) dir.normalize();
        
        enemy.worldPosition.x += dir.x * SPEED * dt;
        enemy.worldPosition.z += dir.z * SPEED * dt;
        
        // Look at player
        const lookTarget = enemy.worldPosition.clone().add(dir);
        enemy.model.mesh.lookAt(lookTarget);
        
      } else {
        enemy.attackTimer = 0;
        enemy.model.playState('idle');
      }

      // Update mesh pos
      enemy.model.mesh.position.copy(enemy.worldPosition);
    }
  }

  // Called by PlayerController during an attack
  public checkMeleeHit(playerPos: THREE.Vector3, playerDir: THREE.Vector3, attackRange: number, attackAngle: number) {
    for (const enemy of this.activeEnemies) {
      if (enemy.state === 'die') continue;

      const dist = enemy.worldPosition.distanceTo(playerPos);
      if (dist <= attackRange) {
        // Check angle
        const dirToEnemy = new THREE.Vector3().subVectors(enemy.worldPosition, playerPos);
        dirToEnemy.y = 0;
        dirToEnemy.normalize();
        
        const angleToEnemy = playerDir.angleTo(dirToEnemy);
        if (angleToEnemy <= attackAngle / 2) {
          // HIT!
          enemy.health -= 1;
          Game.instance.audioEngine?.playSound('enemy_hit', enemy.worldPosition);
          if (enemy.health <= 0) {
            enemy.state = 'die';
            // Spawn some dust
            Game.instance.dustSystem?.spawn(enemy.worldPosition.x, enemy.worldPosition.y + 0.5, enemy.worldPosition.z);
          }
        }
      }
    }
  }
}
