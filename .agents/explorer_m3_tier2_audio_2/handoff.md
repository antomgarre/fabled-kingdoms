# Handoff Report: Tier 2 Audio Boundary & Corner Cases

## 1. Observation
- `SCOPE.md` requires >=5 boundary/corner test cases for Audio Playback in `tests/e2e/tier2/audio.test.ts`, focusing on: concurrent play limits, missing files, volume boundaries, invalid formats.
- `PROJECT.md` defines the interface contract for `AudioEngine`:
  - `loadSound(name: string, url: string): Promise<void>`
  - `playSound(name: string, position?: THREE.Vector3): void`
- `src/engine/AudioEngine.ts` currently implements procedural audio generation (`playFootstep`, etc.) using `AudioContext`, but **does not yet implement** the `loadSound` and `playSound` methods required by the interface contract.
- `TEST_INFRA.md` specifies an opaque-box, requirement-driven methodology using `vitest` for E2E testing.

## 2. Logic Chain
- Because testing is opaque-box and requirement-driven, the tests should be written against the interface contract defined in `PROJECT.md` (`loadSound` and `playSound`), acting as Test-Driven Development (TDD) for the incomplete `AudioEngine`.
- **Missing Files**: Requires mocking `global.fetch` to return a 404 status. `loadSound` should handle the rejection cleanly.
- **Invalid Formats**: Requires mocking `fetch` to return success but `AudioContext.prototype.decodeAudioData` to reject with a decoding error.
- **Concurrent Play Limits**: Involves calling `playSound` repeatedly (e.g., 100 times). The test should verify that the application does not crash, and ideally that an upper bound on active `AudioBufferSourceNode` instances is enforced to prevent audio clipping and performance degradation.
- **Volume Boundaries**: Since `playSound` accepts a `THREE.Vector3` position but no explicit volume parameter, volume boundaries manifest as extreme spatial distances (e.g., `Infinity`, `NaN`, `1e9`) that map to the Web Audio `PannerNode`. The system must handle these without throwing exceptions.
- **Empty State / Missing Sound**: Calling `playSound` on a sound name that was never loaded should fail gracefully (e.g., logging a warning) rather than crashing the engine.

## 3. Caveats
- `AudioEngine.ts` currently lacks the `loadSound` and `playSound` methods. Consequently, the tests will fail upon initial execution. This is expected in a requirement-driven testing approach.
- The actual max concurrent sounds limit is not yet defined in code. The test will need to assert that it either handles unbounded calls gracefully or enforces a logical limit (e.g., 32).
- There is no explicit volume control in the `PROJECT.md` API, so "volume boundaries" are interpreted through spatial positioning limits. If a `setVolume` API is planned, additional tests should be added.

## 4. Conclusion
I recommend implementing the following 5 test cases in `tests/e2e/tier2/audio.test.ts`:

### Mock Strategy
```typescript
// Mocks for Web Audio API and Fetch
const mockAudioContext = {
  state: 'running',
  resume: vi.fn(),
  decodeAudioData: vi.fn(),
  createBufferSource: vi.fn(() => ({ connect: vi.fn(), start: vi.fn(), stop: vi.fn() })),
  createPanner: vi.fn(() => ({ positionX: { value: 0 }, positionY: { value: 0 }, positionZ: { value: 0 }, connect: vi.fn() })),
  createGain: vi.fn(() => ({ gain: { value: 1 }, connect: vi.fn() })),
  destination: {}
};
vi.stubGlobal('AudioContext', vi.fn(() => mockAudioContext));
vi.stubGlobal('fetch', vi.fn());
```

### Recommended Test Cases
1. **Missing File (Network/404)**: Mock `fetch` to return `status: 404`. Assert that `audioEngine.loadSound('hit', '/bad.mp3')` rejects with an appropriate error message and does not crash the engine.
2. **Invalid Format (Decoding Failure)**: Mock `fetch` to return `ok: true` but mock `decodeAudioData` to reject. Assert that `loadSound` catches the decoding error and rejects the promise.
3. **Concurrent Play Limit**: Call `loadSound` successfully, then call `playSound` 100 times in a tight loop. Assert no exceptions are thrown and verify how many times `createBufferSource().start()` was actually invoked (to check if a hard cap is implemented to prevent audio blowing out).
4. **Spatial Volume Boundaries**: Call `playSound` with extreme `THREE.Vector3` inputs (e.g., `new THREE.Vector3(Number.MAX_VALUE, NaN, -Infinity)`). Verify that `PannerNode` does not receive invalid values that cause the AudioContext to crash.
5. **Play Unloaded Sound (Empty State)**: Call `audioEngine.playSound('non-existent')` without loading anything. Assert that the function returns safely without throwing a fatal exception.

### Step-by-Step Implementation Plan
1. Create file `tests/e2e/tier2/audio.test.ts`.
2. Import `AudioEngine`, `vitest`, and `three`.
3. Set up the `beforeEach` block to instantiate a fresh `AudioEngine` and reset all mocks (`fetch` and `AudioContext`).
4. Implement the 5 `it()` blocks mapping to the recommended test cases using the defined mock strategy.
5. Run the tests to confirm they fail appropriately, signaling what needs to be added to `AudioEngine.ts`.

## 5. Verification Method
- Inspect `tests/e2e/tier2/audio.test.ts` to ensure it contains the 5 test cases and the correct mock setup.
- Run `npm run test:e2e tests/e2e/tier2/audio.test.ts` to verify the tests execute (expecting them to fail until `AudioEngine.ts` is implemented).
