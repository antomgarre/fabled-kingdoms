# Project: Fabled Kingdoms

## Architecture
The application is a medieval fantasy MMO frontend/engine built with `three.js`.
- `engine/`: Core game engine components (AssetManager, AudioEngine, Game loop).
- `player/`: Player logic, movement, animation.
- `ai/`: AI Game Master, persistence logic, NPC/Enemy behavior.
- `world/`: Procedural terrain and environment mapping.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Visuals | Implement AssetManager to load .glb with GLTFLoader. Integrate THREE.AnimationMixer into PlayerController, PlayerModel, EnemyManager, and EnemyModel to support skeletal animation states (Idle, Walk, Attack, Death). | none | IN_PROGRESS |
| 2 | Audio | Implement AudioEngine to use AudioContext for loading and playing real .mp3/.wav files for footsteps, sword swings, and enemy impacts. | none | IN_PROGRESS |
| 3 | AI Game Master | Implement Mock Game Master and local persistence (reading/writing JSON in `/data/`). Create `test-gamemaster.ts` and add `npm run test:ai` script to `package.json`. | none | IN_PROGRESS |

## Interface Contracts
### `engine/AssetManager` ↔ `player/` & `ai/`
- `AssetManager.loadModel(url: string): Promise<THREE.Group>`
- Models loaded should be returned with animations accessible so `AnimationMixer` can consume them.

### `engine/AudioEngine` ↔ `player/` & `ai/`
- `AudioEngine.loadSound(name: string, url: string): Promise<void>`
- `AudioEngine.playSound(name: string, position?: THREE.Vector3): void`

### `ai/GameMaster` ↔ Local Filesystem
- `GameMaster.generateRegion(): Promise<RegionData>`
- `Persistence.saveRegion(regionId: string, data: RegionData): void`
- `Persistence.loadRegion(regionId: string): RegionData | null`

## Code Layout
- Root: `test-gamemaster.ts`, `package.json`
- `src/engine/`: `AssetManager.ts`, `AudioEngine.ts`
- `src/player/`: `PlayerController.ts`, `PlayerModel.ts`
- `src/ai/`: `GameMaster.ts`, `EnemyManager.ts`, `EnemyModel.ts`
- `data/`: Local storage for JSON regions.
