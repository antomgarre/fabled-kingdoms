# Visuals Milestone Implementation Strategy

## Observation

1. **AssetManager** (`src/engine/AssetManager.ts`): Currently returns `Promise<GLTF>` and calls `reject(error)` on failure. `PROJECT.md` interface contracts demand it returns `Promise<THREE.Group>` with animations accessible.
2. **Initialization** (`src/engine/Game.ts`): Models are loaded via `Promise.all` in `init()` *before* `PlayerController` and `EnemyManager` are instantiated, meaning the models will be ready synchronously in `Game.instance.assetManager.models` at construction time.
3. **Procedural Animations** (`src/player/PlayerController.ts` lines 225-307, `src/ai/EnemyManager.ts` lines 136-168): Animations are currently simulated by manually mutating rotation values on `.bodyPivot`, `.leftLegPivot`, `.rightArmPivot`, etc.
4. **Procedural Meshes** (`src/player/PlayerModel.ts`, `src/ai/EnemyModel.ts`): Models are manually constructed using Three.js primitive geometries (`CylinderGeometry`, `SphereGeometry`) instead of using loaded assets. Neither uses `THREE.AnimationMixer`.

## Logic Chain

1. **AssetManager Refactor**: To load "without throwing errors" and satisfy the interface, `AssetManager.loadModel` must be changed to return a `Promise<THREE.Group>`. On success, it should attach `gltf.animations` to the group (e.g. `const group = gltf.scene as any; group.animations = gltf.animations;`) and resolve it. On failure, it must resolve with an empty `THREE.Group` rather than rejecting, preventing fatal unhandled rejections.
2. **PlayerModel Integration**: Strip the procedural primitive mesh generation. Extract the 'soldier' model from `Game.instance.assetManager.models['soldier']`. Instantiate a `THREE.AnimationMixer` with this model. Load its `.animations` array into a dictionary of `THREE.AnimationAction` objects. Expose a `playAnimation(state: string)` method that cross-fades between states. Add a `this.mixer.update(dt)` call in its `update` method.
3. **PlayerController Cleanup**: Remove all references to manual pivot rotations (`model.leftLegPivot.rotation.x = ...`). Instead, dispatch state changes: `this.model.playAnimation('Attack')` when attacking, `Walk` (or `Run`) when moving, and `Idle` otherwise.
4. **EnemyModel Integration**: Similar to `PlayerModel`, but because there are multiple instances of enemies (20 goblins), we **must** clone the base model using `import { clone } from 'three/examples/jsm/utils/SkeletonUtils.js'`. A simple `.clone()` will fail to duplicate the skeletal bindings properly. Add a `THREE.AnimationMixer` and a `playAnimation` method.
5. **EnemyManager Cleanup**: Remove procedural pivot rotations during the `'chase'`, `'idle'`, and `'attack'` states. Replace them with `enemy.model.playAnimation('Walking')`, `enemy.model.playAnimation('Punch')`, etc. In the `update` loop, ensure `enemy.model.mixer?.update(dt)` is called for each active enemy.

## Caveats

- **Animation Names**: The strategy assumes specific clip names in the `.glb` files (e.g., 'Idle', 'Walk', 'Walking', 'Punch', 'Death'). A name mapping layer should be included in `playAnimation` (e.g. if 'Attack' is requested but the clip is named 'Punch', it remaps it) to avoid undefined actions.
- **Weapon Attachments**: The current procedural meshes include weapons (swords, clubs). When migrating to GLB skeletal models, if weapons are not part of the `.glb`, they must be attached dynamically to the correct hand bone using `.getObjectByName('RightHand')`. The scope does not explicitly mention this, but it is a likely side-effect of replacing procedural models.

## Conclusion

The implementation requires 5 targeted refactors:
1. `AssetManager.ts`: Catch `gltfLoader` errors to resolve an empty Group, and attach `animations` to `gltf.scene`.
2. `PlayerModel.ts`: Replace primitives with the loaded 'soldier' group, setup `AnimationMixer`, expose `playAnimation()`.
3. `PlayerController.ts`: Replace procedural pivot math with `playAnimation()` calls.
4. `EnemyModel.ts`: Use `SkeletonUtils.clone` on the 'robot' group, setup `AnimationMixer`, expose `playAnimation()`.
5. `EnemyManager.ts`: Replace procedural math with `playAnimation()` calls, and tick the mixer in the update loop.

## Verification Method

1. Run the project (`npm run dev`).
2. Verify no errors appear in the console if a `.glb` fails to load.
3. Move the player and click to attack. Ensure 'Idle' transitions seamlessly to 'Walk', and 'Walk' to 'Attack'.
4. Approach enemies and verify each individual enemy plays the 'Walking' animation towards the player, transitions to 'Punch' in range, and updates its skeletal mixer independently without crashing.
