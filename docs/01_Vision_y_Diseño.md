# 01. Visión y Diseño

## Concepto Core
**Fabled Kingdoms** no es un RPG tradicional. Es un experimento arquitectónico para construir mundos infinitos, dinámicos y orgánicos generados en el navegador mediante inteligencia artificial y matemáticas fractales. 

La meta de este prototipo ha sido evitar las estructuras pre-cocinadas (assets rígidos) en favor de un mundo que se "escribe" a sí mismo. 

Se basa en regiones, que son generadas mediante IA. Los objetos, texturas, enemigos, criaturas, misiones, etc. no son generados proceduralemnte, sino en base a un relato de IA. 

## Filosofía AI-First
La inteligencia artificial (Gemini) no se usa aquí como un mero generador de texto (chat), sino como el núcleo de diseño del mundo. Hemos configurado la arquitectura para que:

1. La IA redacte el **Blueprint de la Región**, definiendo geografía, nombres y razas, historias, misiones, etc.
2. La IA genere el **ADN Genético de la Flora**, definiendo qué tipo de árboles crecen, la densidad del follaje y los tonos hexadecimales de la hierba, creando texturas, objetos...
3. El motor de juego (Three.js) interprete los datos (JSON) ciegamente, levantando la geometría según los caprichos del modelo de lenguaje.
4. Los objetos, razas, datos económicos, historias, etc. son generados por la IA, a través de prompts, manteniendo la coherencia y el buen hacer propios de un Game Master de rol.

## Decisiones Iniciales de Stack Técnico
- **TypeScript:** Fuertemente tipado para mantener el orden en sistemas complejos (Object Pooling, instanciación múltiple).
- **Vite:** Empaquetador y HMR ultrarrápido para iteración en tiempo real.
- **Three.js + WebGPU:** Optamos por la API experimental `WebGPURenderer` en lugar del clásico `WebGLRenderer` para tener una base robusta, moderna y capaz de mover miles de instanciaciones con mínimo overhead. Esto requirió descartar librerías antiguas incompatibles (como el antiguo `EffectComposer`).
