# Handoff Report: Tier 3 E2E Tests (Pairwise) Strategy

## 1. Observation
- The project implements a frontend 3D MMO engine with `three.js`. Features are implemented in `src/engine/` (`AssetManager.ts`, `AudioEngine.ts`), `src/player/`, and `src/ai/` (`GameMaster.ts`).
- `SCOPE.md` defines Milestone 1 for Tier 3 E2E Tests as creating pairwise tests for 5 features (F1 to F5), resulting in 10 pairwise interactions in `tests/e2e/tier3/pairwise.test.ts`.
- `TEST_INFRA.md` requires "opaque-box" testing methodologies.
- The `package.json` contains a `test:e2e` script (`vitest run tests/e2e`) but `vitest` itself is not yet installed in `devDependencies`.
- `AudioEngine.ts` uses browser APIs like `window.AudioContext`. `GameMaster` and local persistence use Node's `fs` and `path`.
- Currently, F1 (AssetManager) and F2 (Skeletal Animations) are only partially integrated (the player uses procedural geometry instead of loaded `.glb` files with `THREE.AnimationMixer`).

## 2. Logic Chain
- To test the 10 pairwise combinations between F1-F5 in a Node environment using `vitest`, the test suite must reconcile browser-only APIs (`AudioContext`) with Node-only APIs (`fs`).
- Therefore, the `vitest` configuration must use `jsdom` (or `happy-dom`) for browser globals, alongside `vi.mock()` to stub Web Audio APIs, Three.js `GLTFLoader`, and `fs` (to prevent polluting the real disk during tests).
- Because tests must be "opaque-box", we shouldn't rely on internal states. Instead, we instantiate the manager classes (`GameMaster`, `AssetManager`, `AudioEngine`, `PlayerController`) and use `vi.spyOn()` on their public methods (e.g., `loadModel`, `playSound`, `generateRegion`) to verify that an action in one feature correctly triggers the public contract of another.
- Even though F1 and F2 are partially implemented in the actual codebase, we can write the test assertions around their planned public interfaces (as defined in `PROJECT.md`) using mocks.

## 3. Caveats
- `vitest` and `jsdom` need to be installed before the tests can be run.
- Because F1 and F2 (GLTF Model loading and Skeletal Animations) are labeled `IN_PROGRESS` in `PROJECT.md` and currently missing integration in `PlayerModel`, some tests might fail if run against the real implementation. Mocks should be heavily utilized for these tests until the feature is completed.
- I am operating in a read-only capacity for the actual source codebase, so I have not installed `vitest` or created the test files directly in `src/`.

## 4. Conclusion
The implementation of the Tier 3 Pairwise tests should proceed by:
1. Installing `vitest` and `jsdom`.
2. Setting up a mocked test environment for `AudioContext`, `GLTFLoader`, and `fs`.
3. Writing the 10 test cases in `tests/e2e/tier3/pairwise.test.ts` focusing on spying on the public APIs (e.g., checking that `GameMaster.generateRegion()` results in corresponding calls to `AssetManager.loadModel()`). 
A detailed breakdown of all 10 pairwise test strategies is available in `analysis.md`.

## 5. Verification Method
- **Method**: The next agent should install `vitest`, create the `pairwise.test.ts` following the strategy in `analysis.md`, and run `npm run test:e2e`.
- **Invalidation**: The strategy is invalidated if the application architecture pivots away from the public interfaces defined in `PROJECT.md` (e.g., if `AssetManager` no longer uses `loadModel()`).
