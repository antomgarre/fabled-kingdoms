# Handoff Report: Test Infra & Feature 1

## Observation
- `package.json` contains `"test:e2e": "vitest run tests/e2e"` in its `scripts` but lacks `vitest` and `jsdom` in `devDependencies`.
- `src/engine/AssetManager.ts` uses `three/examples/jsm/loaders/GLTFLoader.js` to load `.glb` files.
- Upon successful loading, `AssetManager` populates `this.models[name]` with the resulting `gltf` object.
- `AssetManager` traverses the loaded `gltf.scene` and sets `castShadow = true` and `receiveShadow = true` for all child meshes.
- `AssetManager` rejects the returned Promise on failure.
- `TEST_INFRA.md` requires ≥5 opaque-box test cases for Tier 1.

## Logic Chain
- `vitest` and `jsdom` (needed for `three.js` loader compatibility in Node) must be installed.
- The `test:e2e` script in `package.json` is already configured to run tests in `tests/e2e`.
- The tests should be placed in `tests/e2e/tier1/` according to `SCOPE.md` architecture.
- We need exactly ≥5 tests mapping directly to the behaviors observed in `AssetManager.ts`. Because we want to test opaque-box, the implementer can use `vi.mock('three/examples/jsm/loaders/GLTFLoader.js')` to simulate the network responses and provide dummy meshes, or use a local `.glb` file. Mocking the GLTFLoader response is usually more stable in headless environments.

## Caveats
- Since tests will run in Node using Vitest, loading real `.glb` files over XHR/fetch might fail without a server. The implementer should heavily consider using `vi.mock` on the `GLTFLoader` to mock the file loading and yield a fake `gltf` object with a `scene` containing mock meshes.

## Conclusion
**Worker Implementation Plan:**

1. **Install Dependencies:**
   Run `npm install --save-dev vitest jsdom`.

2. **Configure Vitest (if needed):**
   Ensure `vite.config.ts` has `test: { environment: 'jsdom' }` added, or add `// @vitest-environment jsdom` to the top of the test file.

3. **Create Test File:**
   Create the file `tests/e2e/tier1/feature1-model-loading.test.ts`.

4. **Implement ≥5 Test Cases in `feature1-model-loading.test.ts`:**
   - *Test Case 1 (Load Success):* Call `AssetManager.loadModel('robot', 'dummy-url')` and verify the Promise resolves to a `gltf` object.
   - *Test Case 2 (Model Caching):* Verify that after loading, `AssetManager.models['robot']` is populated and matches the loaded object.
   - *Test Case 3 (Shadow Configuration):* Check that the `scene` returned has meshes where `castShadow` and `receiveShadow` are strictly `true`.
   - *Test Case 4 (Error Handling):* Force a load failure (e.g., mock the loader to trigger its `onError` callback) and verify that `AssetManager.loadModel()` rejects.
   - *Test Case 5 (Multiple Loads):* Load two different models ('modelA', 'modelB') and verify both exist in `AssetManager.models` without overwriting each other.

## Verification Method
- Execute `npm install`.
- Execute `npm run test:e2e`.
- The test output should report 1 test suite (`feature1-model-loading.test.ts`) and at least 5 passing tests.
