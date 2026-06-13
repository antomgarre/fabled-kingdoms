# Implementation Plan: Test Infra & Feature 1 (3D Model Loading)

## Observation
- `package.json` already contains the script `"test:e2e": "vitest run tests/e2e"`, but `vitest` is not installed in `devDependencies`.
- The `tests/` directory does not exist.
- `src/engine/AssetManager.ts` implements `loadModel(name: string, url: string): Promise<GLTF>` using `GLTFLoader`. It also traverses the loaded scene to apply shadows and saves the result in an internal `models` record.

## Logic Chain
- To run Vitest tests on Three.js loaders (like `GLTFLoader`), DOM APIs are generally required, so installing `jsdom` alongside `vitest` is best practice.
- The npm script `"test:e2e"` should be updated to ensure the jsdom environment is used if DOM APIs are accessed during testing, or tests must mock `GLTFLoader` entirely.
- 5 Opaque-box tests must verify the core contract described in `PROJECT.md` and the actual implementation in `AssetManager.ts`.

## Caveats
- Since this is Node.js environment, `three/examples/jsm/loaders/GLTFLoader.js` might fail if it attempts to use browser-specific APIs (like `fetch` or `Image`). The implementer will likely need to mock `GLTFLoader` in the test file or rely on `jsdom`. The test case descriptions assume the loader is either mocked or works with `jsdom`.

## Conclusion
The implementer needs to install vitest, configure the test script, create the directory structure, and implement the 5 specific test cases designed below.

### 1. Setup Vitest and Configuration
- **Install Dependencies**: Run `npm install -D vitest jsdom`.
- **`package.json` Configuration**: The script `"test:e2e": "vitest run tests/e2e"` is already present. Update it to `"vitest run tests/e2e --environment jsdom"` to ensure DOM support for Three.js.

### 2. Directories and Files to Create
- **Directories**: Create `tests/e2e/tier1/`
- **File**: Create `tests/e2e/tier1/feature1-model-loading.test.ts`

### 3. Test Cases for `AssetManager` (Opaque-box)
Implement the following 5 tests in `feature1-model-loading.test.ts`:

1. **Successful Model Loading**: Verify that `AssetManager.loadModel("player", "path/to/player.glb")` resolves successfully and returns a valid GLTF object containing a `scene` property.
2. **Shadow Properties Applied**: Verify that when a model is loaded, all `THREE.Mesh` instances within the returned `gltf.scene` have their `castShadow` and `receiveShadow` properties set to `true`.
3. **Internal Storage Population**: Verify that after `loadModel("weapon", "path.glb")` is called, the loaded GLTF object is correctly stored and accessible via `assetManager.models["weapon"]`.
4. **Invalid URL / Error Handling**: Verify that `loadModel("error_test", "nonexistent.glb")` properly rejects the promise when the underlying loader triggers an error.
5. **Animation Data Loading**: Verify that if a loaded model contains animations, the returned GLTF object includes an `animations` array with `THREE.AnimationClip` objects (matching the `PROJECT.md` interface contract for `AnimationMixer` compatibility).

## Verification Method
- Run `npm run test:e2e`. All 5 tests in `tests/e2e/tier1/feature1-model-loading.test.ts` should pass.
- Verify that `vitest` and `jsdom` appear in `devDependencies` of `package.json`.
