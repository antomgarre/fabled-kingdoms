# E2E Test Infra: Fabled Kingdoms

## Test Philosophy
- Opaque-box, requirement-driven. No dependency on implementation design.
- Methodology: Category-Partition + BVA + Pairwise + Workload Testing.

## Feature Inventory
| # | Feature | Source (requirement) | Tier 1 | Tier 2 | Tier 3 |
|---|---------|---------------------|:------:|:------:|:------:|
| 1 | 3D Model Loading | ORIGINAL_REQUEST R1 | 5      | 5      | ✓      |
| 2 | Skeletal Animations | ORIGINAL_REQUEST R1 | 5      | 5      | ✓      |
| 3 | Audio Playback | ORIGINAL_REQUEST R2 | 5      | 5      | ✓      |
| 4 | AI Game Master | ORIGINAL_REQUEST R3 | 5      | 5      | ✓      |
| 5 | Local Persistence | ORIGINAL_REQUEST R3 | 5      | 5      | ✓      |

## Test Architecture
- Test runner: `vitest` (we will use it for E2E testing). Test script: `npm run test:e2e` will run all tests in `tests/e2e/`.
- Test case format: Vitest test files written in TypeScript (`*.test.ts`).
- Directory layout: `tests/e2e/tier1/`, `tests/e2e/tier2/`, `tests/e2e/tier3/`, `tests/e2e/tier4/`.

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Player moves, swings weapon, triggers audio and skeletal animations | F1, F2, F3 | High |
| 2 | Game master generates region, saves to disk, loads from disk | F4, F5 | High |
| 3 | AI spawns creatures, creatures die and play death animation | F1, F2, F3, F4 | High |
| 4 | Player loads saved region and enters it | F1, F5 | Medium |
| 5 | Audio stress test: many footsteps and impacts play simultaneously | F3 | Medium |

## Coverage Thresholds
- Tier 1: ≥5 per feature
- Tier 2: ≥5 per feature (where boundaries exist)
- Tier 3: pairwise coverage of major feature interactions
- Tier 4: ≥5 realistic application scenarios
