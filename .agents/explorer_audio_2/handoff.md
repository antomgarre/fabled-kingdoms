# Audio Milestone Handoff Report

## 1. Observation
- `src/engine/AudioEngine.ts` uses an `AudioContext` to procedurally generate a noise buffer for `playFootstep`, `playAmbientViento`, `playSwordSwing`, and `playEnemyHit`.
- `PROJECT.md` defines the new interface:
  - `AudioEngine.loadSound(name: string, url: string): Promise<void>`
  - `AudioEngine.playSound(name: string, position?: THREE.Vector3): void`
- Audio triggers are already hooked up to the old procedural methods in these locations:
  - `src/player/PlayerController.ts:208` -> `Game.instance.audioEngine.playSwordSwing();`
  - `src/player/PlayerController.ts:283` -> `Game.instance.audioEngine?.playFootstep();`
  - `src/ai/EnemyManager.ts:194` -> `Game.instance.audioEngine?.playEnemyHit();`
- `src/engine/Game.ts` initializes the `audioEngine` inside `canvas.addEventListener('click', ...)` but does not yet load audio assets.

## 2. Logic Chain
1. **AudioEngine Updates:** The `AudioEngine` must drop the old procedural functions (`createNoiseBuffer` and the specific `play*` methods). Instead, it needs a generic asset map (`private buffers: Map<string, AudioBuffer>`). 
   - `loadSound` will instantiate the context (if not already instantiated), `fetch` the `url`, convert the response to `arrayBuffer`, use `context.decodeAudioData()`, and store the result in `buffers`.
   - `playSound` will look up the buffer, create an `AudioBufferSourceNode`, and if a `position` is provided, route it through a `PannerNode` for 3D positional audio before connecting to `context.destination`.
2. **Game Hookup:** The system needs to pre-load actual `.mp3` or `.wav` files. This should happen alongside model loading in `Game.init()` (e.g. `await this.audioEngine.loadSound('footstep', '/sounds/footstep.mp3')`).
3. **Gameplay Triggers:** The specific procedural method calls in `PlayerController.ts` and `EnemyManager.ts` must be replaced with the generic `playSound('name', position)` method to satisfy the new `AudioEngine` contract and provide positional audio.

## 3. Caveats
- `PannerNode` is recommended for `playSound`, but full spatial audio requires updating `AudioContext.listener` continuously (e.g., matching it with the camera position/orientation in the update loop). This report provides the PannerNode for the source, but updating the listener might be required later for accurate 3D panning.
- It is assumed that `.mp3` or `.wav` assets exist in a `/sounds/` folder in the project root. If they don't, they will need to be downloaded or created.
- The procedural ambient wind (`playAmbientViento`) will be removed. If ambient wind is still needed, an ambient track should be loaded and looped.

## 4. Conclusion
To fulfill the "Audio" milestone, implement the following changes:

**1. `src/engine/AudioEngine.ts`**
- Delete `createNoiseBuffer`, `playFootstep`, `playAmbientViento`, `playSwordSwing`, and `playEnemyHit`.
- Add `private buffers: Map<string, AudioBuffer> = new Map();`
- Add `loadSound(name: string, url: string)` using `fetch` and `decodeAudioData`.
- Add `playSound(name: string, position?: THREE.Vector3)` using a `BufferSource` and optionally a `PannerNode`.

**2. `src/engine/Game.ts`**
- In `init()`, call `loadSound` to preload the audio assets:
  ```typescript
  await Promise.all([
    this.audioEngine.loadSound('footstep', '/sounds/footstep.mp3'),
    this.audioEngine.loadSound('sword_swing', '/sounds/sword_swing.mp3'),
    this.audioEngine.loadSound('enemy_hit', '/sounds/enemy_hit.mp3')
  ]);
  ```

**3. `src/player/PlayerController.ts`**
- Line 208: Replace `playSwordSwing()` with `playSound('sword_swing', this.position)`.
- Line 283: Replace `playFootstep()` with `playSound('footstep', this.position)`.

**4. `src/ai/EnemyManager.ts`**
- Line 194: Replace `playEnemyHit()` with `playSound('enemy_hit', enemy.worldPosition)`.

## 5. Verification Method
- Ensure the TypeScript compiler does not complain after changing the `AudioEngine` interface (`npm run build` or `tsc --noEmit`).
- Start the dev server and trigger a footstep, a sword swing, and an enemy hit.
- Console logs should confirm successful load/decode via `AudioEngine`.
- If successful, sounds will play when interacting in the game.
