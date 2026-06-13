import * as THREE from 'three';
import { GLTFLoader, GLTF } from 'three/examples/jsm/loaders/GLTFLoader.js';

export class AssetManager {
  private gltfLoader = new GLTFLoader();
  
  public models: Record<string, THREE.Group> = {};

  public async loadModel(id: string, path: string): Promise<THREE.Group> {
    if (this.models[id]) return this.models[id];

    return new Promise((resolve, reject) => {
      this.gltfLoader.load(
        path,
        (gltf) => {
          this.models[id] = gltf.scene;
          
          // Guardar las animaciones en el objeto si existen
          if (gltf.animations && gltf.animations.length > 0) {
            this.models[id].animations = gltf.animations;
          }
          
          // Habilitar sombras
          gltf.scene.traverse((child) => {
            if ((child as THREE.Mesh).isMesh) {
              child.castShadow = true;
              child.receiveShadow = true;
            }
          });
          
          console.log(`[AssetManager] Loaded model: ${id}`);
          resolve(gltf.scene);
        },
        undefined,
        (error) => {
          console.error(`[AssetManager] Failed to load model: ${path}`, error);
          reject(error);
        }
      );
    });
  }
}
