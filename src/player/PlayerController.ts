import * as THREE from 'three';
import { Game } from '../engine/Game';
import { InputManager } from '../engine/InputManager';
import { TerrainGenerator } from '../world/TerrainGenerator';
import { PlayerModel } from './PlayerModel';
import { ThirdPersonCamera } from './ThirdPersonCamera';
import { getTerrainHeight } from '../utils/noise';
import { lerp } from '../utils/mathUtils';
import {
  PLAYER_SPEED,
  PLAYER_SPRINT_MULTIPLIER,
  GRAVITY,
  JUMP_FORCE
} from '../utils/constants';

export class PlayerController {
  public position: THREE.Vector3 = new THREE.Vector3(0, 0, 0);
  public velocity: THREE.Vector3 = new THREE.Vector3(0, 0, 0);
  public isGrounded: boolean = false;
  
  // Smooth horizontal velocity for lerp-based acceleration
  private currentVelX: number = 0;
  private currentVelZ: number = 0;
  private animationTime: number = 0;

  // Combat State
  private isAttacking: boolean = false;
  private attackTimer: number = 0;
  private attackDuration: number = 0.4; // seconds
  private hasHitDealt: boolean = false;

  public model: PlayerModel;
  public cameraController: ThirdPersonCamera;

  constructor(
    private scene: THREE.Scene,
    private inputManager: InputManager,
    private terrainGenerator: TerrainGenerator,
    camera: THREE.PerspectiveCamera
  ) {
    this.model = new PlayerModel();
    this.scene.add(this.model.mesh);
    
    this.cameraController = new ThirdPersonCamera(camera, inputManager);

    // Inicializar posición Y basándose en el terreno para no caer desde el cielo
    const startY = this.terrainGenerator.getHeightAt(0, 0);
    this.position.set(0, startY, 0);
    this.model.mesh.position.copy(this.position);
  }

  /** Calculate terrain slope at a position by sampling 4 neighboring heights */
  private getTerrainSlope(x: number, z: number): number {
    const d = 0.5;
    const hL = getTerrainHeight(x - d, z);
    const hR = getTerrainHeight(x + d, z);
    const hD = getTerrainHeight(x, z - d);
    const hU = getTerrainHeight(x, z + d);

    const dx = (hR - hL) / (2 * d);
    const dz = (hU - hD) / (2 * d);

    return Math.sqrt(dx * dx + dz * dz);
  }

  /** Check if moving in the given direction is going uphill */
  private isMovingUphill(moveDir: THREE.Vector3, x: number, z: number): boolean {
    const d = 0.5;
    const hHere = getTerrainHeight(x, z);
    const hAhead = getTerrainHeight(x + moveDir.x * d, z + moveDir.z * d);
    return hAhead > hHere;
  }

