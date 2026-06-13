import * as THREE from 'three';
import { WATER_LEVEL, COLORS } from '../utils/constants';

export class WaterPlane {
  public mesh: THREE.Mesh;

  constructor() {
    const geometry = new THREE.PlaneGeometry(2000, 2000);
    geometry.rotateX(-Math.PI / 2);

    const material = new THREE.MeshStandardMaterial({
      color: COLORS.WATER,
      transparent: true,
      opacity: 0.7,
      roughness: 0.1,
      metalness: 0.1
    });

    this.mesh = new THREE.Mesh(geometry, material);
    this.mesh.position.y = WATER_LEVEL;
    
    // El agua no arroja sombras, pero puede recibirlas opcionalmente
    this.mesh.receiveShadow = true;
  }

  /** Reposition the water plane to follow the player */
  public update(playerX: number, playerZ: number): void {
    this.mesh.position.x = playerX;
    this.mesh.position.z = playerZ;
  }
}
