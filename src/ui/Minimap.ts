import * as THREE from 'three';
import { TerrainShaper } from '../world/TerrainShaper';
import { WATER_LEVEL } from '../utils/constants';
import { Game } from '../engine/Game';

export class Minimap {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;
  private size: number = 200;
  private mapRadius: number = 100;

  constructor(parent: HTMLElement) {
    this.canvas = document.createElement('canvas');
    this.canvas.width = this.size;
    this.canvas.height = this.size;
    this.canvas.style.width = `${this.size}px`;
    this.canvas.style.height = `${this.size}px`;
    this.canvas.style.position = 'absolute';
    this.canvas.style.bottom = '20px';
    this.canvas.style.right = '20px';
    this.canvas.style.border = '2px solid gold';
    this.canvas.style.borderRadius = '50%';
    this.canvas.style.background = 'black';
    this.canvas.style.pointerEvents = 'none';
    // Fix z-index just in case
    this.canvas.style.zIndex = '100';

    parent.appendChild(this.canvas);
    
    const ctx = this.canvas.getContext('2d');
    if (!ctx) throw new Error('Could not get 2D context for minimap');
    this.ctx = ctx;
  }

  public update(playerPos: THREE.Vector3, terrainShaper: TerrainShaper): void {
    const imgData = this.ctx.createImageData(this.size, this.size);
    const px = Math.floor(playerPos.x);
    const pz = Math.floor(playerPos.z);

    const halfSize = Math.floor(this.size / 2);

    for (let x = 0; x < this.size; x++) {
      for (let z = 0; z < this.size; z++) {
        // Distancia al centro para clip circular (opcional, aunque con borderRadius=50% ya se ve circular,
        // pero dibujar circularmente ahorra un poquito o hace el fondo negro)
        const dx = x - halfSize;
        const dz = z - halfSize;
        if (dx * dx + dz * dz > halfSize * halfSize) {
          continue; // Leave transparent/black
        }

        const worldX = px + dx * 2; // Step size 2 for broader view
        const worldZ = pz + dz * 2;
        const height = terrainShaper.getHeight(worldX, worldZ);

        let r = 0, g = 0, b = 0, a = 255;
        if (height < WATER_LEVEL + 0.5) {
          // Water
          r = 40; g = 100; b = 200;
        } else if (height < WATER_LEVEL + 3) {
          // Sand
          r = 210; g = 190; b = 130;
        } else {
          // Grass / Land
          // Add some simple shading based on height
          const val = Math.min(255, 100 + height * 2);
          r = val * 0.4; g = val * 0.8; b = val * 0.3;
        }

        const i = (z * this.size + x) * 4;
        imgData.data[i] = r;
        imgData.data[i + 1] = g;
        imgData.data[i + 2] = b;
        imgData.data[i + 3] = a;
      }
    }

    this.ctx.putImageData(imgData, 0, 0);

    // Draw player directional triangle
    const yaw = Game.instance.playerController.cameraController.getAzimuth;
    this.ctx.save();
    this.ctx.translate(halfSize, halfSize);
    this.ctx.rotate(-yaw);
    
    this.ctx.fillStyle = 'red';
    this.ctx.beginPath();
    this.ctx.moveTo(0, -6);
    this.ctx.lineTo(-4, 4);
    this.ctx.lineTo(4, 4);
    this.ctx.closePath();
    this.ctx.fill();
    
    this.ctx.restore();
  }
}
