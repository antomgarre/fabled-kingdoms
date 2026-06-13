# BRIEFING

## Mission
Design and implement >=5 opaque-box boundary/corner test cases for AI Game Master in `tests/e2e/tier2/game_master.test.ts`.

## 🔒 My Identity
- Archetype: sub_orch
- Roles: orchestrator, user_liaison, human_reporter, successor
- Working directory: d:\src\fabled kingdoms\.agents\m4_game_master_orchestrator
- Original parent: main agent
- Original parent conversation ID: 71fcb8aa-c0d6-4cf8-b6da-be3854845875

## 🔒 My Workflow
- **Pattern**: Iteration Loop (Explorer → Worker → Reviewer → gate)
- **Scope document**: d:\src\fabled kingdoms\.agents\e2e_tier2_orchestrator\SCOPE.md
1. **Decompose**: N/A, we are at the milestone level.
2. **Dispatch & Execute**:
   - **Direct (iteration loop)**: Explorer → Worker → Reviewer → Auditor → gate
3. **On failure** (in this order):
   - Retry: nudge stuck agent or re-send task
   - Replace: spawn fresh agent with partial progress
   - Skip: proceed without (only if non-critical)
   - Redistribute: split stuck agent's remaining work
   - Redesign: re-partition decomposition
   - Escalate: report to parent (sub-orchestrators only, last resort)
4. **Succession**: at 16 spawns, write handoff.md, spawn successor
- **Work items**:
  1. M4_Tier2_GameMaster [in-progress]
- **Current phase**: 2
- **Current focus**: M4_Tier2_GameMaster

## 🔒 Key Constraints
- Never reuse a subagent after it has delivered its handoff — always spawn fresh.
- Do NOT run build/test commands myself.
- Must verify through tests and review.

## Current Parent
- Conversation ID: 71fcb8aa-c0d6-4cf8-b6da-be3854845875
- Updated: not yet

## Key Decisions Made
- Starting the Iteration Loop for M4_Tier2_GameMaster

## Team Roster
| Agent | Type | Work Item | Status | Conv ID |
|-------|------|-----------|--------|---------|
| Explorer | teamwork_preview_explorer | Design Test Cases | completed | 7a950ae5-59ba-4a21-8453-922f4a9def1c |
| Worker | teamwork_preview_worker | Implement Test Cases | completed | 42c2dec9-f0a7-4a06-bd6d-49e373f714ae |
| Reviewer 1 | teamwork_preview_reviewer | Review Test Cases | in-progress | c380c1c0-a513-4b8c-840b-4280d3028ce1 |
| Reviewer 2 | teamwork_preview_reviewer | Review Test Cases | in-progress | 578d3284-800d-42ad-9879-f027543fec31 |

## Succession Status
- Succession required: no
- Spawn count: 4 / 16
- Pending subagents: c380c1c0-a513-4b8c-840b-4280d3028ce1, 578d3284-800d-42ad-9879-f027543fec31
- Predecessor: none
- Successor: not yet spawned

## Active Timers
- Heartbeat cron: task-30
- Safety timer: task-26

## Artifact Index
- original_prompt.md — User request
- progress.md — Status and checklist
