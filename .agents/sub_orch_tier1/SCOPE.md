# Scope: Tier 1 E2E Tests

## Architecture
- `tests/e2e/tier1/` directory for Tier 1 opaque-box tests.
- Uses `vitest`.
- 5 features to be tested with >=5 test cases per feature.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Test Infra & Feature 1 | Install vitest, configure package.json `test:e2e`, implement >=5 tests for 3D Model Loading. | none | PLANNED |
| 2 | Feature 2 | Implement >=5 tests for Skeletal Animations. | M1 | PLANNED |
| 3 | Feature 3 | Implement >=5 tests for Audio Playback. | M1 | PLANNED |
| 4 | Feature 4 | Implement >=5 tests for AI Game Master. | M1 | PLANNED |
| 5 | Feature 5 | Implement >=5 tests for Local Persistence. | M1 | PLANNED |

## Interface Contracts
- Tests must be run via `npm run test:e2e`.
- Tests must not rely on internal module details unnecessarily (opaque-box style as much as possible for JS/TS tests, importing public classes).
