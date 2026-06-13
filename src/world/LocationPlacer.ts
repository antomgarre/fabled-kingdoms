import * as THREE from 'three';
import { BlueprintInterpreter } from './BlueprintInterpreter';
import { CHUNK_WORLD_SIZE } from '../utils/constants';

const REGION_RADIUS = CHUNK_WORLD_SIZE * 1.5;

interface ExclusionZone {
  x: number;
  z: number;
  radius: number;
}

export class LocationPlacer {
  public buildingBoxes: THREE.Box3[] = [];
  public exclusionZones: ExclusionZone[] = [];
  public buildingPositions: Map<string, THREE.Vector3> = new Map();

  constructor(
    private scene: THREE.Scene,
    private interpreter: BlueprintInterpreter
  ) {
    this.buildLocations();
  }

  private positionToWorld(posStr: string): { x: number; z: number } {
    const map: Record<string, { x: number; z: number }> = {
      center:         { x:  0,    z:  0    },
      north:          { x:  0,    z: -0.6  },
      south:          { x:  0,    z:  0.6  },
      east:           { x:  0.6,  z:  0    },
      west:           { x: -0.6,  z:  0    },
      northeast:      { x:  0.5,  z: -0.5  },
      northwest:      { x: -0.5,  z: -0.5  },
      southeast:      { x:  0.5,  z:  0.5  },
      southwest:      { x: -0.5,  z:  0.5  },
      center_north:   { x:  0,    z: -0.35 },
      center_south:   { x:  0,    z:  0.35 },
      center_east:    { x:  0.35, z:  0    },
      center_west:    { x: -0.35, z:  0    },
      northeast_edge: { x:  0.85, z: -0.85 },
      northwest_edge: { x: -0.85, z: -0.85 },
      southeast_edge: { x:  0.85, z:  0.85 },
      southwest_edge: { x: -0.85, z:  0.85 },
      north_edge:     { x:  0,    z: -0.9  },
      south_edge:     { x:  0,    z:  0.9  },
      east_edge:      { x:  0.9,  z:  0    },
      west_edge:      { x: -0.9,  z:  0    },
    };
    
    const p = map[posStr] || { x: 0, z: 0 };
    return { x: p.x * REGION_RADIUS, z: p.z * REGION_RADIUS };
  }

  private buildLocations(): void {
    const locations = this.interpreter.getLocations();

    for (const loc of locations) {
      if (loc.type === 'village') {
        const center = this.positionToWorld(loc.position || 'center');
        
        // Deforestar zona del pueblo
        this.exclusionZones.push({ x: center.x, z: center.z, radius: 25 });

        const buildings = loc.buildings || [];
        const numBuildings = buildings.length;
        
        // Colocar edificios en círculo alrededor de la plaza central
        const radius = 8;
        
        for (let i = 0; i < numBuildings; i++) {
          const angle = (i / numBuildings) * Math.PI * 2;
          const bx = center.x + Math.cos(angle) * radius;
          const bz = center.z + Math.sin(angle) * radius;
          
          // La puerta mirará hacia el centro
          const rotation = -angle + Math.PI / 2;

          // Variación de color por tipo
          const bType = buildings[i].type;
          const bName = buildings[i].name;
          let roofColor = 0x8b5a2b; // Default paja/madera
          if (bType === 'blacksmith') roofColor = 0x333333; // Oscuro
          if (bType === 'shop') roofColor = 0x4f6a4f; // Verdoso
          if (bType === 'tavern') roofColor = 0x8b3a3a; // Rojizo

          this.createTudorHouse(bx, bz, rotation, roofColor, bName);
        }
      }
    }
  }

