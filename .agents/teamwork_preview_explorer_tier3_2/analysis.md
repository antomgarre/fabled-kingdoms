# Tier 3 E2E Tests: Pairwise Testing Strategy Analysis

## Objective
Implement opaque-box test cases using `vitest` to verify the pairwise interactions of the 5 core features defined in `TEST_INFRA.md`. The tests must be requirement-driven and rely on the public interfaces of the modules.

## Features
- **F1**: 3D Model Loading (`AssetManager`)
- **F2**: Skeletal Animations (`AnimationMixer` integration)
- **F3**: Audio Playback (`AudioEngine`)
- **F4**: AI Game Master (`GameMaster`)
- **F5**: Local Persistence (`Persistence`)

## Test Environment & Mocking Strategy
Since the tests run in Node.js via `vitest` and not in a browser with a full WebGL/AudioContext environment, we must mock hardware and external I/O boundaries while keeping the application logic intact (opaque-box):
1. **F1 & F2 (3D Models & Animations)**: Mock `three/examples/jsm/loaders/GLTFLoader`. Return a synthetic `GLTF` object containing a `THREE.Group` and dummy `THREE.AnimationClip` objects. Verify `AnimationMixer` bindings by checking if `mixer.clipAction()` is called on the synthetic clips.
2. **F3 (Audio)**: Mock `window.AudioContext` or mock the internal Web Audio API calls. Since the implementation might switch from procedural generation to `.mp3/.wav` loading via `fetch`, mock `fetch` for audio files or spy on `AudioEngine.playSound`.
3. **F4 & F5 (Game Master & Persistence)**: Use `vitest`'s `vi.spyOn` on standard filesystem modules (`fs/promises` or `localStorage` depending on where the JSON is written) to intercept `saveRegion` and `loadRegion` operations, or test them purely against a temporary local `/data/` directory.

## 10 Pairwise Test Scenarios
To achieve pairwise coverage, `tests/e2e/tier3/pairwise.test.ts` should implement the following test cases:

1. **[F1, F2] Model + Animation**: 
   - *Action*: `AssetManager` loads a character model. 
   - *Assertion*: The resolved `GLTF` contains animations, and an `AnimationMixer` can successfully create an action from it and advance its time without throwing errors.
2. **[F1, F3] Model + Audio**:
   - *Action*: An entity model is loaded into the scene.
   - *Assertion*: Its 3D position (`THREE.Vector3`) is successfully passed to `AudioEngine.playSound(..., position)` to play a positional spawn/footstep sound.
3. **[F1, F4] Model + Game Master**:
   - *Action*: `GameMaster.generateRegion()` creates a region containing a specific NPC type.
   - *Assertion*: The engine calls `AssetManager.loadModel()` with the correct URL mapped to that NPC type.
4. **[F1, F5] Model + Persistence**:
   - *Action*: `Persistence.loadRegion()` restores a saved state containing a custom enemy.
   - *Assertion*: The deserialization process correctly triggers `AssetManager.loadModel()` for that specific enemy.
5. **[F2, F3] Animation + Audio**:
   - *Action*: A character state changes to "Attack", triggering an attack animation.
   - *Assertion*: The animation state change simultaneously triggers `AudioEngine.playSound('sword_swing')`.
6. **[F2, F4] Animation + Game Master**:
   - *Action*: `GameMaster` updates the global AI state, commanding an NPC to die.
   - *Assertion*: The NPC's model transitions its skeletal animation state to the "Death" clip.
7. **[F2, F5] Animation + Persistence**:
   - *Action*: A region is saved while an entity is actively in a "Walk" state, then loaded.
   - *Assertion*: Upon load, the entity's `AnimationMixer` is restored and immediately plays the "Walk" clip.
8. **[F3, F4] Audio + Game Master**:
   - *Action*: `GameMaster.generateRegion()` generates a spooky environment.
   - *Assertion*: `GameMaster` instructs `AudioEngine` to play the appropriate ambient sound (e.g., ambient wind).
9. **[F3, F5] Audio + Persistence**:
   - *Action*: Save a game state where a specific looping environmental audio is active. Restore it.
   - *Assertion*: `AudioEngine` restores the audio context and resumes the specific sound loop.
10. **[F4, F5] Game Master + Persistence**:
    - *Action*: Generate a complex `RegionData` object via `GameMaster`. Pass it to `Persistence.saveRegion()`. Read it back via `Persistence.loadRegion()`.
    - *Assertion*: The loaded region data is a deep equal match to the original, preserving all AI entities, positions, and states.

## Recommendations for Implementation
- Create `tests/e2e/tier3/pairwise.test.ts`.
- Use a `setupFiles` configuration in vitest (or just global mocks in the test file) to handle `THREE.WebGLRenderer`, `GLTFLoader`, and `AudioContext` stubs.
- Group the tests under a single `describe('Tier 3 Pairwise Combinations', () => { ... })` block.
- Keep the tests focused on the *interfaces* provided in `PROJECT.md` rather than current procedural implementations (e.g., expect `loadModel` and `loadSound` to be used).
