# Audio Milestone Analysis & Strategy

## Observation
- `src/engine/AudioEngine.ts` currently initializes `AudioContext` and uses a procedural `noiseBuffer` to generate sounds in methods `playFootstep()`, `playSwordSwing()`, `playEnemyHit()`, and `playAmbientViento()`.
- Interface contracts require `loadSound(name, url)` and `playSound(name, position)`.
- Sounds are currently triggered in the following locations:
  - `src/player/PlayerController.ts:208` -> `Game.instance.audioEngine.playSwordSwing()`
  - `src/player/PlayerController.ts:283` -> `Game.instance.audioEngine?.playFootstep()`
  - `src/ai/EnemyManager.ts:194` -> `Game.instance.audioEngine?.playEnemyHit()`

## Logic Chain
1. To support loading `.mp3`/`.wav` files, `AudioEngine` must maintain a `Map<string, AudioBuffer>` to cache decoded audio data.
2. `loadSound` needs to fetch the file, read as `ArrayBuffer`, decode via `AudioContext.decodeAudioData`, and store it in the map. This must happen *after* `AudioContext` is created in `init()`.
3. `playSound` must retrieve the buffer by name and use a `BufferSourceNode` to play it. Since it accepts an optional `position: THREE.Vector3`, a `PannerNode` should be introduced to support 3D positional audio.
4. The existing `playFootstep()`, `playSwordSwing()`, and `playEnemyHit()` methods can be safely removed or refactored.
5. The game objects (`PlayerController`, `EnemyManager`) must be updated to call `playSound` with the correct sound names and 3D positions instead of the old specific methods.

## Caveats
- The procedural ambient wind (`playAmbientViento()`) is currently called in `AudioEngine.init()`. Since the milestone only specifies replacing footsteps, swings, and impacts, `playAmbientViento` and `createNoiseBuffer` can optionally be kept as-is.
- The `AudioEngine.init()` is invoked on a click listener in `Game.ts`. The `loadSound` calls should be placed there or immediately inside `AudioEngine.init()` after context creation so sounds are downloaded and decoded appropriately.
- Hardcoded URLs like `/sounds/footstep.wav` will be needed. Make sure the actual `.wav`/`.mp3` files are present in the `public/sounds/` directory.

## Conclusion
**Strategy & Proposed Changes:**

1. **`src/engine/AudioEngine.ts`**
   - Add a property `private buffers: Map<string, AudioBuffer> = new Map();`
   - Implement `loadSound(name: string, url: string): Promise<void>`. Inside, fetch the URL, get `arrayBuffer()`, and use `this.context.decodeAudioData` to store it in `this.buffers`. Log success to console as required by SCOPE.md.
   - Implement `playSound(name: string, position?: THREE.Vector3): void`. Inside, check if `name` exists in `this.buffers`. Create a `BufferSource`, and if `position` is provided, create and configure a `PannerNode` connected to the destination.
   - In `init()`, after `this.context` is initialized, add `await` calls to `loadSound` for `'footstep'`, `'sword_swing'`, and `'enemy_hit'` using appropriate URLs (e.g., `/sounds/footstep.wav`).
   - Remove or deprecate `playFootstep`, `playSwordSwing`, and `playEnemyHit`.

2. **`src/player/PlayerController.ts`**
   - Replace `Game.instance.audioEngine.playSwordSwing();` (Line 208) with `Game.instance.audioEngine.playSound('sword_swing', this.position);`
   - Replace `Game.instance.audioEngine?.playFootstep();` (Line 283) with `Game.instance.audioEngine.playSound('footstep', this.position);`

3. **`src/ai/EnemyManager.ts`**
   - Replace `Game.instance.audioEngine?.playEnemyHit();` (Line 194) with `Game.instance.audioEngine.playSound('enemy_hit', enemy.worldPosition);`

## Verification Method
1. Inspect `AudioEngine.ts` to verify `loadSound` and `playSound` exist and utilize `AudioContext.decodeAudioData` and `PannerNode`.
2. Inspect `PlayerController.ts` and `EnemyManager.ts` to confirm they call `playSound` with position arguments.
3. Start the dev server, click to initialize audio, and check the browser console for logs confirming successful load/decode. Walk, swing sword, and hit an enemy to verify sound is playing correctly.
