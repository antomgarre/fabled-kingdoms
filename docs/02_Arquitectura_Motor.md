# 02. Arquitectura del Motor

El corazón de Fabled Kingdoms se ha programado poniendo el rendimiento (Game Feel y Zero Lag) como máxima prioridad.

## Game Loop (`Game.ts`)
El patrón central es un clásico Bucle de Animación (`requestAnimationFrame` envuelto por WebGPU). Todo el sistema avanza a través de una inyección de `deltaTime` gestionada por `TimeManager.ts` para desvincular la física de la tasa de fotogramas del monitor (independiente de Hz).

## Arquitectura "Zero Lag"
Al tratar con un mundo procedural infinito, la gestión de la memoria RAM y VRAM es crítica.
1. **Object Pooling (Agrupación de Objetos):** `TerrainGenerator` no destruye el terreno (`new / dispose`) cuando el jugador avanza. En su lugar, recicla los trozos de tierra que quedan atrás (`chunkPool`) y los posiciona al frente, alterando únicamente sus alturas (Y) de forma asíncrona.
2. **Time-Slicing (Generación Diferida):** El cálculo masivo (vértices y árboles) se divide en *batches* (lotes). Al sobrepasar la capacidad de un fotograma (16ms), el sistema interrumpe el cálculo (`await new Promise(...)`), cediendo el control al hilo principal. Esto asegura 60 FPS inquebrantables.
3. **InstancedMesh:** Se usa para la vegetación. Un solo "Draw Call" de tarjeta gráfica dibuja miles de troncos y hojas en todo el bosque.

## Input & Sensórica
- **PlayerController:** Uso de inercia y matemáticas predictivas (Lerp y fricción extrema al detenerse).
- **DustSystem:** Partículas esparcidas y sincronizadas matemáticamente con las sinusoides del caminar.
- **AudioEngine:** Síntesis sonora procedural (Web Audio API) en lugar de reproducir archivos MP3 pesados.
