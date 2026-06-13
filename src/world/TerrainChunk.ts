import * as THREE from 'three';
import {
  CHUNK_SIZE,
  CHUNK_WORLD_SIZE
} from '../utils/constants';

export class TerrainChunk {
  public mesh: THREE.Mesh;
  public chunkX: number;
  public chunkZ: number;

  constructor(chunkX: number, chunkZ: number) {
    this.chunkX = chunkX;
    this.chunkZ = chunkZ;

    const geometry = new THREE.PlaneGeometry(
      CHUNK_WORLD_SIZE,
      CHUNK_WORLD_SIZE,
      CHUNK_SIZE - 1,
      CHUNK_SIZE - 1
    );

    geometry.rotateX(-Math.PI / 2);

    const positions = geometry.attributes.position;
    const colors = new Float32Array(positions.count * 3);
    geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

    const material = new THREE.MeshStandardMaterial({
      vertexColors: true,
      flatShading: true,
      roughness: 0.8,
      metalness: 0.1
    });

    this.mesh = new THREE.Mesh(geometry, material);
    this.mesh.position.set(chunkX * CHUNK_WORLD_SIZE, 0, chunkZ * CHUNK_WORLD_SIZE);
    this.mesh.visible = false; // Hide until data is applied
  }

  public prepareForRebuild(chunkX: number, chunkZ: number): void {
    this.chunkX = chunkX;
    this.chunkZ = chunkZ;
    this.mesh.visible = false;
    this.mesh.position.set(chunkX * CHUNK_WORLD_SIZE, 0, chunkZ * CHUNK_WORLD_SIZE);
  }

  public applyData(heights: Float32Array, colors: Float32Array, normals: Float32Array): void {
    const geometry = this.mesh.geometry;
    const positions = geometry.attributes.position;
    const colorsAttr = geometry.attributes.color as THREE.BufferAttribute;

    if (!geometry.attributes.normal) {
      geometry.setAttribute('normal', new THREE.BufferAttribute(normals, 3));
    } else {
      (geometry.attributes.normal as THREE.BufferAttribute).set(normals);
    }

    // Apply heights
    for (let i = 0; i < heights.length; i++) {
      positions.setY(i, heights[i]);
    }

    // Apply colors directly from buffer
    colorsAttr.set(colors);

    positions.needsUpdate = true;
    colorsAttr.needsUpdate = true;
    geometry.attributes.normal.needsUpdate = true;

    // Recalcular bounding sphere/box para que la cámara no haga culling incorrecto al rotar
    geometry.computeBoundingBox();
    geometry.computeBoundingSphere();

    this.mesh.visible = true;
  }
}
