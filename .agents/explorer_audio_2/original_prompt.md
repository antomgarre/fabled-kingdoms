## 2026-06-11T14:34:11Z

You are an Explorer. Your working directory is `d:\src\fabled kingdoms\.agents\explorer_audio_2`. 
Read `d:\src\fabled kingdoms\.agents\orchestrator_audio\SCOPE.md` and `d:\src\fabled kingdoms\PROJECT.md`.
Your task is to analyze the codebase for the "Audio" milestone. 
Specifically, `AudioEngine.ts` currently uses procedurally generated noise buffers.
You need to recommend a strategy to:
1. Update `AudioEngine.ts` to use `AudioContext` for loading and decoding `.mp3` and `.wav` files.
2. Implement `loadSound(name, url)` and `playSound(name, position)` according to the interface contracts.
3. Find where in the codebase sword swings, footsteps, and enemy impacts happen and recommend how to hook up `AudioEngine.playSound` to them.
Do NOT implement the changes. Provide a detailed report (handoff.md) in your working directory outlining the strategy and exact files to change. When done, send me a message.
