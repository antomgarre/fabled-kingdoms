# Analysis: Tier 3 E2E Tests (Pairwise Combinations)

## 1. Goal & Scope
The objective is to implement "Milestone 1: Pairwise Tests Implementation" for Tier 3 E2E testing using `vitest`. The target features are:
- **F1**: 3D Model Loading
- **F2**: Skeletal Animations
- **F3**: Audio Playback
- **F4**: AI Game Master
- **F5**: Local Persistence

We must cover the 10 pairwise combinations with opaque-box tests, which means asserting on the public APIs of `AssetManager`, `AudioEngine`, `GameMaster`, `PlayerController`, etc., without worrying about internal procedural geometries or audio buffer implementations.

## 2. Current Implementation State
- **F1 & F2**: Partially implemented / in progress. `PlayerModel` currently uses procedural meshes instead of `GLTFLoader`. `AssetManager` has `loadModel` but it is not yet integrated with `AnimationMixer` inside the Player/Enemy models.
- **F3**: `AudioEngine` is implemented and uses `window.AudioContext`.
- **F4 & F5**: `GameMaster` and `Persistence` (via Node `fs` and `path`) are implemented and generate/save/load basic mock JSON blueprints.

## 3. Environment Setup Recommendations (`vitest` config)
Since these tests interact with browser APIs (`AudioContext`) and Node APIs (`fs`), the test environment must be carefully configured:
1. **Dependencies**: `npm install -D vitest jsdom`
2. **Vitest Config**: Use `environment: 'jsdom'` to provide `window`.
3. **Mocks Required**:
   - `AudioContext`: Mock the Web Audio API since `jsdom` doesn't support it natively.
   - `GLTFLoader`: Mock Three.js loaders so we can pass fake URLs and return mocked `THREE.Group` objects with mock `.animations`.
   - `fs`: For F5, either use a dedicated `/data/test/` folder that is cleaned up before/after tests, or mock `fs` using `vi.mock('fs')` to avoid polluting the real file system.

## 4. The 10 Pairwise Test Scenarios
To achieve pairwise coverage in `tests/e2e/tier3/pairwise.test.ts`:

1. **F1 + F2 (Model + Animation)**
   - *Strategy*: Load a mock model using `AssetManager.loadModel()`. Inject this model into the `PlayerModel`. Assert that a `THREE.AnimationMixer` is created for it and we can trigger an 'Idle' action.
2. **F1 + F3 (Model + Audio)**
   - *Strategy*: Trigger an entity spawn sequence that loads a model (F1) and plays a spawn sound via `AudioEngine` (F3). Assert both `loadModel` and `playSound` (or `playEnemyHit`) are called.
3. **F1 + F4 (Model + Game Master)**
   - *Strategy*: Call `GameMaster.generateRegion()`. For every NPC/Enemy type returned in the region blueprint, assert that the system correctly routes these entities to `AssetManager.loadModel()`.
4. **F1 + F5 (Model + Persistence)**
   - *Strategy*: Call `Persistence.loadRegion()` with a saved state containing entities. Assert that loading this state triggers the system to invoke `AssetManager.loadModel()` for the restored entities.
5. **F2 + F3 (Animation + Audio)**
   - *Strategy*: Simulate an attack action (e.g., `inputManager.consumeLeftClick()`). Assert that `AnimationMixer.clipAction('Attack').play()` is triggered concurrently with `AudioEngine.playSwordSwing()`.
6. **F2 + F4 (Animation + Game Master)**
   - *Strategy*: The `GameMaster` sends a 'death' or 'damage' event to an `EnemyManager`. Assert that the corresponding `EnemyModel` triggers the 'Death' or 'Hit' skeletal animation via `AnimationMixer`.
7. **F2 + F5 (Animation + Persistence)**
   - *Strategy*: Save an entity's state as 'Attacking' or 'Dead' via `Persistence`. Upon `loadRegion`, assert that the entity's `AnimationMixer` is restored and plays the corresponding animation frame/clip.
8. **F3 + F4 (Audio + Game Master)**
   - *Strategy*: Have `GameMaster.generateRegion()` produce an environment type (e.g., 'windy'). Assert that the system reads this and calls `AudioEngine.playAmbientViento()`.
9. **F3 + F5 (Audio + Persistence)**
   - *Strategy*: Save audio volume or persistent ambient states to disk. Call `Persistence.loadRegion()`, and assert that `AudioEngine` initializes and restores these ambient sounds based on the save file.
10. **F4 + F5 (Game Master + Persistence)**
    - *Strategy*: End-to-end data integrity. Call `GameMaster.generateRegion()`, save the result with `Persistence.saveRegion()`, load it back with `loadRegion()`, and assert `deepEqual` between the generated and loaded blueprints.

## 5. Next Steps
- Implement the `vitest` configuration and mock fixtures.
- Write `tests/e2e/tier3/pairwise.test.ts` implementing the 10 scenarios described above using `vi.spyOn()` for the opaque-box verifications.
