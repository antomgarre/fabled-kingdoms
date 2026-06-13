# Scope: Tier 3 E2E Tests (Cross-Feature)

## Architecture
- Opaque-box testing of pairwise combinations of the 5 features:
  F1: 3D Model Loading
  F2: Skeletal Animations
  F3: Audio Playback
  F4: AI Game Master
  F5: Local Persistence
- Test Runner: `vitest`
- Directory: `tests/e2e/tier3/`

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Pairwise Tests Implementation | Implement test cases covering all pairwise interactions between F1-F5. Generate a minimum of 10 tests (one for each pair) in `tests/e2e/tier3/pairwise.test.ts` or individual files. | none | PLANNED |

## Interface Contracts
### E2E Tests ↔ Product
- Tests must be requirement-driven and opaque-box, utilizing standard E2E testing strategies or exposed public CLI / interfaces (though since this is a frontend app, we use `vitest` for the TS environment, likely testing the public API of the modules like `AssetManager`, `AudioEngine`, `GameMaster` as an integrated unit, ignoring internals).
- The prompt says "opaque-box test cases as defined in TEST_INFRA.md". Test cases must not rely on internal module details, but verify external behavior.

## Code Layout
- `tests/e2e/tier3/pairwise.test.ts`
