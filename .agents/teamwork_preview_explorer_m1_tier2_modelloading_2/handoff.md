# Handoff Report: Tier 2 Boundary & Corner Cases for Model Loading

## Observation
- `SCOPE.md` assigns milestone `M1_Tier2_ModelLoading`: implement >=5 boundary/corner test cases for 3D Model Loading in `tests/e2e/tier2/model_loading.test.ts`.
- Required focus areas: invalid URLs, empty URLs, very large files, network failures, missing extension.
- `PROJECT.md` specifies the `AssetManager` interface, specifically `loadModel(url: string)`.
- `src/engine/AssetManager.ts` implements `loadModel(name: string, url: string): Promise<GLTF>`. It wraps `GLTFLoader.load` in a Promise, successfully resolving if loaded, and rejecting via the `onError` callback on failure.
- `package.json` reveals the test runner is `vitest` (`vitest run tests/e2e`).

## Logic Chain
1. Since tests must be opaque-box and focus on the `AssetManager.loadModel` method, we need to assert that the returned `Promise` rejects properly under error conditions.
2. `three.js`'s `GLTFLoader` relies on `FileLoader`, which uses the global `fetch` API. To simulate network-level corner cases (network failures, very large files), we must mock `global.fetch` using `vi.spyOn(global, 'fetch')`.
3. The 5 specific boundary tests can be structured as follows:
   - **Invalid URLs**: Provide an invalid URL (e.g., `invalid-url-format` or a 404 endpoint). Assert that `AssetManager.loadModel` rejects.
   - **Empty URLs**: Pass `""` as the URL string. Assert that it rejects immediately.
   - **Network failures**: Mock `global.fetch` to reject with `new TypeError('Failed to fetch')` to simulate an offline state or DNS failure.
   - **Missing extension**: Pass a URL without `.glb` or `.gltf` (e.g., `http://localhost/model`). Return invalid or plain text content via the fetch mock to ensure `GLTFLoader` fails to parse it and rejects.
   - **Very large files**: Mock `global.fetch` to return an artificially massive `ArrayBuffer` or a mock response that simulates a timeout/out-of-memory error, or simply verify how the promise reacts when simulated stream limits are exceeded.

## Caveats
- `AssetManager` itself does not currently contain custom logic for file extensions or size limits; it relies entirely on `GLTFLoader`. The tests will effectively verify that `GLTFLoader`'s error states are correctly surfaced as Promise rejections by `AssetManager`.
- Mocking `fetch` in `vitest` might require ensuring the environment supports `fetch` (Node 18+ does).
- Actually generating a "very large file" in memory could crash the test runner, so the test for very large files should either mock the `Content-Length` header to a massive value and simulate a rejection, or simulate an `ArrayBuffer` allocation failure.

## Conclusion
To implement the `M1_Tier2_ModelLoading` tests, create `tests/e2e/tier2/model_loading.test.ts` using `vitest`. Use `vi.spyOn(global, 'fetch')` to control network responses. Implement the 5 test cases using `expect(assetManager.loadModel(...)).rejects.toThrow()` (or similar `.rejects` assertions) to guarantee that boundary and corner cases gracefully result in rejected promises instead of silent failures.

## Verification Method
1. The implementer should create the file at `tests/e2e/tier2/model_loading.test.ts`.
2. Inspect the file to confirm all 5 scenarios are covered using `vitest`'s `describe` and `it` blocks.
3. Run the tests using `npx vitest run tests/e2e/tier2/model_loading.test.ts`. The tests should pass and report 5/5 successful boundary checks.
