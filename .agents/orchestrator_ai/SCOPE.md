# Scope: AI Game Master

## Architecture
Node.js script to mock an AI Game Master that generates RegionData and saves it to a local JSON file in `/data/`.
Read `d:\src\fabled kingdoms\PROJECT.md` for global architecture context.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Mock Game Master | Create a mock AI Game Master (`GameMaster.ts`) that generates complex world data (regions, lore, creature stats). | none | PLANNED |
| 2 | Local Persistence | Implement reading and writing to `/data/` as JSON files. | 1 | PLANNED |
| 3 | Test Script | Create `test-gamemaster.ts` that asks Game Master to generate a region, outputs to console, and saves. Loading a second time should read from disk. Add `npm run test:ai` to `package.json`. | 2 | PLANNED |

## Interface Contracts
- Node.js script runnable via `npm run test:ai`.
- Persists to local filesystem `/data/*.json`.
