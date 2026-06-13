# Handoff Report: Tier 2 Audio Playback Test Cases

## 1. Observation
- **`SCOPE.md`**: Requires >=5 boundary/corner test cases for Audio Playback in `tests/e2e/tier2/audio.test.ts`. Focus areas: concurrent play limits, missing files, volume boundaries, invalid formats. Opaque-box requirement-driven testing.
- **`PROJECT.md`**: Defines the target public interface for `engine/AudioEngine`:
  - `loadSound(name: string, url: string): Promise<void>`
  - `playSound(name: string, position?: THREE.Vector3): void`
- **`src/engine/AudioEngine.ts`**: Currently implements synthesized audio via `AudioContext` (`playFootstep`, `playAmbientViento`, etc.). It does **not** yet implement `loadSound` or `playSound` from the spec, nor does it define any limits for concurrent playback.

## 2. Logic Chain
- Because tests are **opaque-box and requirement-driven**, they must be written against the *intended* API defined in `PROJECT.md`, even though `AudioEngine.ts` has not implemented it yet. 
- To test boundaries without side effects, we must deeply mock `fetch` (for network boundaries) and `AudioContext` (for audio hardware boundaries).
- The missing constants (like maximum concurrent sounds) will need to be implicitly enforced by our tests. We will assume a reasonable boundary (e.g., 32 concurrent sounds) and check that `AudioContext.createBufferSource().start()` is not called more than this limit in a single burst.

## 3. Caveats
- Since `loadSound` and `playSound` are not yet implemented in `AudioEngine.ts`, the test suite will fail initially (`TypeError: engine.loadSound is not a function`). This is the correct "red" phase for requirement-driven testing.
- The exact mock implementation for 3D positional audio might vary depending on whether `AudioEngine` ends up using `PannerNode` or manual gain calculations based on `position`. The tests will assume standard volume capping.

## 4. Conclusion
We recommend the following 5 boundary/corner test cases and mocking strategy:

### Mocking Strategy
- **`global.fetch`**: Stub using `vi.spyOn(global, 'fetch')`. Return `new Response(new ArrayBuffer(8))` for success, `new Response(null, { status: 404 })` for missing files, and a mock throwing an error for network failures.
- **`window.AudioContext`**: Stub globally. 
  - Mock `decodeAudioData` to resolve successfully for valid buffers, or reject for invalid ones.
  - Mock `createBufferSource`, `createGain`, and `createPanner` to return spy objects that track how many times `start()` is called and check `gain.value`.

### Recommended Test Cases
1. **Missing File (404 Boundary)**
   - **Action:** Call `loadSound('theme', 'missing.mp3')`. Mock `fetch` to return `status: 404`.
   - **Expectation:** Promise rejects cleanly without crashing the engine.
2. **Invalid Audio Format (Decoding Boundary)**
   - **Action:** Call `loadSound('theme', 'corrupted.mp3')`. Mock `fetch` to return an invalid `ArrayBuffer`, and `decodeAudioData` to reject.
   - **Expectation:** Promise rejects with a decoding error.
3. **Concurrent Play Limits (Volume/Resource Boundary)**
   - **Action:** Load a valid sound, then loop `playSound('effect')` 100 times sequentially.
   - **Expectation:** `AudioEngine` should enforce a limit (e.g., `MAX_CONCURRENT_SOUNDS = 32`). The mock `createBufferSource().start()` should only be called 32 times.
4. **Volume Boundaries at Extreme Distances (Positional Boundary)**
   - **Action:** Call `playSound('effect', new THREE.Vector3(999999, 999999, 999999))`.
   - **Expectation:** The resulting audio graph (either via `PannerNode` or `GainNode`) caps the volume effectively at 0. No `NaN` or negative volume values are propagated.
5. **Volume Boundaries at Zero Distance (Clipping Boundary)**
   - **Action:** Call `playSound('effect', new THREE.Vector3(0, 0, 0))`.
   - **Expectation:** The gain value is strictly clamped (e.g., `gain <= 1.0`) to prevent audio clipping.

## 5. Verification Method
- Implement the proposed mock setups and 5 `it()` blocks in `tests/e2e/tier2/audio.test.ts`.
- Run `npx vitest tests/e2e/tier2/audio.test.ts`.
- Verify the tests fail exactly because the methods (`loadSound`/`playSound`) and features are absent. This validates the tests accurately define the missing requirements.
