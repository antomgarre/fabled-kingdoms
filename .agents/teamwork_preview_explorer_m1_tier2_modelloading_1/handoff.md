# Observation
- Checked `d:\src\fabled kingdoms\.agents\e2e_tier2_orchestrator\SCOPE.md` which requests >=5 boundary/corner test cases for 3D Model Loading in `tests/e2e/tier2/model_loading.test.ts` focusing on invalid URLs, empty URLs, very large files, network failures, missing extension. Tests must use `vitest` and be opaque-box.
- Checked `d:\src\fabled kingdoms\PROJECT.md` which shows `AssetManager.loadModel(url: string): Promise<THREE.Group>` as the interface.
- Analyzed `src/engine/AssetManager.ts`. The actual signature is `loadModel(name: string, url: string): Promise<GLTF>`. It wraps `GLTFLoader.load` into a Promise, resolving on success and rejecting on the `onError` callback. It uses `console.error` to log failures.

# Logic Chain
1. `AssetManager.loadModel` abstracts the GLTF loading. Being opaque-box E2E tests, the tests should interact with `AssetManager` and evaluate its final returned Promise or side effects, rather than inspecting its internal `models` record directly.
2. `GLTFLoader` under the hood uses `THREE.FileLoader`, which in a test environment uses the global `fetch` API.
3. Therefore, to simulate boundary/corner cases without making real external requests or needing local mock files, we should use `vitest`'s `vi.stubGlobal('fetch', ...)` or `vi.spyOn(global, 'fetch')` to intercept the `url` and return mocked `Response` objects or reject the promise.
4. The required test cases can be structured as follows:
   - **Invalid URLs**: Mock `fetch` to resolve with `{ ok: false, status: 404 }`. Assert `loadModel` rejects.
   - **Empty URLs**: Pass `""` as URL. Mock `fetch` to reject (or let the browser/node naturally reject empty fetch). Assert `loadModel` rejects.
   - **Network Failures**: Mock `fetch` to reject with `new TypeError('Failed to fetch')` simulating a disconnected network. Assert `loadModel` rejects.
   - **Missing Extension / Corrupt File**: Pass a URL without `.glb` (e.g. `http://example.com/model`). Mock `fetch` to resolve with `ok: true` but return an invalid body (e.g. plain text `Not a GLTF`). Assert `loadModel` rejects due to `GLTFLoader` parse error.
   - **Very Large Files**: Mock `fetch` to resolve with `ok: true`, but mock the `.arrayBuffer()` method on the response to throw an Out Of Memory error or a simulated size limit exceeded error. Assert `loadModel` catches this and rejects safely without crashing the Node process.

# Caveats
- Since we are not doing a full browser E2E (like Playwright), we rely on JSDOM/Node `fetch` environment. The `vitest` environment needs to support `fetch` (Node 18+ or `happy-dom`/`jsdom`).
- `console.error` is called internally by `AssetManager` on failure. Tests should probably spy on `console.error` (`vi.spyOn(console, 'error').mockImplementation(() => {})`) to keep test output clean.
- The interface documented in `PROJECT.md` (`loadModel(url: string)`) is slightly out of sync with actual code (`loadModel(name: string, url: string)`). The tests should follow the actual implementation.

# Conclusion
The tests should be implemented in `tests/e2e/tier2/model_loading.test.ts` using `vitest`. The strategy is to instantiate `AssetManager`, use `vi.spyOn(global, 'fetch')` to intercept requests, and assert that `assetManager.loadModel(name, url)` rejects gracefully under the five required boundary/corner conditions: 404, empty URL, network error, invalid format (missing extension), and mocked large file failures.

# Verification Method
- After implementation, the receiving agent can run `npx vitest run tests/e2e/tier2/model_loading.test.ts` to verify all >=5 tests pass.
- Verify `vi.spyOn(global, 'fetch')` is successfully restored between tests (`afterEach(() => vi.restoreAllMocks())`).
