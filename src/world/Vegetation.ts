import * as THREE from 'three';
import {
  TREES_PER_CHUNK,
  TREE_MIN_TERRAIN_HEIGHT,
  TREE_MAX_TERRAIN_HEIGHT,
  CHUNK_WORLD_SIZE
} from '../utils/constants';
import { Game } from '../engine/Game';
import type { TerrainShaper } from './TerrainShaper';
import { getTerrainHeight } from '../utils/noise';
import { IAIFloraDefinition, ProceduralMeshBuilder } from './ProceduralMeshBuilder';
import { AIObjectGenerator } from '../ai/AIObjectGenerator';

const MAX_INSTANCES_PER_SPECIES = 3000;

interface SpeciesCache {
  def: IAIFloraDefinition;
  trunkGeo: THREE.BufferGeometry;
  trunkMat: THREE.Material;
  leafGeo: THREE.BufferGeometry;
  leafMat: THREE.Material;
}

interface SpeciesPool {
  trunkMesh: THREE.InstancedMesh;
  leafMesh: THREE.InstancedMesh;
}

interface TreeData {
  pos: THREE.Vector3;
  scale: number;
  rotY: number;
  greenShade: THREE.Color;
}

interface ChunkVegetation {
  treesBySpecies: Map<number, TreeData[]>;
}

function chunkKey(cx: number, cz: number): string {
  return `${cx},${cz}`;
}

export class Vegetation {
  private floraSpecies: SpeciesCache[] = [];
  public treePositions: {x:number, z:number}[] = [];
  private chunks: Map<string, ChunkVegetation> = new Map();
  private generatingChunks: Set<string> = new Set();
  
  private speciesPools: SpeciesPool[] = [];
  
  private scene: THREE.Scene;
  private terrainShaper: TerrainShaper | undefined;

  constructor(scene: THREE.Scene, terrainShaper?: TerrainShaper) {
    this.scene = scene;
    this.terrainShaper = terrainShaper;
    this.initAIFlora();
  }

  private async initAIFlora() {
    const definitions = await AIObjectGenerator.generateFloraForRegion("Valle templado con ríos");
    for (const def of definitions) {
      const meshes = ProceduralMeshBuilder.buildFloraMeshes(def);
      this.floraSpecies.push({ def, ...meshes });
      
      // Creamos un POOL global para cada especie (1 solo draw call, 1 solo buffer en GPU)
      const trunkMesh = new THREE.InstancedMesh(meshes.trunkGeo, meshes.trunkMat, MAX_INSTANCES_PER_SPECIES);
      const leafMesh = new THREE.InstancedMesh(meshes.leafGeo, meshes.leafMat, MAX_INSTANCES_PER_SPECIES);
      
      trunkMesh.castShadow = true;
      trunkMesh.receiveShadow = true;
      leafMesh.castShadow = true;
      leafMesh.receiveShadow = false; // Optimización de sombras
      
      // Desactivamos el culling porque los InstancedMesh globales no tienen BoundingSphere dinámica
      trunkMesh.frustumCulled = false;
      leafMesh.frustumCulled = false;

      leafMesh.instanceColor = new THREE.InstancedBufferAttribute(
        new Float32Array(MAX_INSTANCES_PER_SPECIES * 3), 3
      );
      
      // Inicializar todas las matrices ocultas bajo tierra por si acaso el motor renderiza algo antes de count=0
      const hiddenMatrix = new THREE.Matrix4().makeTranslation(0, -1000, 0);
      for (let i = 0; i < MAX_INSTANCES_PER_SPECIES; i++) {
        trunkMesh.setMatrixAt(i, hiddenMatrix);
        leafMesh.setMatrixAt(i, hiddenMatrix);
        leafMesh.setColorAt(i, new THREE.Color(0,0,0));
      }
      
      trunkMesh.count = 0;
      leafMesh.count = 0;

      this.scene.add(trunkMesh);
      this.scene.add(leafMesh);
      
      this.speciesPools.push({ trunkMesh, leafMesh });
    }
  }

  private seededRandom(seed: number): () => number {
    let s = seed;
    return () => {
      s = (s * 16807 + 0) % 2147483647;
      return s / 2147483647;
    };
  }

  private getHeight(x: number, z: number): number {
    if (this.terrainShaper) return this.terrainShaper.getHeight(x, z);
    return getTerrainHeight(x, z);
  }

  private getTerrainSlope(worldX: number, worldZ: number): number {
    const d = 1.0;
    const hL = this.getHeight(worldX - d, worldZ);
    const hR = this.getHeight(worldX + d, worldZ);
    const hD = this.getHeight(worldX, worldZ - d);
    const hU = this.getHeight(worldX, worldZ + d);

    const dx = (hR - hL) / (2 * d);
    const dz = (hU - hD) / (2 * d);

    return Math.sqrt(dx * dx + dz * dz);
  }

