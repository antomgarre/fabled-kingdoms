import * as THREE from 'three';
import * as SkeletonUtils from 'three/examples/jsm/utils/SkeletonUtils.js';
import { Game } from '../engine/Game';

export type NPCRace = 'human' | 'halfling' | 'dwarf' | 'elf';

export class NPCModel {
  public mesh: THREE.Group;
  public baseBodyY: number = 0; // Legacy property for NPCManager breathing
  
  private mixer: THREE.AnimationMixer | null = null;
  private actions: Record<string, THREE.AnimationAction> = {};
  private currentAction: THREE.AnimationAction | null = null;
  
  // Pivot legacy para que no rompa código en NPCManager
  public bodyPivot: THREE.Group;

  constructor(race: NPCRace, role: string) {
    this.mesh = new THREE.Group();
    this.bodyPivot = new THREE.Group();
    this.mesh.add(this.bodyPivot);

    const modelGroup = Game.instance.assetManager.models['villager'];
    if (modelGroup) {
      const clonedModel = SkeletonUtils.clone(modelGroup) as THREE.Group;
      clonedModel.rotation.y = 0; // The Quaternius models face the correct way
      
      // Modificar escala según la raza
      let scale = 1.0;
      switch (race) {
        case 'dwarf': scale = 0.9; break;
        case 'halfling': scale = 0.85; break;
        case 'elf': scale = 1.05; break;
        case 'human': default: break;
      }
      clonedModel.scale.set(scale, scale, scale);

      this.mesh.add(clonedModel);

      this.mixer = new THREE.AnimationMixer(clonedModel);
      if (modelGroup.animations) {
        modelGroup.animations.forEach((clip) => {
          const action = this.mixer!.clipAction(clip);
          this.actions[clip.name.toLowerCase()] = action;
        });
      }
      
      this.playState('idle');
    } else {
      console.warn('[NPCModel] Model not found in AssetManager');
    }
  }

  public playState(state: string) {
    const key = state.toLowerCase();
    
    let targetName: string | undefined;
    if (key.includes('idle')) targetName = 'idle';
    else if (key.includes('walk') || key.includes('run')) {
      targetName = this.actions['walk'] ? 'walk' : 'run';
    } else {
      targetName = key;
    }

    let matchedAction: THREE.AnimationAction | undefined;
    for (const name in this.actions) {
      if (name.includes(targetName)) {
        matchedAction = this.actions[name];
        break;
      }
    }

    if (!matchedAction) {
      if (key.includes('idle')) matchedAction = this.actions['idle'] || this.actions['idle_a'];
      if (key.includes('walk') || key.includes('run')) matchedAction = this.actions['walk'] || this.actions['run'];
    }

    if (matchedAction && this.currentAction !== matchedAction) {
      if (this.currentAction) {
        this.currentAction.fadeOut(0.2);
      }
      matchedAction.reset().fadeIn(0.2).play();
      this.currentAction = matchedAction;
    }
  }

  public update(dt: number) {
    if (this.mixer) {
      this.mixer.update(dt);
    }
  }
}
