# Handoff Report: Visuals Implementation Strategy

## 1. Observation
- `AssetManager.ts` currently uses `GLTFLoader` but throws/rejects on error (`reject(error)`), which could break Promise chains if unhandled (though `Game.ts` wraps `Promise.all` in a try/catch, resolving gracefully is requested by the prompt).
- `PlayerModel.ts` and `EnemyModel.ts` currently construct characters purely procedurally using primitive `THREE.Mesh` parts (Box, Cylinder, Sphere) organized in pivots (`bodyPivot`, `leftArmPivot`, etc.).
- `PlayerController.ts` and `EnemyManager.ts` manipulate these pivots directly each frame (e.g., `model.leftLegPivot.rotation.x = angle`) to simulate walking, breathing, and attacking.
- `Game.ts` successfully pre-loads `soldier` (`/models/Soldier.glb`) and `robot` (`/models/RobotExpressive.glb`) and registers them in `Game.instance.assetManager.models`.
- Three.js skeletal animations require passing the loaded `GLTF` scene to `THREE.AnimationMixer`, storing `AnimationClip` actions, and calling `.update(dt)` every frame.

## 2. Logic Chain
1. **AssetManager Error Handling:** To satisfy the requirement "without throwing errors," we must replace `reject(error)` with a fallback resolution (e.g., `resolve(null as any)`) in the `GLTFLoader.load` error callback.
2. **Model Replacement:** `PlayerModel.ts` and `EnemyModel.ts` need to be rewritten to fetch their respective loaded models (`Game.instance.assetManager.models['soldier']` and `['robot']`), clone the `scene`, and add it to `this.mesh`.
3. **AnimationMixer Integration:** Both model classes must instantiate `THREE.AnimationMixer(model)`, map `gltf.animations` to `THREE.AnimationAction` instances via `mixer.clipAction(clip)`, and provide a `playAnimation(stateName)` method that handles `.crossFadeFrom` for smooth transitions.
4. **State Machine & Update Loops:** `PlayerController.ts` and `EnemyManager.ts` must call the new `playAnimation` function based on their logical states (Idle, Walk/Run, Attack, Death). They also need to call `this.model.update(dt)` to advance the AnimationMixer.
5. **Procedural Cleanup:** All manual pivot rotations (`rotation.x = angle`, `torsoTwist`, etc.) must be deleted to allow the skeletal animations to control the visual state without interference.

## 3. Caveats
- The exact names of the animations inside `Soldier.glb` and `RobotExpressive.glb` are not entirely guaranteed without parsing them. The `playAnimation` logic should use fuzzy matching (e.g., fallback `Attack` to `Punch`, `Walk` to `Run`) to ensure the transition requirements are met safely.
- The procedural weapons (Sword/Shield for player, Club for goblin) may not attach automatically to the bones of the `.glb` models unless manually parented to the specific `Bone` nodes. The strategy replaces the whole procedural mesh, dropping the weapons. If weapons are required, they'll need to be attached to `mixamorigRightHand` or equivalent bones post-load.

## 4. Conclusion
The implementation strategy requires:
1. **`src/engine/AssetManager.ts`**: Change `reject(error)` to `resolve(null as any)` to prevent unhandled promise rejections.
2. **`src/player/PlayerModel.ts` & `src/ai/EnemyModel.ts`**: Remove the procedural meshes. Fetch the GLTF model from `AssetManager`, create an `AnimationMixer`, map animation actions (supporting Idle, Walk, Attack, Death via fuzzy matching), and expose a `playAnimation(name)` and `update(dt)` method.
3. **`src/player/PlayerController.ts`**: Remove `// --- PROCEDURAL ANIMATION ---` and manual pivot combat rotations. Insert `this.model.playAnimation('attack')` in the combat block, and toggle between `run` and `idle` based on `currentSpeed`. Maintain `this.animationTime` just to trigger footstep sounds.
4. **`src/ai/EnemyManager.ts`**: Remove manual `leftLegPivot.rotation.x` logic. Call `enemy.model.playAnimation` corresponding to the state (`'idle'`, `'walk'`, `'attack'`, `'death'`) inside the state logic blocks. Add `enemy.model.update(dt)` at the end of the enemy update loop.

## 5. Verification Method
- Ensure the TypeScript compiler does not complain (`npx tsc --noEmit`).
- Start the application and verify that characters render using the actual `.glb` assets instead of primitive blocks.
- Move the player and attack; observe smooth blending between 'Idle', 'Run', and 'Attack' animations.
- Let an enemy detect the player and observe its transition from 'Idle' to 'Walk/Run', then to 'Attack' when close. Defeat the enemy and verify the 'Death' animation plays.