  private createTudorHouse(x: number, z: number, rotation: number, roofColorHex: number, name?: string): void {
    const height = this.interpreter.getHeightAt(x, z);

    const houseGroup = new THREE.Group();

    const bodyWidth = 4;
    const bodyDepth = 5;
    const bodyHeight = 3.5;

    // Materiales Premium
    const wallMat = new THREE.MeshStandardMaterial({ color: 0xeeeeee, roughness: 0.9 }); // Yeso
    const woodMat = new THREE.MeshStandardMaterial({ color: 0x3e2723, roughness: 1.0 }); // Madera oscura
    const roofMat = new THREE.MeshStandardMaterial({ color: roofColorHex, roughness: 0.8, flatShading: true });
    const windowMat = new THREE.MeshStandardMaterial({ color: 0xffaa00, emissive: 0xffaa00, emissiveIntensity: 1.5 }); // Luz interior
    
    // 1. Paredes
    const bodyGeo = new THREE.BoxGeometry(bodyWidth, bodyHeight, bodyDepth);
    const bodyMesh = new THREE.Mesh(bodyGeo, wallMat);
    bodyMesh.position.y = bodyHeight / 2;
    bodyMesh.castShadow = true;
    bodyMesh.receiveShadow = true;
    houseGroup.add(bodyMesh);

    // 2. Vigas de Madera (Esquinas)
    const beamThickness = 0.3;
    const cornerBeamGeo = new THREE.BoxGeometry(beamThickness, bodyHeight + 0.1, beamThickness);
    
    const corners = [
      [1, 1], [-1, 1], [1, -1], [-1, -1]
    ];
    corners.forEach(([cx, cz]) => {
      const beam = new THREE.Mesh(cornerBeamGeo, woodMat);
      beam.position.set(cx * (bodyWidth / 2), bodyHeight / 2, cz * (bodyDepth / 2));
      beam.castShadow = true;
      houseGroup.add(beam);
    });

    // 3. Tejado con Alero (sobresale de la casa)
    const roofHeight = 2.5;
    // Utilizamos cilindro de 4 lados para tener un prisma perfecto y rotarlo
    const roofGeo = new THREE.CylinderGeometry(0, Math.hypot(bodyWidth, bodyDepth) / 1.5, roofHeight, 4);
    roofGeo.rotateY(Math.PI / 4); // Alinear con la caja
    const roofMesh = new THREE.Mesh(roofGeo, roofMat);
    roofMesh.position.y = bodyHeight + roofHeight / 2 - 0.2; // Solapar ligeramente
    roofMesh.castShadow = true;
    roofMesh.receiveShadow = true;
    houseGroup.add(roofMesh);

    // 4. Puerta
    const doorGeo = new THREE.BoxGeometry(1.2, 2.0, 0.2);
    const doorMesh = new THREE.Mesh(doorGeo, woodMat);
    // Puerta en Z positivo
    doorMesh.position.set(0, 1.0, bodyDepth / 2 + 0.05);
    houseGroup.add(doorMesh);

    // 5. Ventanas Emisivas (Brillan en la niebla)
    const windowGeo = new THREE.BoxGeometry(0.8, 0.8, 0.2);
    
    // Ventana Izquierda
    const winL = new THREE.Mesh(windowGeo, windowMat);
    winL.position.set(-bodyWidth / 2 - 0.05, 1.5, 0);
    winL.rotation.y = Math.PI / 2;
    houseGroup.add(winL);

    // Ventana Derecha
    const winR = new THREE.Mesh(windowGeo, windowMat);
    winR.position.set(bodyWidth / 2 + 0.05, 1.5, 0);
    winR.rotation.y = Math.PI / 2;
    houseGroup.add(winR);

    // 6. Chimenea
    const chimneyGeo = new THREE.BoxGeometry(0.8, 3.5, 0.8);
    const chimneyMat = new THREE.MeshStandardMaterial({ color: 0x555555, roughness: 0.9 });
    const chimney = new THREE.Mesh(chimneyGeo, chimneyMat);
    // Offset ligeramente para evitar Z-fighting con la pared blanca
    chimney.position.set(-bodyWidth / 2 + 0.45, bodyHeight, -bodyDepth / 2 + 0.45);
    chimney.castShadow = true;
    houseGroup.add(chimney);

    // Ensamblar
    houseGroup.position.set(x, height, z);
    houseGroup.rotation.y = rotation;
    this.scene.add(houseGroup);

    // Colisiones
    const box = new THREE.Box3();
    houseGroup.updateMatrixWorld();
    box.setFromObject(bodyMesh);
    
    this.buildingBoxes.push(box);

    if (name) {
      // Guardar posición para NPCs enfrente de la casa (offset según la rotación)
      // La puerta está en Z positivo local.
      const forward = new THREE.Vector3(0, 0, 1).applyAxisAngle(new THREE.Vector3(0, 1, 0), rotation);
      const spawnPos = new THREE.Vector3(x, height, z).addScaledVector(forward, bodyDepth / 2 + 2.0); // 2 metros enfrente de la puerta
      this.buildingPositions.set(name, spawnPos);
    }
  }
}
