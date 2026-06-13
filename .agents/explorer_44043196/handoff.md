# Handoff: Skeletal Animations Boundary Tests

## 1. Observation
- `PROJECT.md` dictates that `THREE.AnimationMixer` will be integrated into `PlayerController`, `PlayerModel`, etc. for skeletal animations (Idle, Walk, Attack, Death).
- The current implementation in `PlayerController.ts` uses manual procedural animation (e.g. `this.model.bodyPivot.rotation.y = torsoTwist`) and `AssetManager.ts` loads GLTFs that contain a `THREE.AnimationClip[]` in `gltf.animations`.
- The user requested >=5 boundary/corner test cases for these skeletal animations focusing on: missing animations, invalid state transitions, rapid state changes, empty state.

## 2. Logic Chain
Since `AssetManager` retrieves the GLTF object, the `PlayerModel` and `PlayerController` will need to extract `gltf.animations` and pass them to a `THREE.AnimationMixer`.
To test boundaries, we can mock the `AssetManager` returning specific `THREE.AnimationClip` lists (or empty ones) and spy on `THREE.AnimationMixer` behavior when rapid or invalid state calls are made. 

Here is the strategy and design for each of the 5 boundary tests using Vitest (`vi.mock` and `vi.spyOn`):

### Test 1: Empty State (Zero Animations Loaded)
- **Goal:** Ensure the system initializes without crashing when the model contains `0` animations.
- **Strategy:** Mock `AssetManager.loadModel` to return a GLTF object with `animations: []`. Instantiate `PlayerController` and verify that calling `update(deltaTime)` does not throw an error or crash when it inevitably tries to initialize the default state (e.g. 'Idle').
- **Assertions:** `expect(() => controller.update(0.16)).not.toThrow()`.

### Test 2: Missing Specific Animation (Fallback/Graceful Degradation)
- **Goal:** Verify behavior when an expected animation (e.g., 'Attack') is missing from the `glb`.
- **Strategy:** Mock `AssetManager` to return 'Idle' and 'Walk', but omit 'Attack'. Trigger the attack action via `InputManager`.
- **Assertions:** Verify that `AnimationMixer.clipAction` does not cause an unhandled exception for undefined clips, and that the player state remains in the previous valid state (e.g., 'Idle') or falls back cleanly.

### Test 3: Rapid State Changes (Spamming Inputs)
- **Goal:** Ensure rapid back-and-forth transitions do not infinitely stack `AnimationAction` weights, bloat memory, or break crossfade math.
- **Strategy:** Use a `for` loop to toggle `InputManager` 'Walk' (KeyW) and 'Idle' (No keys) 100 times within a simulated 1-second interval (`deltaTime` increments). 
- **Assertions:** Spy on `AnimationAction.play()` and `AnimationAction.crossFadeFrom()`. Verify that weight values on active actions remain bounded `[0, 1]` and the mixer does not hang. 

### Test 4: Invalid State Transitions (Death to Walk)
- **Goal:** Ensure character cannot transition out of a terminal state ('Death') into a movement or attack state.
- **Strategy:** Expose or forcefully set the player's internal state to 'Death' (simulating 0 HP). Then simulate movement input ('KeyW') or attack input ('LeftClick'). 
- **Assertions:** Verify that `AnimationMixer` does not attempt to play or crossfade to 'Walk' or 'Attack', and that the currently playing action remains 'Death'.

### Test 5: Rapid Transition During Non-Interruptible Action (Attack Interruption)
- **Goal:** Test the boundary of interrupting an action that normally has strict timing or logic.
- **Strategy:** Mock a 1-second 'Attack' animation. Start the attack via `InputManager`. Advance the mixer (`update`) by 0.5 seconds so the attack is halfway done. Then forcefully trigger a state that *should* interrupt it (e.g., receiving a 'Hit' or 'Death' event).
- **Assertions:** Verify that `AnimationAction.stop()` or `crossFadeTo()` is called correctly on the 'Attack' action, resetting its time to 0, preventing the damage frame (e.g., progress > 0.3) from firing post-interruption.

## 3. Caveats
- Since the actual `AnimationMixer` logic is not yet implemented in `PlayerController`, these test strategies rely on typical THREE.js mixer patterns.
- Implementation details (like whether fallback to 'Idle' is standard or if it throws a custom error) are assumed to favor "no crashing / graceful degradation".
- Mocks will need to provide valid skeletal meshes so that `AnimationMixer` constructor does not throw due to missing bones.

## 4. Conclusion
By mocking `AssetManager.loadModel` to return crafted `THREE.AnimationClip` arrays and programmatically stepping the `InputManager` and `PlayerController.update` loop, we can comprehensively test animation boundaries (Empty, Missing, Rapid, Invalid, Interrupted) without needing actual `.glb` files.

## 5. Verification Method
1. Create the file `tests/e2e/tier2/animations.test.ts`.
2. Implement the 5 test cases described above using Vitest.
3. Run `npm run test` (or `vitest tests/e2e/tier2/animations.test.ts`).
4. Ensure the tests act as TDD assertions for the upcoming Milestone 1 implementation.
