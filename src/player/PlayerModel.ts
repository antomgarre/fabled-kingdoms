import * as THREE from 'three';
import * as SkeletonUtils from 'three/examples/jsm/utils/SkeletonUtils.js';
import { Game } from '../engine/Game';

export class PlayerModel {
  public mesh: THREE.Group;
  
  private mixer: THREE.AnimationMixer | null = null;
  private actions: Record<string, THREE.AnimationAction> = {};
  private currentAction: THREE.AnimationAction | null = null;
  
  constructor() {
    this.mesh = new THREE.Group();

    const modelGroup = Game.instance.assetManager.models['player'];
    if (modelGroup) {
      const clonedModel = SkeletonUtils.clone(modelGroup) as THREE.Group;
      clonedModel.rotation.y = 0; // The Quaternius models face the correct way
      this.mesh.add(clonedModel);

      this.mixer = new THREE.AnimationMixer(clonedModel);
      if (modelGroup.animations) {
        modelGroup.animations.forEach((clip) => {
          const action = this.mixer!.clipAction(clip);
          const name = clip.name.toLowerCase();
          if (name.includes('death')) {
            action.setLoop(THREE.LoopOnce, 1);
            action.clampWhenFinished = true;
          }
          this.actions[name] = action;
        });
      }
    } else {
      console.warn('[PlayerModel] Player model not found in AssetManager');
    }
  }

  public playState(state: string) {
    const key = state.toLowerCase();
    
    let targetName: string | undefined;
    
    if (key.includes('idle')) targetName = 'idle';
    else if (key.includes('walk') || key.includes('run')) {
      targetName = this.actions['walk'] ? 'walk' : 'run';
    } else if (key.includes('attack')) {
      targetName = this.actions['sword_slash'] ? 'sword_slash' : (this.actions['punch'] ? 'punch' : 'attack');
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

    // fallback
    if (!matchedAction) {
      if (key.includes('idle')) matchedAction = this.actions['idle'] || this.actions['idle_a'];
      if (key.includes('walk')) matchedAction = this.actions['walk'] || this.actions['run'] || this.actions['walking'];
      if (key.includes('attack')) matchedAction = this.actions['sword_slash'] || this.actions['punch'] || this.actions['attack'];
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
