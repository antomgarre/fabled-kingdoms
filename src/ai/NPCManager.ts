import * as THREE from 'three';
import { NPCModel, NPCRace } from './NPCModel';
import { BlueprintInterpreter } from '../world/BlueprintInterpreter';
import { LocationPlacer } from '../world/LocationPlacer';
import { INPC } from './types';
import { lerp } from '../utils/mathUtils';

interface ActiveNPC {
  data: INPC;
  model: NPCModel;
  worldPosition: THREE.Vector3;
  originalRotationY: number;
}

export class NPCManager {
  private activeNPCs: ActiveNPC[] = [];
  private scene: THREE.Scene;
  private camera: THREE.PerspectiveCamera;
  
  // UI Prompt flotante
  private promptEl: HTMLDivElement;
  public nearestNPC: ActiveNPC | null = null;

  constructor(
    scene: THREE.Scene,
    camera: THREE.PerspectiveCamera,
    interpreter: BlueprintInterpreter,
    locationPlacer: LocationPlacer
  ) {
    this.scene = scene;
    this.camera = camera;
    
    // Crear prompt flotante
    this.promptEl = document.createElement('div');
    this.promptEl.innerText = '[ E ] Hablar';
    this.promptEl.style.position = 'absolute';
    this.promptEl.style.color = '#ffffff';
    this.promptEl.style.backgroundColor = 'rgba(0,0,0,0.7)';
    this.promptEl.style.padding = '4px 8px';
    this.promptEl.style.borderRadius = '4px';
    this.promptEl.style.fontFamily = 'sans-serif';
    this.promptEl.style.fontWeight = 'bold';
    this.promptEl.style.pointerEvents = 'none';
    this.promptEl.style.display = 'none';
    this.promptEl.style.transform = 'translate(-50%, -100%)';
    this.promptEl.style.zIndex = '100';
    document.body.appendChild(this.promptEl);

    this.spawnNPCs(interpreter.getNPCs(), locationPlacer);
  }

  private spawnNPCs(npcs: readonly INPC[], locationPlacer: LocationPlacer) {
    for (const npc of npcs) {
      const pos = locationPlacer.buildingPositions.get(npc.location);
      if (pos) {
        const race = (npc.race as NPCRace) || 'human';
        const model = new NPCModel(race, npc.role);
        
        // Colocar enfrente del edificio, mirando hacia afuera
        model.mesh.position.copy(pos);
        
        // Hacer que miren un poco hacia el centro de la aldea (asumiendo centro 0,0)
        model.mesh.lookAt(new THREE.Vector3(0, pos.y, 0));
        const originalRotationY = model.mesh.rotation.y;

        this.scene.add(model.mesh);

        this.activeNPCs.push({
          data: npc,
          model,
          worldPosition: pos.clone(),
          originalRotationY
        });
        
        console.log(`[NPC] Spawned ${npc.name} at ${npc.location}`);
      } else {
        console.warn(`[NPC] Building ${npc.location} not found for ${npc.name}`);
      }
    }
  }

  public update(dt: number, playerPos: THREE.Vector3, time: number, terrainGenerator?: any) {
    let closestDist = Infinity;
    this.nearestNPC = null;

    for (const npc of this.activeNPCs) {
      // Ajustar altura visual (Raycast) si el terreno existe
      if (terrainGenerator) {
        const visualHeight = terrainGenerator.getVisualHeightAt(npc.worldPosition.x, npc.worldPosition.z);
        if (visualHeight !== null) {
          npc.worldPosition.y = lerp(npc.worldPosition.y, visualHeight, 5 * dt);
        }
      }

      // Distance to player
      const dist = npc.worldPosition.distanceTo(playerPos);
      
      // Update animation mixer
      npc.model.update(dt);
      
      // Look at player if close
      if (dist < 8.0) {
        const targetLook = playerPos.clone();
        targetLook.y = npc.worldPosition.y; // Mantener plano horizontal
        
        // Guardar rotación actual
        const currentRot = npc.model.mesh.rotation.clone();
        
        // Calcular rotación objetivo
        npc.model.mesh.lookAt(targetLook);
        const targetRotY = npc.model.mesh.rotation.y;
        
        // Restaurar y hacer lerp
        npc.model.mesh.rotation.copy(currentRot);
        
        // Ajuste de ángulos para lerp más corto
        let diff = targetRotY - npc.model.mesh.rotation.y;
        while (diff < -Math.PI) diff += Math.PI * 2;
        while (diff > Math.PI) diff -= Math.PI * 2;
        
        npc.model.mesh.rotation.y += diff * 5 * dt;

        if (dist < 4.0 && dist < closestDist) {
          closestDist = dist;
          this.nearestNPC = npc;
        }
      } else {
        // Volver a rotación original
        let diff = npc.originalRotationY - npc.model.mesh.rotation.y;
        while (diff < -Math.PI) diff += Math.PI * 2;
        while (diff > Math.PI) diff -= Math.PI * 2;
        npc.model.mesh.rotation.y += diff * 2 * dt;
      }

      // Sincronizar posición de la malla con la posición física anclada al raycast
      npc.model.mesh.position.copy(npc.worldPosition);
    }

    // Actualizar UI Prompt
    if (this.nearestNPC) {
      const npcPos = this.nearestNPC.worldPosition.clone();
      npcPos.y += 2.2; // Encima de la cabeza
      
      npcPos.project(this.camera);
      
      if (npcPos.z < 1.0) { // Si está frente a la cámara
        const x = (npcPos.x * 0.5 + 0.5) * window.innerWidth;
        const y = (-(npcPos.y * 0.5) + 0.5) * window.innerHeight;
        
        this.promptEl.style.left = `${x}px`;
        this.promptEl.style.top = `${y}px`;
        this.promptEl.style.display = 'block';
      } else {
        this.promptEl.style.display = 'none';
      }
    } else {
      this.promptEl.style.display = 'none';
    }
  }
}