  public update(deltaTime: number): void {
    // 1. Movimiento XZ relativo a la cámara
    let inputZ = 0;
    let inputX = 0;

    if (this.inputManager.isKeyDown('KeyW')) inputZ -= 1;
    if (this.inputManager.isKeyDown('KeyS')) inputZ += 1;
    if (this.inputManager.isKeyDown('KeyA')) inputX -= 1;
    if (this.inputManager.isKeyDown('KeyD')) inputX += 1;

    // Obtener direcciones de cámara en XZ plano
    const camDir = new THREE.Vector3();
    this.cameraController['camera'].getWorldDirection(camDir);
    camDir.y = 0;
    camDir.normalize();

    const camRight = new THREE.Vector3();
    camRight.crossVectors(camDir, new THREE.Vector3(0, 1, 0)).normalize();

    const moveDir = new THREE.Vector3();
    moveDir.addScaledVector(camDir, -inputZ);
    moveDir.addScaledVector(camRight, inputX);
    if (moveDir.length() > 1) moveDir.normalize();

    let speed = PLAYER_SPEED;
    if (this.inputManager.isKeyDown('ShiftLeft')) {
      speed *= PLAYER_SPRINT_MULTIPLIER;
    }

    // Slope detection
    const slope = this.getTerrainSlope(this.position.x, this.position.z);
    const movingUphill = moveDir.length() > 0 && this.isMovingUphill(moveDir, this.position.x, this.position.z);

    // If slope > 0.7 (~45 degrees) and moving uphill, block movement
    if (slope > 0.7 && movingUphill) {
      speed = 0;
    } else if (movingUphill) {
      // Reduce speed going uphill based on slope
      speed *= Math.max(0.2, 1 - slope * 0.5);
    }

    // Target velocity
    const targetVelX = moveDir.x * speed;
    const targetVelZ = moveDir.z * speed;

    // Smooth acceleration/deceleration via lerp
    let lerpFactor = 1 - Math.exp(-10 * deltaTime); // Smooth ~10Hz response
    if (inputX === 0 && inputZ === 0) {
      lerpFactor = 1 - Math.exp(-30 * deltaTime); // Sharp stop (Snappy)
    }
    
    this.currentVelX = lerp(this.currentVelX, targetVelX, lerpFactor);
    this.currentVelZ = lerp(this.currentVelZ, targetVelZ, lerpFactor);

    this.velocity.x = this.currentVelX;
    this.velocity.z = this.currentVelZ;

    // 2. Gravedad y Salto
    this.velocity.y -= GRAVITY * deltaTime;
    
    if (this.isGrounded && this.inputManager.isKeyDown('Space')) {
      this.velocity.y = JUMP_FORCE;
      this.isGrounded = false;
    }

    // 3. Aplicar movimiento
    this.position.x += this.velocity.x * deltaTime;
    this.position.z += this.velocity.z * deltaTime;

    // Colisión simple con árboles
    const trees = Game.instance.vegetation.treePositions;
    for (const tree of trees) {
      const dist = Math.hypot(this.position.x - tree.x, this.position.z - tree.z);
      if (dist < 1.0 && dist > 0.001) {
        const pushForce = 1.0 - dist;
        this.position.x += ((this.position.x - tree.x) / dist) * pushForce;
        this.position.z += ((this.position.z - tree.z) / dist) * pushForce;
      }
    }

    // Colisión con edificios
    if (Game.instance.locationPlacer) {
      const playerBox = new THREE.Box3(
        new THREE.Vector3(this.position.x - 0.5, this.position.y, this.position.z - 0.5),
        new THREE.Vector3(this.position.x + 0.5, this.position.y + 1.8, this.position.z + 0.5)
      );
      
      for (const bBox of Game.instance.locationPlacer.buildingBoxes) {
        if (playerBox.intersectsBox(bBox)) {
          const overlapX = Math.min(playerBox.max.x - bBox.min.x, bBox.max.x - playerBox.min.x);
          const overlapZ = Math.min(playerBox.max.z - bBox.min.z, bBox.max.z - playerBox.min.z);
          
          if (overlapX < overlapZ) {
            this.position.x += (this.position.x < (bBox.min.x + bBox.max.x) / 2) ? -overlapX : overlapX;
          } else {
            this.position.z += (this.position.z < (bBox.min.z + bBox.max.z) / 2) ? -overlapZ : overlapZ;
          }
        }
      }
    }

    this.position.y += this.velocity.y * deltaTime;

    // 4. Colisión con terreno
    let terrainHeight = this.terrainGenerator.getVisualHeightAt(this.position.x, this.position.z);
    if (terrainHeight === null) {
      terrainHeight = this.terrainGenerator.getHeightAt(this.position.x, this.position.z);
    }
    
    if (this.position.y <= terrainHeight + 0.2) {
      this.position.y = lerp(this.position.y, terrainHeight, 15 * deltaTime);
      if (this.velocity.y < 0) this.velocity.y = 0;
      this.isGrounded = true;
    } else {
      this.isGrounded = false;
    }

    // 5. Actualizar modelo y cámara
    this.model.mesh.position.copy(this.position);
    
    // Rotar modelo hacia la dirección de movimiento si nos estamos moviendo (y no atacando)
    if (moveDir.length() > 0 && !this.isAttacking) {
      const lookTarget = this.position.clone().add(moveDir);
      this.model.mesh.lookAt(lookTarget);
    }

    // --- COMBAT LOGIC ---
    if (this.inputManager.consumeLeftClick() && !this.isAttacking && this.isGrounded) {
      this.isAttacking = true;
      this.attackTimer = 0;
      this.hasHitDealt = false;
      
      // Play sound
      if (Game.instance.audioEngine) {
        Game.instance.audioEngine.playSound('sword_swing', this.position);
      }
    }

    if (this.isAttacking) {
      this.model.playState('attack');
      
      this.attackTimer += deltaTime;
      const progress = this.attackTimer / this.attackDuration;

      // Deal damage in the middle of the swing
      if (progress >= 0.3 && !this.hasHitDealt) {
        this.hasHitDealt = true;
        if (Game.instance.enemyManager) {
          const playerDir = new THREE.Vector3(0, 0, 1).applyQuaternion(this.model.mesh.quaternion);
          Game.instance.enemyManager.checkMeleeHit(this.position, playerDir, 2.5, Math.PI / 2);
        }
      }

      // Disable movement while attacking
      this.currentVelX = lerp(this.currentVelX, 0, 20 * deltaTime);
      this.currentVelZ = lerp(this.currentVelZ, 0, 20 * deltaTime);

      if (this.attackTimer >= this.attackDuration) {
        this.isAttacking = false;
      }
    }

    // --- PROCEDURAL ANIMATION (Walk cycle) ---
    const currentSpeed = Math.sqrt(this.currentVelX * this.currentVelX + this.currentVelZ * this.currentVelZ);
    
    if (currentSpeed > 0.1 && this.isGrounded && !this.isAttacking) {
      this.model.playState('walk');
      
      // Walk cycle for sounds/dust
      const walkSpeed = currentSpeed * 1.5;
      const prevSin = Math.sin(this.animationTime);
      this.animationTime += deltaTime * walkSpeed;
      const currSin = Math.sin(this.animationTime);
      
      // Play footstep on zero cross
      if (prevSin * currSin < 0 || (prevSin === 0 && currSin !== 0)) {
        Game.instance.audioEngine?.playSound('footstep', this.position);
        Game.instance.dustSystem?.spawn(this.position.x, this.position.y - 0.2, this.position.z);
      }
    } else if (!this.isAttacking) {
      this.model.playState('idle');
      this.animationTime = 0; // optional reset
    }

    this.model.update(deltaTime);

    this.cameraController.update(this.position, this.terrainGenerator);
  }
}

