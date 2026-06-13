import * as THREE from 'three';
import { TerrainChunk } from './TerrainChunk';
import { CHUNK_WORLD_SIZE, RENDER_DISTANCE, CHUNK_SIZE } from '../utils/constants';
import { worldToChunk, chunkKey } from '../utils/mathUtils';
import { getTerrainHeight } from '../utils/noise';
import type { TerrainShaper } from './TerrainShaper';

export class TerrainGenerator {
  private chunks: Map<string, TerrainChunk> = new Map();
  private chunkPool: TerrainChunk[] = [];
  private scene: THREE.Scene;
  private terrainShaper: TerrainShaper | undefined;
  
  private worker: Worker;
  private pendingChunks: Set<string> = new Set();

  constructor(scene: THREE.Scene, terrainShaper?: TerrainShaper) {
    this.scene = scene;
    this.terrainShaper = terrainShaper;
    
    // Inicializar Web Worker
    this.worker = new Worker(new URL('../workers/terrain.worker.ts', import.meta.url), { type: 'module' });
    
    if (this.terrainShaper) {
      // Extraemos las coordenadas locales exactas de PlaneGeometry para evitar desajustes
      const dummyGeo = new THREE.PlaneGeometry(CHUNK_WORLD_SIZE, CHUNK_WORLD_SIZE, CHUNK_SIZE - 1, CHUNK_SIZE - 1);
      dummyGeo.rotateX(-Math.PI / 2);
      const pos = dummyGeo.attributes.position;
      const localX = new Float32Array(pos.count);
      const localZ = new Float32Array(pos.count);
      for(let i = 0; i < pos.count; i++) {
        localX[i] = pos.getX(i);
        localZ[i] = pos.getZ(i);
      }

      this.worker.postMessage({ 
        type: 'init', 
        payload: { config: this.terrainShaper.config, localX, localZ } 
      });
    }
    
    // Escuchar respuestas del Worker
    this.worker.onmessage = (e) => {
      if (e.data.type === 'result') {
        const { id, chunkX, chunkZ, heights, colors, normals } = e.data.payload;
        this.pendingChunks.delete(id);
        
        const chunk = this.chunks.get(id);
        // Verificar que el chunk no ha sido reciclado mientras el worker calculaba
        if (chunk && chunk.chunkX === chunkX && chunk.chunkZ === chunkZ) {
          chunk.applyData(heights, colors, normals);
        }
      }
    };
  }

  public update(playerX: number, playerZ: number): void {
    const { cx, cz } = worldToChunk(playerX, playerZ, CHUNK_WORLD_SIZE);

    const activeKeys = new Set<string>();

    for (let x = -RENDER_DISTANCE; x <= RENDER_DISTANCE; x++) {
      for (let z = -RENDER_DISTANCE; z <= RENDER_DISTANCE; z++) {
        const targetCx = cx + x;
        const targetCz = cz + z;
        const key = chunkKey(targetCx, targetCz);
        activeKeys.add(key);

        if (!this.chunks.has(key)) {
          let chunk: TerrainChunk;
          if (this.chunkPool.length > 0) {
            chunk = this.chunkPool.pop()!;
            chunk.prepareForRebuild(targetCx, targetCz);
          } else {
            chunk = new TerrainChunk(targetCx, targetCz);
          }
          this.chunks.set(key, chunk);
          this.scene.add(chunk.mesh);
          
          // Solicitar generación al Worker si no está ya en la cola
          if (!this.pendingChunks.has(key)) {
            this.pendingChunks.add(key);
            this.worker.postMessage({
              type: 'generate',
              payload: { chunkX: targetCx, chunkZ: targetCz, id: key }
            });
          }
        }
      }
    }

    // Remover y reciclar chunks fuera de la vista
    for (const [key, chunk] of this.chunks.entries()) {
      if (!activeKeys.has(key)) {
        this.scene.remove(chunk.mesh);
        this.chunkPool.push(chunk);
        this.chunks.delete(key);
        // No borramos del pendingChunks por si el worker responde, lo ignoraremos al comprobar chunkX/Z
      }
    }
  }

  public getHeightAt(worldX: number, worldZ: number): number {
    // Lookup puntual para física de jugador y árboles en el hilo principal (muy rápido)
    if (this.terrainShaper) {
      return this.terrainShaper.getHeight(worldX, worldZ);
    }
    return getTerrainHeight(worldX, worldZ);
  }

  public getVisualHeightAt(worldX: number, worldZ: number): number | null {
    const { cx, cz } = worldToChunk(worldX, worldZ, CHUNK_WORLD_SIZE);
    const key = chunkKey(cx, cz);
    const chunk = this.chunks.get(key);
    
    if (chunk && chunk.mesh.geometry.attributes.position.count > 0) {
      const raycaster = new THREE.Raycaster();
      // Lanzar rayo siempre desde el cielo hacia abajo para no fallar
      raycaster.set(new THREE.Vector3(worldX, 200, worldZ), new THREE.Vector3(0, -1, 0));
      // Raycast against the specific chunk mesh
      const intersects = raycaster.intersectObject(chunk.mesh, false);
      if (intersects.length > 0) {
        return intersects[0].point.y;
      }
    }
    return null;
  }
}
