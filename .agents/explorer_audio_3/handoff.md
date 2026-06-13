# Analysis Report: Audio Milestone

## 1. Observation
- `src/engine/AudioEngine.ts` currently uses procedurally generated noise buffers (e.g., `playFootstep()`, `playSwordSwing()`, `playEnemyHit()`, `playAmbientViento()`).
- Interface contracts required: `loadSound(name: string, url: string): Promise<void>` and `playSound(name: string, position?: THREE.Vector3): void`.
- `Game.ts` initializes the `AudioEngine` upon user interaction (`canvas.addEventListener('click', ...)`).
- **Sword swings** are triggered in `src/player/PlayerController.ts` inside `update()` line 208: `Game.instance.audioEngine.playSwordSwing();`
- **Footsteps** are triggered in `src/player/PlayerController.ts` inside `update()` line 283: `Game.instance.audioEngine?.playFootstep();`
- **Enemy impacts** are triggered in `src/ai/EnemyManager.ts` inside `checkMeleeHit()` line 194: `Game.instance.audioEngine?.playEnemyHit();`

## 2. Logic Chain
1. To satisfy the new interface contracts, `AudioEngine.ts` needs a `Map<string, AudioBuffer>` to cache decoded audio data.
2. `loadSound(name, url)` must fetch the URL as an `ArrayBuffer` and use `this.context.decodeAudioData` to convert it to an `AudioBuffer`, logging success/failure to the console as per requirements, and storing it in the map.
3. `playSound(name, position)` must retrieve the corresponding buffer, create an `AudioBufferSourceNode`, and connect it to `this.context.destination`. For optional spatialization, a `PannerNode` can be created and updated with `position.x`, `position.y`, `position.z` before connecting to destination.
4. Hooking up the events requires modifying `PlayerController.ts` and `EnemyManager.ts` to call `playSound(name, position)` instead of the old specific procedural methods.
5. `loadSound` requires `AudioContext` to be initialized. `Game.ts` currently calls `this.audioEngine.init()` on the first click. To prevent redundant loading, `Game.ts` should ensure that the audio files (`footstep.mp3`, `sword_swing.mp3`, `enemy_hit.mp3`) are only loaded once, ideally right after the initial `audioEngine.init()` resolves.

## 3. Caveats
- Concrete asset URLs (e.g. `'/audio/footstep.mp3'`) are unknown. Placeholder URLs should be used during implementation.
- Basic spatialization (via `PannerNode`) will work with `position`, but for fully accurate 3D audio, the `AudioContext.listener` position should ideally be synced with the player's camera in `AudioEngine.update()`. The strategy here focuses on simple spatialization based on the provided parameter `position`.
- We must handle cases where `playSound` is called before the sounds have finished downloading/decoding.

## 4. Conclusion
**Strategy & Files to change:**
1. **`src/engine/AudioEngine.ts`**:
   - Add `private buffers: Map<string, AudioBuffer> = new Map();`
   - Implement `public async loadSound(name: string, url: string): Promise<void>`.
   - Implement `public playSound(name: string, position?: THREE.Vector3): void`.
   - Keep or remove the legacy procedural methods, but ensure `playSound` checks for `this.buffers.get(name)`.
2. **`src/engine/Game.ts`**:
   - Update the `canvas.addEventListener('click')` callback to conditionally load sounds only once after `this.audioEngine.init()` succeeds.
3. **`src/player/PlayerController.ts`**:
   - Line 208: change to `Game.instance.audioEngine.playSound('sword_swing', this.position);`
   - Line 283: change to `Game.instance.audioEngine?.playSound('footstep', this.position);`
4. **`src/ai/EnemyManager.ts`**:
   - Line 194: change to `Game.instance.audioEngine?.playSound('enemy_hit', enemy.worldPosition);`

## 5. Verification Method
- Execute the project (`npm run dev`).
- Open browser devtools console.
- Click on the canvas to trigger initialization and check the console logs for "successful load/decode".
- Walk around and swing the sword (left click) and verify no errors are thrown and that the audio system attempts to play the loaded sounds.
- Verify the build passes with no TypeScript errors concerning the updated `AudioEngine` contracts.
