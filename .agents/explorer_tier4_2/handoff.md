# Handoff Report: Tier 4 E2E Test Design

## Observation
- `TEST_INFRA.md` specifies 5 Tier 4 scenarios for E2E testing exercising features F1-F5.
- `PROJECT.md` specifies interface contracts for `AssetManager`, `AudioEngine`, and `GameMaster`/`Persistence`.
- Source code inspection (`src/engine/AudioEngine.ts`, `src/player/PlayerController.ts`, `src/ai/EnemyManager.ts`) shows that the current implementation uses programmatic sound generation (e.g., `playFootstep()`, `playEnemyHit()`) and procedural animations (e.g., `leftLegPivot.rotation.x`) rather than the finalized `loadSound` or `AnimationMixer` stated in the architecture.
- `GameMaster.generateRegion()` returns a mocked `IRegionBlueprint`, and `Persistence` provides file I/O operations under `data/`.
- Tests must be located in `tests/e2e/tier4/` and run using `npm run test:e2e`. The project uses `vitest`.

## Logic Chain
- To maintain opaque-box principles, tests must interact with high-level managers (`PlayerController`, `EnemyManager`, `GameMaster`) and verify behavior by observing side effects (spies on `AudioEngine` methods, `fs` state, or model transforms).
- The 5 scenarios directly dictate the test files and the flows to execute:
  1. **Scenario 1**: Demands simulating movement and attack inputs and verifying audio and animation side effects.
  2. **Scenario 2**: Demands generating a region, writing it to disk, and reading it back to verify serialization.
  3. **Scenario 3**: Demands initializing enemies, dealing fatal damage via `PlayerController` interface, and verifying the death state transition and audio.
  4. **Scenario 4**: Demands loading a saved environment and successfully placing the player within it.
  5. **Scenario 5**: Demands a stress scenario where an audio method (like `playEnemyHit`) is called many times simultaneously without crashing.

## Caveats
- The codebase is currently in `IN_PROGRESS` for Milestones 1 and 2. Therefore, tests should spy on the *currently implemented* methods in `AudioEngine` (e.g., `playFootstep`, `playSwordSwing`) and `PlayerModel` (e.g., `bodyPivot`) instead of the planned milestone interfaces, to ensure tests actually run against the real codebase. 
- Some tests might require mocking browser APIs like `AudioContext` depending on the Vitest environment setup.
- Clean up file side-effects (e.g., `data/test-*.json`) in `afterAll` blocks.

## Conclusion

The Worker should create the following 5 test files in `tests/e2e/tier4/`:

1. **`player-combat-flow.test.ts`**
   - **Tests**: Player moves, swings weapon, triggers audio and skeletal animations.
   - **Strategy**: Instantiate `PlayerController` and a mocked `InputManager`. Simulate the 'W' key and call `update()`. Assert position changes and spy on `AudioEngine.playFootstep`. Simulate a left-click and call `update()`. Assert `AudioEngine.playSwordSwing` is called and animation pivots (e.g., `rightArmPivot.rotation.x`) change.

2. **`gamemaster-persistence-flow.test.ts`**
   - **Tests**: Game master generates region, saves to disk, loads from disk.
   - **Strategy**: Instantiate `GameMaster`. Call `generateRegion()`. Pass the result to `Persistence.saveRegion('tier4-e2e-test', region)`. Verify the file exists. Call `Persistence.loadRegion('tier4-e2e-test')`. Assert the loaded object deeply equals the generated object. Clean up the file.

3. **`enemy-combat-death-flow.test.ts`**
   - **Tests**: AI spawns creatures, creatures die and play death animation.
   - **Strategy**: Initialize `EnemyManager` and verify enemies spawn. Simulate an attack from `PlayerController` positioned near an enemy (triggering `checkMeleeHit`). Spy on `AudioEngine.playEnemyHit`. Reduce enemy health to 0, advance time via `update()`, and verify the enemy's state changes to `'die'` and its death animation progresses.

4. **`player-enters-saved-region.test.ts`**
   - **Tests**: Player loads saved region and enters it.
   - **Strategy**: Save a mock `IRegionBlueprint` to disk using `Persistence`. Load it back. Instantiate the `TerrainGenerator` and `PlayerController` using the loaded data. Run a few frames of `update()`. Assert the player is correctly grounded to the loaded terrain height without throwing errors.

5. **`audio-stress.test.ts`**
   - **Tests**: Audio stress test (many footsteps and impacts).
   - **Strategy**: Spy on `AudioEngine.playEnemyHit` and `playFootstep`. Spawn 50 enemies via `EnemyManager`. Simulate a massive AoE hit from the player that strikes all enemies in a single frame. Assert the spy is called 50 times in that frame and that no `AudioContext` exceptions are thrown.

## Verification Method
- The Worker must verify the implementation by running `npm run test:e2e`.
- The worker must inspect `tests/e2e/tier4/` to confirm the exact 5 files exist.
- All tests should pass and maintain opaque-box separation (no reliance on internal private state, interacting only via `update()`, `InputManager`, or `Persistence`).
