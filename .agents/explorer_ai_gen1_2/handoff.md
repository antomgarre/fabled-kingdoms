# Handoff: AI Game Master Implementation Investigation

## Observation
- `PROJECT.md` specifies an interface contract for `ai/GameMaster`:
  - `GameMaster.generateRegion(): Promise<RegionData>`
  - `Persistence.saveRegion(regionId: string, data: RegionData): void`
  - `Persistence.loadRegion(regionId: string): RegionData | null`
- `SCOPE.md` details the need to create a Node.js script to mock an AI Game Master that generates `RegionData` and saves it to `/data/`. A `test-gamemaster.ts` script should be placed in the project root to test reading/writing to disk. A script `"test:ai"` must be added to `package.json`.
- `package.json` configures the project as `"type": "module"`. It lacks a TypeScript runner like `ts-node` or `tsx` to run `.ts` scripts natively via `npm run`.
- `src/ai/types.ts` defines `IRegionBlueprint`, which serves as the concrete `RegionData` structure.
- `src/ai/mockBlueprint.ts` exports a hardcoded `MOCK_BLUEPRINT` of type `IRegionBlueprint`, ideal for simulating the AI generation without external dependencies.
- Directory `src/ai/` does not yet contain a `GameMaster.ts` file.

## Logic Chain
1. To meet the requirements without writing actual AI logic yet, `GameMaster.ts` should implement a mock `GameMaster` class whose `generateRegion` method returns `MOCK_BLUEPRINT` (wrapped in a Promise for API realism).
2. The `Persistence` utility should use synchronous Node.js `fs` functions (`writeFileSync`, `readFileSync`, `existsSync`, `mkdirSync`) to fulfill the synchronous signature specified in `PROJECT.md` (`void` and `RegionData | null`).
3. Since the project uses `"type": "module"`, relative imports within `GameMaster.ts` and `test-gamemaster.ts` must use `.js` extensions (e.g., `import { MOCK_BLUEPRINT } from './mockBlueprint.js';`).
4. To run `test-gamemaster.ts` reliably, we should add `tsx` to `devDependencies` and configure `package.json` with `"test:ai": "tsx test-gamemaster.ts"`.

## Caveats
- `RegionData` in the design documentation conceptually maps to `IRegionBlueprint` defined in `types.ts`.
- The Node.js environment requires `.js` extensions on local imports due to `"type": "module"`.
- We assume `npm i -D tsx` is acceptable to run TypeScript files natively.

## Conclusion
The AI Game Master milestone can be implemented by creating `GameMaster.ts` in `src/ai/` and `test-gamemaster.ts` in the root, utilizing `MOCK_BLUEPRINT`.
I have prepared the exact implementations in:
- `d:\src\fabled kingdoms\.agents\explorer_ai_gen1_2\proposed_GameMaster.ts`
- `d:\src\fabled kingdoms\.agents\explorer_ai_gen1_2\proposed_test-gamemaster.ts`

**Next steps for Implementer:**
1. Copy the contents of `proposed_GameMaster.ts` to `d:\src\fabled kingdoms\src\ai\GameMaster.ts`.
2. Copy the contents of `proposed_test-gamemaster.ts` to `d:\src\fabled kingdoms\test-gamemaster.ts`.
3. Update `d:\src\fabled kingdoms\package.json`:
   - Add `"test:ai": "tsx test-gamemaster.ts"` to `scripts`.
   - Run `npm install -D tsx` to ensure the runner is available.

## Verification Method
1. Run `npm run test:ai`. The output should indicate the region was not found, generated, and saved to `/data/velanthi_reach.json`.
2. Run `npm run test:ai` again. The output should indicate the region was successfully loaded from disk.
3. Inspect `d:\src\fabled kingdoms\data\velanthi_reach.json` to verify valid JSON formatting.
