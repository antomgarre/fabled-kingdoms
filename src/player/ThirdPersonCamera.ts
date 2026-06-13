import * as THREE from 'three';
import { InputManager } from '../engine/InputManager';
import {
  CAMERA_MIN_DISTANCE,
  CAMERA_MAX_DISTANCE,
  CAMERA_DEFAULT_DISTANCE,
  CAMERA_HEIGHT_OFFSET,
  CAMERA_SENSITIVITY,
  CAMERA_MIN_POLAR,
  CAMERA_MAX_POLAR
} from '../utils/constants';
import { clamp, lerp } from '../utils/mathUtils';

import { TerrainGenerator } from '../world/TerrainGenerator';

export class ThirdPersonCamera {
  private distance: number = CAMERA_DEFAULT_DISTANCE;
  private azimuth: number = 0;
  private polar: number = Math.PI / 4; // ~45 grados
  private idealPosition: THREE.Vector3 = new THREE.Vector3();
  private lookAtPos: THREE.Vector3 = new THREE.Vector3();
  private isFirstFrame: boolean = true;

  public get getAzimuth(): number {
    return this.azimuth;
  }

  constructor(private camera: THREE.PerspectiveCamera, private inputManager: InputManager) {}

  public update(targetPosition: THREE.Vector3, terrainGenerator: TerrainGenerator): void {
    // 1. Mouse Input para rotación
    const mouseDelta = this.inputManager.getMouseDelta();
    this.azimuth -= mouseDelta.x * CAMERA_SENSITIVITY;
    this.polar -= mouseDelta.y * CAMERA_SENSITIVITY;
    this.polar = clamp(this.polar, CAMERA_MIN_POLAR, CAMERA_MAX_POLAR);

    // 2. Scroll Input para zoom
    const scrollDelta = this.inputManager.consumeScrollDelta();
    if (scrollDelta !== 0) {
      this.distance += Math.sign(scrollDelta) * 1.5;
      this.distance = clamp(this.distance, CAMERA_MIN_DISTANCE, CAMERA_MAX_DISTANCE);
    }

    // Lógica de apuntado (Aiming)
    const isAiming = this.inputManager.isRightMouseDown();
    const targetFov = isAiming ? 45 : 75;
    const currentDistance = isAiming ? 3 : this.distance;
    
    // Zoom suave
    const currentFov = this.camera.fov;
    if (this.isFirstFrame) {
      this.camera.fov = targetFov;
      this.camera.updateProjectionMatrix();
    } else {
      this.camera.fov = lerp(currentFov, targetFov, 10 * 0.016); // asumiendo 60fps dt
      if (Math.abs(this.camera.fov - currentFov) > 0.1) {
        this.camera.updateProjectionMatrix();
      }
    }

    // 3. Calcular posición offset
    const offsetX = currentDistance * Math.sin(this.polar) * Math.sin(this.azimuth);
    const offsetY = currentDistance * Math.cos(this.polar);
    const offsetZ = currentDistance * Math.sin(this.polar) * Math.cos(this.azimuth);

    // 4. Target a mirar (jugador + offset altura)
    this.lookAtPos.copy(targetPosition);
    this.lookAtPos.y += CAMERA_HEIGHT_OFFSET;

    // 5. Posición ideal de la cámara
    this.idealPosition.copy(this.lookAtPos);
    this.idealPosition.x += offsetX;
    this.idealPosition.y += offsetY;
    this.idealPosition.z += offsetZ;

    // Si apuntamos, desplazamos la cámara a la derecha (Over-the-shoulder)
    if (isAiming) {
      // Vector derecha desde la vista de la cámara
      const camRightX = Math.cos(this.azimuth);
      const camRightZ = -Math.sin(this.azimuth);
      this.idealPosition.x -= camRightX * 0.8;
      this.idealPosition.z -= camRightZ * 0.8;
    }

    // 6. Colisión de cámara con el suelo
    const terrainHeight = terrainGenerator.getHeightAt(this.idealPosition.x, this.idealPosition.z);
    const minCameraHeight = terrainHeight + 0.5; // Medio metro sobre el suelo
    if (this.idealPosition.y < minCameraHeight) {
      this.idealPosition.y = minCameraHeight;
      // Recalcular polar (opcional, pero esto evita que tiemble)
    }

    // 7. Suavizado (o instantáneo en el primer frame)
    if (this.isFirstFrame) {
      this.camera.position.copy(this.idealPosition);
      this.isFirstFrame = false;
    } else {
      this.camera.position.lerp(this.idealPosition, 0.15);
    }
    this.camera.lookAt(this.lookAtPos);
  }
}
