# Scope: Tier 2 Boundary & Corner Cases

## Architecture
- We are implementing Tier 2 (Boundary & Corner Cases) E2E tests using `vitest`.
- The tests are opaque-box, requirement-driven.
- Test files should be in `tests/e2e/tier2/`.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1_Tier2_ModelLoading | Implement >=5 boundary/corner test cases for 3D Model Loading in `tests/e2e/tier2/model_loading.test.ts`. Focus on: invalid URLs, empty URLs, very large files, network failures, missing extension. | none | PLANNED |
| 2 | M2_Tier2_Animations | Implement >=5 boundary/corner test cases for Skeletal Animations in `tests/e2e/tier2/animations.test.ts`. Focus on: missing animations, invalid state transitions, rapid state changes, empty state. | none | PLANNED |
| 3 | M3_Tier2_Audio | Implement >=5 boundary/corner test cases for Audio Playback in `tests/e2e/tier2/audio.test.ts`. Focus on: concurrent play limits, missing files, volume boundaries, invalid formats. | none | PLANNED |
| 4 | M4_Tier2_GameMaster | Implement >=5 boundary/corner test cases for AI Game Master in `tests/e2e/tier2/game_master.test.ts`. Focus on: extreme random seeds, massive region sizes, empty region, invalid coordinates. | none | PLANNED |
| 5 | M5_Tier2_Persistence | Implement >=5 boundary/corner test cases for Local Persistence in `tests/e2e/tier2/persistence.test.ts`. Focus on: out of disk space, corrupted JSON, missing file, special characters in region ID. | none | PLANNED |

## Interface Contracts
- Tests use `vitest` assertions.
- They invoke public APIs defined in `PROJECT.md` or simulate environment boundaries (e.g. mock fetch to return 404 for model loading).
