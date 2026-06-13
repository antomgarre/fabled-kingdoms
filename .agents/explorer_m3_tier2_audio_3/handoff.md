# Handoff Report: Tier 2 E2E Audio Playback Tests

## 1. Observation
- `SCOPE.md` defines Milestone 3 (M3_Tier2_Audio) requiring >=5 boundary/corner test cases for Audio Playback in `tests/e2e/tier2/audio.test.ts`. Focus areas: concurrent play limits, missing files, volume boundaries, invalid formats.
- Tests must be opaque-box, requirement-driven, using `vitest` (`TEST_INFRA.md`).
- `PROJECT.md` defines the public interface contract for `engine/AudioEngine`:
  - `loadSound(name: string, url: string): Promise<void>`
  - `playSound(name: string, position?: THREE.Vector3): void`
- `src/engine/AudioEngine.ts` currently implements synthetic sound methods (`playFootstep`, etc.) but lacks the generalized `loadSound` and `playSound` methods documented in `PROJECT.md`.

## 2. Logic Chain
1. **Contract-Driven**: Because tests are opaque-box and requirement-driven, they must be written against the `PROJECT.md` interface, even though `src/engine/AudioEngine.ts` is currently missing `loadSound` and `playSound`.
2. **Test Cases**: The required focus areas map directly to these 5 boundary/corner scenarios:
   - *Case 1: Missing Files (Network Error/404)*: Calling `loadSound` with an unreachable URL. Mock `fetch` to return status 404. Expect the promise to reject or log a warning without crashing.
   - *Case 2: Invalid Formats (Decoding Error)*: Calling `loadSound` where `fetch` succeeds but `AudioContext.decodeAudioData` fails (simulating corrupted `.mp3` or `.html` served as audio). Expect a safe rejection.
   - *Case 3: Concurrent Play Limits*: Calling `playSound('hit')` 100 times synchronously. The engine should handle it gracefully (e.g., dropping sounds beyond a sensible limit like 32) without crashing the `AudioContext`.
   - *Case 4: Volume Boundaries (Position Extreemes)*: Calling `playSound` with extreme position vectors (e.g., `new THREE.Vector3(9999999, 9999999, 9999999)`). This tests for math domain boundaries/NaN in distance attenuation logic.
   - *Case 5: Unloaded Sounds*: Calling `playSound('non_existent')` before `loadSound` has cached it. Expect safe fallback (no-op or console warning).
3. **Mocking Strategy**: Since we are in a Node/Vitest environment, real Web Audio API does not exist. We must use `vi.stubGlobal()`:
   - Mock `global.fetch` to return `ArrayBuffer` for success, or reject for missing files.
   - Mock `global.AudioContext` with stubs for `createBufferSource`, `createGain`, `createPanner`, and `decodeAudioData`. Track the number of active `BufferSource.start()` calls for testing concurrent limits.

## 3. Caveats
- `AudioEngine.ts` does not yet implement `loadSound` and `playSound`. The tests will fail with "method not found" until the implementation catches up to `PROJECT.md`.
- "Volume boundaries" is interpreted via the `position` argument (distance attenuation) since `playSound` does not take an explicit volume float in the contract.
- The exact concurrent limit (e.g., 32) isn't specified in constants, so tests should verify that calling play 100 times doesn't throw unhandled exceptions, rather than asserting a strict max limit.

## 4. Conclusion
The implementation of `tests/e2e/tier2/audio.test.ts` should proceed by setting up a global `AudioContext` and `fetch` mock before each test, then sequentially exercising the 5 scenarios against `AudioEngine`'s public interface. The implementer should write these tests asserting on the required opaque-box behaviors.

## 5. Verification Method
- Execute the tests using `npx vitest run tests/e2e/tier2/audio.test.ts` (once implemented).
- Review the test file to ensure it checks: 404 fetch responses, decodeAudioData rejections, 100+ synchronous `playSound` calls, extreme `THREE.Vector3` arguments, and missing cache keys.
- If `AudioEngine` hasn't been implemented yet, verification requires observing expected test failures indicating missing methods.
