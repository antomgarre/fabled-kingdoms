# 03. Generación Procedural

La infinita extensión del mundo se crea de la nada utilizando algoritmos matemáticos deterministas.

## Trozos de Mundo (Chunks)
El espacio continuo está dividido en cuadrículas de 100x100 metros (`CHUNK_WORLD_SIZE`). A medida que el personaje (`PlayerController`) camina, `TerrainGenerator` escanea una matriz de 5x5 alrededor de él. Si detecta un "hueco" (una coordenada donde no hay tierra), desencadena la reconstrucción de un `TerrainChunk` reciclado.

## Matemáticas del Relieve
Usamos la librería `simplex-noise` (más suave y optimizada que el Perlin clásico).
El `TerrainShaper` utiliza **Fractal Brownian Motion (FBM)**, superponiendo múltiples octavas de ruido. 
Las frecuencias bajas dictan las grandes formaciones (cordilleras) y las frecuencias altas, con baja persistencia, añaden los baches y el detalle del suelo a los 10,000 vértices de cada parcela de tierra.

## Pintura Procedural
El motor de renderizado prescinde de texturas fotográficas (UV mapping). En su lugar, usa un mapeo de Altitud a Color (Vertex Colors). Si el vértice Y de un polígono está por debajo de `WATER_LEVEL`, se pinta de color arena; si supera `MAX_HEIGHT * 0.8`, se interpola matemáticamente (Lerp) hacia el blanco (nieve).
