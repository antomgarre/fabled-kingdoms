# Handoff Report: Visuals Milestone Analysis

## Observation
1. **Current `AssetManager.ts`**: Uses `GLTFLoader` to load models and returns a `Promise<GLTF>`, storing the `GLTF` objects in `this.models`. It does not attach the animations to the returned scene, which violates the contract defined in `PROJECT.md` (`AssetManager.loadModel(url: string): Promise<THREE.Group>`).
2. **Current Player and Enemy Models**: Both `PlayerModel.ts` and `EnemyModel.ts` use procedural geometry (e.g., `BoxGeometry`, `CylinderGeometry`) and expose bone pivots (e.g., `bodyPivot`, `leftLegPivot`, `rightArmPivot`).
3. **Current Controllers**: `PlayerController.ts` and `EnemyManager.ts` manually manipulate these pivot rotations each frame to simulate walking, attacking, and breathing.
4. **Build Status**: `npm run build` passes successfully with no compilation errors.

## Logic Chain
1. To satisfy the Visuals milestone, `AssetManager.ts` must return a `THREE.Group` representing the scene and attach the `gltf.animations` array to `scene.animations` so they are accessible to `THREE.AnimationMixer`. The `this.models` property must be updated to type `Record<string, THREE.Group>`.
2. `PlayerModel.ts` and `EnemyModel.ts` must be stripped of all procedural generation logic. They should instead retrieve their respective `.glb` models from `Game.instance.assetManager.models`, clone them using `SkeletonUtils.clone()`, add them to `this.mesh`, and instantiate a `THREE.AnimationMixer`.
3. The models must maintain a dictionary of `THREE.AnimationAction` objects created from the `AnimationClip`s and implement a `playState(state: string)` method that uses `.crossFadeTo()` to seamlessly switch between 'Idle', 'Walk', 'Attack', and 'Death' animations.
4. `PlayerController.ts` and `EnemyManager.ts` must remove all manual rotation/position logic targeting the procedural bone pivots. Instead, they should evaluate the entity's current state and call `model.playState('Walk')`, etc., followed by `model.update(deltaTime)`.

## Caveats
- Since the exact animation names inside the `/models/Soldier.glb` and `/models/RobotExpressive.glb` files are unknown without inspecting them, the `playState` method should implement soft fallbacks (e.g., mapping 'Attack' to 'Punch' or 'Walking' to 'Walk') to prevent runtime errors.
- Cloning skeletal meshes requires importing `SkeletonUtils` from `three/examples/jsm/utils/SkeletonUtils.js`.
- Footstep sound and dust particle emission in `PlayerController.ts` currently rely on checking `Math.sin(this.animationTime)`. This logic should be preserved (without the bone rotation part) to keep the effects synchronized with the movement speed.

## Conclusion
The implementation strategy is fully verified. The architectural shift from procedural to skeletal animations requires modifying 5 files:
1. `src/engine/AssetManager.ts` (Update loading logic and types)
2. `src/player/PlayerModel.ts` (Implement AnimationMixer and SkeletonUtils)
3. `src/player/PlayerController.ts` (Remove procedural logic, add `playState` calls)
4. `src/ai/EnemyModel.ts` (Implement AnimationMixer and SkeletonUtils)
5. `src/ai/EnemyManager.ts` (Remove procedural logic, add `playState` calls)

No additional dependencies are needed. The build currently works, but applying these changes must be done carefully to remove all pivot references from the controllers simultaneously to avoid TypeScript errors.

## Verification Method
- **TypeScript**: Run `npm run build` after applying the changes to ensure no references to the old `bodyPivot` properties remain.
- **Runtime**: Launch the development server and verify that models render, animate, and smoothly transition between states without console errors.
