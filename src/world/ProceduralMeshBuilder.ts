import * as THREE from 'three';

export interface IAIFloraDefinition {
  species_id: string;
  name: string;
  description: string;
  trunk: {
    base_radius: number;
    top_radius: number;
    height: number;
    color: string;
  };
  leaves: {
    shape: 'cone' | 'sphere' | 'box';
    radius: number;
    height: number;
    color: string;
    y_offset: number; // Offset from trunk base
  };
  density_multiplier: number; // How common it is (0.1 to 2.0)
}

export class ProceduralMeshBuilder {
  /**
   * Construye las geometrías base a partir de la definición de la IA.
   * Devuelve las geometrías y materiales listos para instanciar.
   */
  static buildFloraMeshes(def: IAIFloraDefinition): {
    trunkGeo: THREE.BufferGeometry;
    trunkMat: THREE.Material;
    leafGeo: THREE.BufferGeometry;
    leafMat: THREE.Material;
  } {
    // 1. Tronco
    const trunkGeo = new THREE.CylinderGeometry(
      def.trunk.top_radius,
      def.trunk.base_radius,
      def.trunk.height,
      6
    );
    trunkGeo.translate(0, def.trunk.height / 2, 0);

    const trunkMat = new THREE.MeshStandardMaterial({
      color: parseInt(def.trunk.color.replace('#', '0x')),
      roughness: 1.0,
      flatShading: true
    });

    // 2. Hojas
    let leafGeo: THREE.BufferGeometry;
    if (def.leaves.shape === 'sphere') {
      leafGeo = new THREE.SphereGeometry(def.leaves.radius, 7, 7);
    } else if (def.leaves.shape === 'box') {
      leafGeo = new THREE.BoxGeometry(def.leaves.radius * 2, def.leaves.height, def.leaves.radius * 2);
    } else {
      leafGeo = new THREE.ConeGeometry(def.leaves.radius, def.leaves.height, 6);
    }
    
    leafGeo.translate(0, def.leaves.y_offset, 0);

    const leafMat = new THREE.MeshStandardMaterial({
      color: parseInt(def.leaves.color.replace('#', '0x')),
      roughness: 0.9,
      flatShading: true
    });

    return { trunkGeo, trunkMat, leafGeo, leafMat };
  }
}
