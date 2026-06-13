# Analysis: Tier 3 E2E Pairwise Testing Strategy

## Overview
This document analyzes the strategy for implementing Milestone 1 of the Tier 3 E2E Tests. The goal is to create opaque-box tests covering 10 pairwise combinations of the 5 core features: F1 (3D Model Loading), F2 (Skeletal Animations), F3 (Audio Playback), F4 (AI Game Master), and F5 (Local Persistence) using `vitest`.

## Feature Interfaces
Based on the codebase and `PROJECT.md`, the external interfaces to be tested are:
- **F1 (3D Model Loading):** `AssetManager.loadModel()` (expected to return a Promise resolving to a THREE.js GLTF object).
- **F2 (Skeletal Animations):** `PlayerModel` / `EnemyModel` and their `THREE.AnimationMixer` interactions.
- **F3 (Audio Playback):** `AudioEngine` (currently implemented with `init()`, `playFootstep()`, `playSwordSwing()`, etc.).
- **F4 (AI Game Master):** `GameMaster.generateRegion()`.
- **F5 (Local Persistence):** `Persistence.saveRegion()` and `loadRegion()`.

## Environmental & Mocking Considerations (Vitest)
Because these are frontend components tested in a Node-based `vitest` environment, we must address missing browser APIs to keep the tests opaque without modifying product code:
1. **AudioContext (F3):** `AudioEngine` relies on `window.AudioContext`. We need a global mock or stub in the Vitest setup file to prevent errors.
2. **GLTFLoader (F1):** `AssetManager` uses `GLTFLoader`, which relies on `fetch` or XHR. We should mock the global `fetch` to return a minimal valid ArrayBuffer representing a `.glb` or stub the network layer.
3. **THREE.js WebGL:** We must avoid invoking `WebGLRenderer` since it requires a real canvas. The tests should only manipulate the scene graph (Groups, Meshes, Mixers).

## Pairwise Test Cases Strategy
We recommend grouping these tests in `tests/e2e/tier3/pairwise.test.ts`.

1. **F1 & F2 (Model Loading + Animations):**
   - *Test:* Call `AssetManager.loadModel()`, verify the returned `GLTF` contains `.animations`. Feed these animations into an `AnimationMixer` attached to a `PlayerModel` and tick the mixer, verifying bone/node positions update.
2. **F1 & F3 (Model Loading + Audio):**
   - *Test:* Load an enemy model via `AssetManager.loadModel()`, and upon success, trigger `AudioEngine.playEnemyHit()`. Verify both operations succeed and the mock `AudioContext` records a play event.
3. **F1 & F4 (Model Loading + Game Master):**
   - *Test:* Call `GameMaster.generateRegion()`. For an entity defined in the returned blueprint, use `AssetManager.loadModel()` to load its visual representation.
4. **F1 & F5 (Model Loading + Persistence):**
   - *Test:* Generate a region, save it using `Persistence.saveRegion()`. Load it with `loadRegion()`, parse the entities, and call `AssetManager.loadModel()` for the loaded entity types.
5. **F2 & F3 (Animations + Audio):**
   - *Test:* Simulate an attack animation using `AnimationMixer` on a model, and assert that a listener or event triggers `AudioEngine.playSwordSwing()`.
6. **F2 & F4 (Animations + Game Master):**
   - *Test:* `GameMaster.generateRegion()` creates enemies with specific states (e.g., 'patrol'). Verify that parsing this state correctly sets the `AnimationMixer` to the corresponding animation (e.g., 'walk').
7. **F2 & F5 (Animations + Persistence):**
   - *Test:* Save a region with an enemy in a 'dead' state via `Persistence.saveRegion()`. Upon `loadRegion()`, verify the `AnimationMixer` transitions to the 'death' animation frame.
8. **F3 & F4 (Audio + Game Master):**
   - *Test:* When `GameMaster.generateRegion()` is invoked to create a new area, trigger `AudioEngine.playAmbientViento()` to start ambient sound. Verify the audio graph connected correctly.
9. **F3 & F5 (Audio + Persistence):**
   - *Test:* Load a saved region via `Persistence.loadRegion()`. Based on the biome/data, assert that `AudioEngine` is signaled to play the correct environmental sounds.
10. **F4 & F5 (Game Master + Persistence):**
    - *Test:* `GameMaster.generateRegion()` creates a mock blueprint. `Persistence.saveRegion()` writes it to disk. `Persistence.loadRegion()` retrieves it, and a deep equality check confirms data integrity.

## Recommended Next Steps for Implementer
1. Run `npm install -D vitest` and update `package.json` if needed.
2. Create the `tests/e2e/tier3/pairwise.test.ts` file.
3. Implement a setup block `beforeAll` in the test file to mock `window.AudioContext` and `global.fetch`.
4. Write the 10 test cases as defined above, ensuring no internal methods are called directly except the documented public API.