  public async generateForChunk(cx: number, cz: number): Promise<void> {
    if (this.floraSpecies.length === 0) return;

    const key = chunkKey(cx, cz);
    if (this.chunks.has(key) || this.generatingChunks.has(key)) return;
    
    this.generatingChunks.add(key);

    const seed = (cx * 73856093) ^ (cz * 19349663);
    const random = this.seededRandom(seed);

    const treesBySpecies: Map<number, TreeData[]> = new Map();
    for (let i = 0; i < this.floraSpecies.length; i++) {
      treesBySpecies.set(i, []);
    }

    const totalAttempts = TREES_PER_CHUNK * 3;
    const batchSize = 20;

    for (let i = 0; i < totalAttempts; i++) {
      if (i > 0 && i % batchSize === 0) {
        await new Promise(resolve => setTimeout(resolve, 0));
      }

      const offsetX = random() * CHUNK_WORLD_SIZE;
      const offsetZ = random() * CHUNK_WORLD_SIZE;
      
      const worldX = cx * CHUNK_WORLD_SIZE + offsetX - CHUNK_WORLD_SIZE / 2;
      const worldZ = cz * CHUNK_WORLD_SIZE + offsetZ - CHUNK_WORLD_SIZE / 2;

      const height = this.getHeight(worldX, worldZ);
      if (height < TREE_MIN_TERRAIN_HEIGHT || height > TREE_MAX_TERRAIN_HEIGHT) continue;

      const slope = this.getTerrainSlope(worldX, worldZ);
      if (slope > 0.4) continue;

      let inExclusionZone = false;
      if (Game.instance && Game.instance.locationPlacer) {
        for (const zone of Game.instance.locationPlacer.exclusionZones) {
          const dx = worldX - zone.x;
          const dz = worldZ - zone.z;
          if (dx * dx + dz * dz < zone.radius * zone.radius) {
            inExclusionZone = true;
            break;
          }
        }
      }
      if (inExclusionZone) continue;

      let selectedSpeciesIndex = 0;
      let r = random() * 3.0;
      let currentSum = 0;
      for (let s = 0; s < this.floraSpecies.length; s++) {
        currentSum += this.floraSpecies[s].def.density_multiplier;
        if (r <= currentSum) {
          selectedSpeciesIndex = s;
          break;
        }
      }

      const scale = 0.8 + random() * 0.4;
      const rotY = random() * Math.PI * 2;
      
      const greenBase = 0.3 + random() * 0.25;
      const greenShade = new THREE.Color(0.1 + random() * 0.08, greenBase, 0.1 + random() * 0.05);

      treesBySpecies.get(selectedSpeciesIndex)?.push({
        pos: new THREE.Vector3(worldX, height, worldZ),
        scale,
        rotY,
        greenShade
      });

      this.treePositions.push({ x: worldX, z: worldZ });
    }

    this.chunks.set(key, { treesBySpecies });
    this.generatingChunks.delete(key);
    
    this.updateGlobalInstancedMeshes();
  }

  public removeForChunk(cx: number, cz: number): void {
    const key = chunkKey(cx, cz);
    if (this.chunks.has(key)) {
      this.chunks.delete(key);
      this.updateGlobalInstancedMeshes();
    }
  }

  public cleanupChunks(activeKeys: Set<string>): void {
    let changed = false;
    for (const key of this.chunks.keys()) {
      if (!activeKeys.has(key)) {
        this.chunks.delete(key);
        changed = true;
      }
    }
    if (changed) {
      this.updateGlobalInstancedMeshes();
    }
  }

  private updateGlobalInstancedMeshes() {
    if (this.speciesPools.length === 0) return;

    const dummy = new THREE.Object3D();

    for (let s = 0; s < this.speciesPools.length; s++) {
      const pool = this.speciesPools[s];
      let i = 0;
      
      for (const chunk of this.chunks.values()) {
        const trees = chunk.treesBySpecies.get(s);
        if (!trees) continue;
        
        for (const data of trees) {
          if (i >= MAX_INSTANCES_PER_SPECIES) break;
          
          dummy.position.copy(data.pos);
          dummy.rotation.set(0, data.rotY, 0);
          dummy.scale.set(data.scale, data.scale, data.scale);
          dummy.updateMatrix();
          
          pool.trunkMesh.setMatrixAt(i, dummy.matrix);
          pool.leafMesh.setMatrixAt(i, dummy.matrix);
          pool.leafMesh.setColorAt(i, data.greenShade);
          i++;
        }
      }
      
      pool.trunkMesh.count = i;
      pool.leafMesh.count = i;
      pool.trunkMesh.instanceMatrix.needsUpdate = true;
      pool.leafMesh.instanceMatrix.needsUpdate = true;
      if (pool.leafMesh.instanceColor) pool.leafMesh.instanceColor.needsUpdate = true;
    }
  }
}
