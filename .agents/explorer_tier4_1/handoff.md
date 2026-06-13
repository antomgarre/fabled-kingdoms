# Handoff: Tier 4 E2E Test Strategy

## Observation
- `PROJECT.md` defines the overall architecture and Interface Contracts for `AssetManager`, `AudioEngine`, `GameMaster`, and `Persistence`.
- `TEST_INFRA.md` requires >=5 "Real-World Application Scenarios (Tier 4)" to be implemented using `vitest` in `tests/e2e/tier4/`.
- Tests must be opaque-box, requirement-driven, and interact via interfaces.
- The project uses DOM elements (Canvas, AudioContext) so testing E2E requires a browser-like environment (`jsdom`) or mocking these APIs. `GameMaster` and `Persistence` interact with the Node filesystem.
- `Game.ts` acts as the main orchestrator, initializing systems like `AudioEngine`, `PlayerController`, `EnemyManager`, etc.

## Logic Chain
1. To fulfill the opaque-box requirement, tests should treat the application as a black box where possible. Inputs are either method calls on public interfaces (e.g., `GameMaster.generateRegion()`) or simulated user events (keydown, click).
2. The tests map directly to the 5 scenarios listed in `TEST_INFRA.md`.
3. Vitest can handle DOM APIs via `jsdom`, allowing us to instantiate the `Game` singleton, dispatch events to the canvas, and spy on public subsystem interfaces to verify outcomes.
4. E2E tests for 3D/Audio are hard to verify via pixels/soundwaves, so we verify by intercepting the boundary interfaces (`AudioContext`, `AssetManager` load calls, and `AnimationMixer` state).

## Caveats
- Since actual `THREE.WebGLRenderer` requires a WebGL context, tests instantiating `Game.ts` may need to mock WebGL or use a headless GL environment. The Worker must handle Three.js/WebGL mock setup.
- Skeletal animations (Milestone 1) are marked as `IN_PROGRESS` in `PROJECT.md`, so the test assertions for animations might fail until the feature is fully implemented. The tests should be written against the expected interface (e.g., verifying `AnimationMixer.clipAction` is called).

## Conclusion
The implementation strategy involves creating 5 test files under `tests/e2e/tier4/`, utilizing `vitest` with a `jsdom` environment and necessary mocks for WebGL/AudioContext.

### Target Test Files

1. **`tests/e2e/tier4/scenario-1-player-actions.test.ts`**
   - **What it tests:** Player movement and combat. Simulates 'W' key press and mouse click on the canvas. Verifies that `AssetManager` attempts to load models with animations, and asserts that the expected audio interface methods (`playFootstep`, `playSwordSwing`) are triggered.

2. **`tests/e2e/tier4/scenario-2-gamemaster-io.test.ts`**
   - **What it tests:** Region generation and local persistence. Interacts purely with `GameMaster` and `Persistence`. Calls `generateRegion()`, writes it via `saveRegion()` to a test directory, and reads it back via `loadRegion()`. Asserts structural equality and file creation.

3. **`tests/e2e/tier4/scenario-3-ai-creatures.test.ts`**
   - **What it tests:** AI spawning and death cycle. Mocks a `RegionBlueprint` containing enemies. Initializes the game. Simulates player combat interactions reducing an enemy's HP to 0. Verifies `AudioEngine.playEnemyHit` is called and a skeletal death animation is queued.

4. **`tests/e2e/tier4/scenario-4-player-loads-region.test.ts`**
   - **What it tests:** End-to-end integration of Persistence and Engine. Seeds the test environment with a specific mock region JSON. Boots the `Game` and checks that `AssetManager` loads the expected location models and the player is correctly bounded/spawned in the loaded region.

5. **`tests/e2e/tier4/scenario-5-audio-stress.test.ts`**
   - **What it tests:** System stability under heavy workload. Rapidly fires multiple `AudioEngine` methods (`playFootstep`, `playEnemyHit`, `playSwordSwing`) concurrently simulating a large battle. Verifies the AudioContext gracefully handles the buffer load without throwing exceptions or crashing.

## Verification Method
- **Directory check**: `dir tests\e2e\tier4\` to ensure files are created.
- **Execution**: Run `npm run test:e2e` (or `npx vitest run tests/e2e/tier4`) to confirm tests execute.
- **Validation**: Ensure tests fail gracefully if features (like skeletal animations) are incomplete, and pass when mocked appropriately.
