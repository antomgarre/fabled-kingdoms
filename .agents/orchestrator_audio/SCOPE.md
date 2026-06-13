# Scope: Audio

## Architecture
Integrate HTML5 AudioContext or THREE.Audio to load and play sound files (`.mp3` or `.wav`).
Read `d:\src\fabled kingdoms\PROJECT.md` for global architecture context.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | AudioEngine | Implement `AudioEngine.ts` to load and decode `.mp3` / `.wav` audio files using `AudioContext`. | none | PLANNED |
| 2 | Game Hookups | Trigger sword swings, footsteps, and enemy impacts using the `AudioEngine`. Console logs should confirm successful load/decode. | 1 | PLANNED |

## Interface Contracts
- `AudioEngine.loadSound(name, url)`
- `AudioEngine.playSound(name)`
