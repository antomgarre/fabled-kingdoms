# Handoff Report: Tier 3 E2E Pairwise Tests Strategy

## 1. Observation
- `PROJECT.md` defines 5 main features to be implemented: 3D Model Loading (F1), Skeletal Animations (F2), Audio Playback (F3), AI Game Master (F4), and Local Persistence (F5). It also outlines the interface contracts (`AssetManager.loadModel`, `AudioEngine.playSound`, `GameMaster.generateRegion`, etc.).
- `SCOPE.md` requires implementing Tier 3 E2E Tests covering all 10 pairwise combinations of F1-F5 using `vitest` in `tests/e2e/tier3/pairwise.test.ts`. Tests must be opaque-box and requirement-driven.
- `TEST_INFRA.md` reinforces testing against the public interfaces, regardless of internal implementation.
- Inspection of the codebase (`src/ai/`, `src/engine/`, `src/player/`) reveals that `GameMaster.ts` and `Persistence.ts` are not yet fully present. Additionally, `PlayerModel` and `EnemyModel` currently use procedural meshes/animations and `AudioEngine` uses procedural oscillators, meaning the final GLTF/Audio loading APIs are defined in `PROJECT.md` but not fully utilized across the board yet.
- `package.json` does not currently list `vitest` or `jsdom` in its dependencies.

## 2. Logic Chain
1. Since the project mandates an "opaque-box, requirement-driven" testing philosophy, tests must be designed around the interface contracts established in `PROJECT.md` rather than the current procedural implementations.
2. The Node.js environment used by `vitest` lacks browser-specific APIs (like `AudioContext`, `fetch`, and WebGL/Canvas APIs used by `three.js`). Therefore, the testing strategy must rely on robust stubs for `GLTFLoader` and `AudioContext`.
3. Generating 10 test scenarios is done mathematically by taking pairs of the 5 features and designing a scenario where both are exercised simultaneously through their public APIs (e.g., triggering an animation (F2) which implicitly calls `AudioEngine.playSound` (F3)).
4. Because the target modules are partially implemented, writing the tests now effectively enforces a Test-Driven Development (TDD) cycle. The tests will serve as the spec that the module implementations must satisfy.

## 3. Caveats
- `vitest` and related testing utilities (e.g., `jsdom`) are not yet installed in the `package.json`.
- The tests will likely fail upon initial execution because the application modules (particularly `GameMaster` and `Persistence`) are still `IN_PROGRESS` or missing. The test suite will turn green once those milestones are fulfilled.
- The exact imports and directory paths for missing files will need to be approximated based on `PROJECT.md` (e.g., importing `GameMaster` from `../../src/ai/GameMaster`).

## 4. Conclusion
The implementation of Milestone 1 should proceed by creating `tests/e2e/tier3/pairwise.test.ts`. The implementer must first install `vitest`, then write 10 test cases that intercept external boundaries (`vi.spyOn` for filesystem, `GLTFLoader`, `AudioContext`). The test definitions must follow the 10 pairwise interactions detailed in `analysis.md` (e.g., F1&F2: Loading a model returns an object that `AnimationMixer` can play; F4&F5: GameMaster generates a region that Persistence saves/loads seamlessly). 

## 5. Verification Method
1. Install testing dependencies: `npm install -D vitest`.
2. Inspect the created `tests/e2e/tier3/pairwise.test.ts` to ensure it contains at least 10 `it()` or `test()` blocks matching the combinations of F1-F5.
3. Run the tests using `npx vitest run tests/e2e/tier3/pairwise.test.ts`. 
4. The test file should compile and run. While some tests may fail (due to incomplete game features), the test architecture itself must not crash due to missing mocks for `AudioContext` or `three.js`.
