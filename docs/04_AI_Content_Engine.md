# 04. AI Content Engine

El elemento que hace a Fabled Kingdoms verdaderamente "Next-Gen" es el uso de LLMs para moldear las constantes matemáticas del juego.

## El Modelo Conceptual (Tipado Fuerte)
En la carpeta `src/ai/types.ts` residen las interfaces de TypeScript que fuerzan a la IA a devolver un Blueprint perfecto.
La IA no solo inventa el nombre de la región, sino que define `TerrainType` (ej: 'rolling_hills') e inyecta parámetros como multiplicadores de elevación y persistencia que alteran físicamente la experiencia del `TerrainShaper`.

## Blueprint Interpreter
Actúa como traductor entre el cerebro del LLM y el código estricto de WebGPU. 
Al inicializar la partida, lee el `MOCK_BLUEPRINT` y coordina todos los sistemas:
1. Alimenta al `TerrainGenerator` con la orografía solicitada.
2. Servirá de faro para el `LocationPlacer` (Fase Futura) para insertar pueblos y NPCs físicamente en coordenadas exactas del relieve 3D.
