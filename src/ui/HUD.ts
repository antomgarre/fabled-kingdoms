import * as THREE from 'three';
import { FPSCounter } from './FPSCounter';
import { Minimap } from './Minimap';
import { TerrainShaper } from '../world/TerrainShaper';

export class HUD {
  private container: HTMLDivElement;
  private fpsCounter: FPSCounter;
  private minimap: Minimap;

  constructor() {
    this.container = document.createElement('div');
    this.container.id = 'hud';
    document.body.appendChild(this.container);

    this.fpsCounter = new FPSCounter(this.container);
    this.minimap = new Minimap(this.container);
    
    // Crosshair (Punto de mira)
    const crosshair = document.createElement('div');
    crosshair.style.position = 'fixed';
    crosshair.style.top = '50%';
    crosshair.style.left = '50%';
    crosshair.style.width = '4px';
    crosshair.style.height = '4px';
    crosshair.style.background = 'white';
    crosshair.style.borderRadius = '50%';
    crosshair.style.transform = 'translate(-50%, -50%)';
    crosshair.style.pointerEvents = 'none';
    this.container.appendChild(crosshair);
  }

  public update(deltaTime: number, elapsedTime: number, playerPos: THREE.Vector3, terrainShaper: TerrainShaper): void {
    this.fpsCounter.update(deltaTime, elapsedTime);
    this.minimap.update(playerPos, terrainShaper);
  }
}
