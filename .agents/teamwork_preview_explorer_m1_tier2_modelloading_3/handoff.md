# Handoff: Tier 2 Boundary & Corner Cases for 3D Model Loading

## Observation
- `src/engine/AssetManager.ts` implements a `loadModel(name: string, url: string): Promise<GLTF>` function.
- It uses Three.js's `GLTFLoader` internally and stores successfully loaded models in a public `models` dictionary.
- Errors during loading are caught in `GLTFLoader`'s error callback, which then rejects the `loadModel` promise.
- The project requires E2E opaque-box testing using `vitest` for boundary and corner cases (`TEST_INFRA.md`).

## Logic Chain
1. **Opaque-box testing via network boundaries**: Because we are performing opaque-box testing, we should avoid mocking the internal `GLTFLoader`. Instead, we can intercept the network layer that Three.js uses (`fetch` in modern Node/browsers) using `vi.spyOn(global, 'fetch')`.
2. **Invalid URL**: Call `loadModel` with a malformed URL (e.g., `http://[::1]`). Mock `fetch` to reject with `TypeError('Invalid URL')`. Verify the promise rejects and the model is not added to the `models` dictionary.
3. **Empty URL**: Call `loadModel` with `""`. Mock `fetch` to reject. Verify it is handled gracefully and rejected.
4. **Very Large Files**: To simulate an OOM or a file that is too large without crashing the test suite, mock `fetch` to throw a simulated error (e.g., `Error("fetch failed: payload too large")` or `QuotaExceededError`). Verify `AssetManager` properly propagates the rejection.
5. **Network Failures**: Simulate an offline state or DNS failure by having the mocked `fetch` immediately reject with `TypeError('Failed to fetch')`. Verify `AssetManager` rejects the promise.
6. **Missing Extension**: Pass a URL without a `.gltf` or `.glb` extension. Mock `fetch` to return a 200 OK status but with an invalid payload (e.g., HTML text simulating a captive portal or soft 404). Verify that `GLTFLoader` fails to parse the invalid content and `AssetManager` safely rejects the promise instead of hanging.

## Caveats
- `AssetManager` delegates all validation and loading logic to `GLTFLoader`. It does not explicitly validate URLs, file extensions, or file sizes before calling `load`.
- Depending on the `vitest` environment configuration (`jsdom` vs `node`), Three.js might attempt to use `XMLHttpRequest` instead of `fetch`. The proposed strategy assumes `fetch` is the underlying mechanism (which is default in Node 18+ and modern Three.js `FileLoader`). If `jsdom` is used, mocking `fetch` will still be effective, but XHR mocking may be needed if `FileLoader` falls back to it.

## Conclusion
The test strategy for `tests/e2e/tier2/model_loading.test.ts` is to test the `AssetManager` public API while controlling the environment via `vi.spyOn(global, 'fetch')`. By doing this, we can simulate invalid URLs, empty strings, massive payloads, network offline errors, and invalid/missing-extension payloads, asserting that `loadModel` securely rejects the promise in all 5 corner cases without corrupting the internal state.

## Verification Method
1. The Implementer should create the file `tests/e2e/tier2/model_loading.test.ts`.
2. Implement the 5 `it()` blocks corresponding to the cases using the `fetch` mocking strategy.
3. Run the test file via `npx vitest run tests/e2e/tier2/model_loading.test.ts`.
4. Tests should pass, confirming that `AssetManager` correctly catches and rejects all simulated edge cases.
