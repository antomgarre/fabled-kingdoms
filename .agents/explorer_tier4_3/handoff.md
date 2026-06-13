# Tier 4 E2E Test Strategy Handoff

## 1. Observation
- `TEST_INFRA.md` requires >=5 real-world scenarios for Tier 4 tests.
- The specified scenarios are:
  1. Player moves, swings weapon, triggers audio and skeletal animations (F1, F2, F3)
  2. Game master generates region, saves to disk, loads from disk (F4, F5)
  3. AI spawns creatures, creatures die and play death animation (F1, F2, F3, F4)
  4. Player loads saved region and enters it (F1, F5)
  5. Audio stress test: many footsteps and impacts play simultaneously (F3)
- `TEST_INFRA.md` dictates an opaque-box philosophy: "No dependency on implementation design."
- Target directory is `tests/e2e/tier4/`.
- `PROJECT.md` details key Interface Contracts:
  - `AssetManager.loadModel(url)` -> `Promise<THREE.Group>`
  - `AudioEngine.loadSound(name, url)` and `AudioEngine.playSound(name, position?)`
  - `GameMaster.generateRegion()` -> `Promise<RegionData>`
  - `Persistence.saveRegion(regionId, data)` and `Persistence.loadRegion(regionId)` -> `RegionData | null`
- Source files exist for these domains: `src/engine/AudioEngine.ts`, `src/engine/AssetManager.ts`, `src/player/PlayerController.ts`, `src/ai/GameMaster.ts`, `src/ai/EnemyManager.ts`.

## 2. Logic Chain
To satisfy the opaque-box constraint, the test cases must strictly interact with the system via its public interface contracts rather than manipulating internal state.

We can map each scenario to a concrete vitest file:
1. **Scenario 1 -> `tests/e2e/tier4/01-player-combat.test.ts`**
   - **Strategy:** Instantiate `PlayerController` and `PlayerModel`. Simulate player movement and attack actions. Assert that `PlayerModel` animation state transitions to 'Walk' and 'Attack'. Use `vi.spyOn(AudioEngine, 'playSound')` to assert that audio is triggered during the attack.
2. **Scenario 2 -> `tests/e2e/tier4/02-gamemaster-persistence.test.ts`**
   - **Strategy:** Call `GameMaster.generateRegion()`. Pass the resulting `RegionData` to `Persistence.saveRegion()`. Immediately read it back using `Persistence.loadRegion()`. Assert deep equality between the generated data and the loaded data.
3. **Scenario 3 -> `tests/e2e/tier4/03-creature-lifecycle.test.ts`**
   - **Strategy:** Use `EnemyManager` to spawn an enemy, verifying `EnemyModel` initialization. Simulate lethal damage. Assert that the `EnemyModel` animation state transitions to 'Death', and spy on `AudioEngine` to ensure a death/impact sound is played.
4. **Scenario 4 -> `tests/e2e/tier4/04-region-entry.test.ts`**
   - **Strategy:** Manually seed a valid `RegionData` object via `Persistence.saveRegion()`. Call the game initialization logic to load this region. Assert that `AssetManager.loadModel()` was called for the required environment assets, and that the `PlayerController` is initialized at a valid coordinate within the region.
5. **Scenario 5 -> `tests/e2e/tier4/05-audio-stress.test.ts`**
   - **Strategy:** Pre-load a sound via `AudioEngine.loadSound()`. In a loop, trigger `AudioEngine.playSound()` rapidly (e.g., 100+ times). Assert that no exceptions are thrown and that the system correctly queues or plays the sounds under stress.

## 3. Caveats
- The exact method names for `PlayerController` actions (like `move()` or `attack()`) and `EnemyManager` (like `spawn()` or `damage()`) are not explicitly defined in the `PROJECT.md` contracts. The implementer must check the respective `.ts` files to use the correct public methods.
- The `Persistence` object's exact location is unspecified (it may be exported by `GameMaster.ts` or a utility file). The implementer will need to resolve its import path.
- E2E testing with `three.js` in a Node environment (via vitest) might require mocking WebGL or the DOM context. The implementer may need to set up `setupFiles` in vitest or mock `THREE.WebGLRenderer`.

## 4. Conclusion
The implementation strategy is to create 5 distinct test files in `tests/e2e/tier4/`:
1. `01-player-combat.test.ts`
2. `02-gamemaster-persistence.test.ts`
3. `03-creature-lifecycle.test.ts`
4. `04-region-entry.test.ts`
5. `05-audio-stress.test.ts`

Each test will use standard `vitest` functions (`describe`, `it`, `expect`, `vi.spyOn`) to exercise the public interfaces documented in `PROJECT.md`, verifying outputs, spy invocations, and public state changes without hard-coupling to private implementation details.

## 5. Verification Method
- Execute the command: `npm run test:e2e`
- Ensure all 5 `tier4` tests are discovered.
- Verify they pass against the existing implementations of `PlayerController`, `GameMaster`, `AudioEngine`, etc.
- Invalidation condition: If any test relies on reading a private class field (e.g., `player._isAttacking`) rather than public observable effects (e.g., the public AnimationMixer state or sound calls), it violates the opaque-box constraint and must be refactored.
