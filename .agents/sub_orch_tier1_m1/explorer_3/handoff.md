# Handoff Report: Test Infra & Feature 1 (3D Model Loading)

## 1. Observation
- `package.json` contains a `test:e2e` script `"vitest run tests/e2e"`, but `vitest` is not installed in `devDependencies`.
- `TEST_INFRA.md` specifies Tier 1 tests using `vitest` in the `tests/e2e/tier1/` directory with >= 5 tests per feature.
- `src/engine/AssetManager.ts` exports an `AssetManager` class with a `loadModel(name: string, url: string): Promise<GLTF>` method. It instantiates `GLTFLoader`, sets `castShadow` and `receiveShadow` to `true` on all child meshes, caches the loaded GLTF in `this.models[name]`, and resolves the promise. It rejects on error.
- GLB models are available in `public/models/` (`RobotExpressive.glb`, `Soldier.glb`).
- `vitest` running in Node does not natively support `XMLHttpRequest` or `fetch` for local files (which `GLTFLoader` uses), so a test environment like `jsdom` and/or mocking is required.

## 2. Logic Chain
- To fulfill the infrastructure requirement, `vitest` must be installed. Installing `jsdom` is also recommended to support DOM APIs used by `three`.
- The `test:e2e` command in `package.json` needs to ensure the environment is set properly. We should update it to: `"vitest run tests/e2e --environment jsdom"`.
- Since tests are opaque-box, we should test the public interface of `AssetManager` (`loadModel` and the `models` dictionary).
- Because `GLTFLoader` uses browser APIs to fetch models, tests should mock `GLTFLoader.prototype.load` (using `vitest`'s `vi.mock` or spying) to reliably test `AssetManager` logic without network/file access issues in a Node environment.
- The required test file is `tests/e2e/tier1/feature1-model-loading.test.ts`.

## 3. Caveats
- Opaque-box testing `AssetManager` without mocking is difficult in `vitest` because `GLTFLoader` makes real HTTP requests. The implementer will need to mock `GLTFLoader.prototype.load` to simulate successes and failures. This slightly violates "opaque-box" testing but is standard practice for testing browser-loader APIs in Node.
- The implementer can choose how exactly to mock the loader, as long as the 5 required test scenarios are covered.

## 4. Conclusion
**Implementation Plan for Worker:**

1. **Install Dependencies:**
   Run: `npm install -D vitest jsdom`

2. **Update `package.json`:**
   Modify the `"test:e2e"` script to: `"vitest run tests/e2e --environment jsdom"`

3. **Create Test File:**
   Create the directory `tests/e2e/tier1/` and the file `tests/e2e/tier1/feature1-model-loading.test.ts`.

4. **Implement Test Cases (`feature1-model-loading.test.ts`):**
   Design >= 5 test cases testing `AssetManager` (using `vi.mock` on `GLTFLoader` or spying on its `load` method):
   - **Case 1: Valid Loading:** Calling `loadModel` with a valid URL resolves with a `GLTF` object containing a `scene` (`THREE.Group`).
   - **Case 2: Shadow Assignment:** Verify that when `loadModel` succeeds, it traverses the `scene` and sets `castShadow` and `receiveShadow` to `true` on all meshes.
   - **Case 3: Model Caching:** Verify that after loading, the model is cached correctly in the `AssetManager.models` dictionary under the provided `name`.
   - **Case 4: Animation Access:** Verify that the resolved `GLTF` object retains the `animations` array so it is accessible for the AnimationMixer.
   - **Case 5: Error Handling:** Verify that if the loader encounters an error (e.g. invalid URL), the `loadModel` promise is rejected with an appropriate error.

## 5. Verification Method
- Verify `package.json` has `vitest` and `jsdom` in `devDependencies`.
- Run `npm run test:e2e` and ensure all 5 tests in `feature1-model-loading.test.ts` pass without errors.
- Ensure no source files in `src/` were modified, only tests were added.
