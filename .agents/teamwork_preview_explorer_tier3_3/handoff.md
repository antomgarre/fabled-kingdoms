# Handoff Report: Tier 3 E2E Tests (Pairwise)

## Observation
- Vitest test runner is expected by the E2E infrastructure (`npm run test:e2e`), but `vitest` is not currently in `package.json` devDependencies.
- The testing environment will be Node-based. Browser-specific APIs used by the project (`window.AudioContext` in `AudioEngine.ts`, and `fetch`/XHR inside `GLTFLoader` in `AssetManager.ts`) are not natively available.
- Features F1-F5 have public interfaces exposed in `AssetManager.ts`, `AudioEngine.ts`, `GameMaster.ts`, `PlayerModel.ts`, and `EnemyModel.ts`.
- `tests/e2e/tier3/pairwise.test.ts` does not exist yet.

## Logic Chain
1. Since the project requires opaque-box pairwise testing for 5 features, we need exactly 10 test combinations (F1-F2, F1-F3, ..., F4-F5).
2. Opaque-box means we should only invoke the public methods (e.g., `AssetManager.loadModel`, `AudioEngine.playFootstep`, `GameMaster.generateRegion`, `Persistence.saveRegion`) and verify outputs/state changes, avoiding testing internal logic.
3. Because this is a Node environment, we cannot spawn a real WebGL canvas or play real audio. Thus, to allow the code to run and be tested opaquely, `AudioContext` and `fetch` must be mocked at the vitest global level (`beforeAll`).
4. Tests will manipulate the scene graphs (THREE.Group, THREE.AnimationMixer) and the mocked audio graph directly to assert integration success.

## Caveats
- No real DOM/WebGL context means tests only verify logical state (e.g., node counts, mixer ticks, promise resolutions), not visual correctness.
- We assume `fetch` will be mocked to return dummy GLTF structures rather than using real `.glb` assets, though using local `file://` assets could also work depending on the vitest configuration.
- The exact skeletal animations in `PlayerModel` and `EnemyModel` are still procedural/mocked in some places (e.g., `EnemyModel.dieAnimation` does not use `AnimationMixer` yet), so the tests will need to mock or trigger these placeholders until Milestone 1 Visuals is completed.

## Conclusion
The strategy is sound and ready for implementation. The 10 pairwise test cases can be structured as separate `it()` blocks within `tests/e2e/tier3/pairwise.test.ts`. The primary challenge will be the vitest test environment setup (mocking browser globals). The implementer should first install `vitest` and `jsdom` (or `happy-dom`), write a setup script for `AudioContext`, and then implement the 10 pairwise interactions described in `analysis.md`.

## Verification Method
- **Command:** `npm install -D vitest` followed by `npm run test:e2e` (or `npx vitest run tests/e2e`).
- **Condition:** All 10 pairwise combinations execute without environment errors (like missing AudioContext) and pass successfully.
- **Files to Inspect:** `tests/e2e/tier3/pairwise.test.ts` to ensure each test strictly targets exactly two features' public APIs simultaneously.
