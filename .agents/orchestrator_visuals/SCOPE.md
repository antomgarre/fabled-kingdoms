# Scope: Visuals

## Architecture
Integrating GLTFLoader and THREE.AnimationMixer to provide skeletal animations to the project.
Read `d:\src\fabled kingdoms\PROJECT.md` for global architecture context.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | AssetManager | Implement `AssetManager.ts` to dynamically load external `.glb` models using `GLTFLoader` without throwing errors. | none | IN_PROGRESS |
| 2 | Skeletal Animations | Integrate `THREE.AnimationMixer` into `PlayerController.ts`, `PlayerModel.ts`, `EnemyManager.ts`, and `EnemyModel.ts`. Support 'Idle', 'Walk', 'Attack', 'Death' states and transition between at least 2 states. | 1 | IN_PROGRESS |

## Interface Contracts
- `AssetManager` must provide `.glb` loading capabilities. Models returned should include their animation tracks.
