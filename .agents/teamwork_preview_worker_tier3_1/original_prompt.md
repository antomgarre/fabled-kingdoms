## 2026-06-11T14:38:00Z
You are the Worker for the Tier 3 E2E Tests. Read `d:\src\fabled kingdoms\PROJECT.md`, `d:\src\fabled kingdoms\.agents\sub_orch_tier3\SCOPE.md`, and `d:\src\fabled kingdoms\TEST_INFRA.md`. Also read the explorer analysis at `d:\src\fabled kingdoms\.agents\teamwork_preview_explorer_tier3_1\analysis.md`. 
Your task:
1. Install `vitest` and `jsdom` (`npm install -D vitest jsdom`). Update package.json scripts if needed.
2. Create `tests/e2e/tier3/pairwise.test.ts`.
3. Set up the necessary mocks for `AudioContext`, `GLTFLoader`, `fs`, etc., as vitest runs in a Node environment.
4. Implement the 10 pairwise test cases covering F1-F5 combinations using opaque-box assertions on the public interfaces of the modules.
5. Run the tests. They might fail because some implementation is missing, but the tests themselves must be valid and the environment mocks must work.
6. Provide a `handoff.md` with your results.

MANDATORY INTEGRITY WARNING: DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your working directory is `d:\src\fabled kingdoms\.agents\teamwork_preview_worker_tier3_1`. Send a completion message when done.
