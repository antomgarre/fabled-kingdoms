# 📋 Region Prompt — Thornhaven
# Instrucciones consolidadas para el compilador de mundos

> Este archivo es el resumen de instrucciones que el `world_generator.js` enviará a la IA
> junto con las reglas globales. Los archivos detallados (geography.md, inhabitants.md,
> quests.md) son la fuente de verdad; este archivo es el prompt concentrado.

---

## Instrucción Principal

Genera el estado inicial de la región "Thornhaven" para el juego Fabled Kingdoms.
Lee el contexto del mundo en `global_rules.md` para respetar el tono, el balance y
las razas disponibles.

Thornhaven es una aldea pequeña y pacífica de finales de otoño, zona de nivel 1-5,
situada al borde del Bosque de Ylen. Es la primera zona que verá el jugador.
Debe sentirse acogedora pero con una inquietud sutil que no se puede nombrar.

## NPCs a Generar (ver inhabitants.md para fichas completas)

Genera los siguientes NPCs con sus stats, posición y visuals:
- `Maren Ashfield` — Posadera humana, amigable, outfit: Male_Ranger, posición central del pueblo
- `Aldric Moln` — Molinero humano, amigable, outfit: Male_Ranger, posición junto al río (este)
- `Vael Dorne` — Sacerdotisa Sylvari, amigable, outfit: Male_Ranger, posición en el templo (norte)
- `Bandido_1` y `Bandido_2` — Humanos hostiles, outfit: Male_Ranger, posición en el camino norte
- `Morric` — Anciano humano, neutral, outfit: Male_Ranger, posición en la plaza central

## Formato de Salida Requerido

```json
{
  "region_id": "thornhaven",
  "region_name": "Thornhaven",
  "biome": "temperate_forest_edge",
  "level_range": [1, 5],
  "npcs": [
    {
      "id": "string",
      "name": "string",
      "role": "string (NPC_FRIENDLY | NPC_MERCHANT | ENEMY | NEUTRAL)",
      "backstory": "string (1-2 frases)",
      "stats": { "health": 0, "speed": 0.0, "aggressiveness": 0.0 },
      "visuals": { "base_body": "Superhero_Male_FullBody", "outfit": "Male_Ranger" },
      "position": { "x": 0, "y": 1, "z": 0 },
      "dialogue_opening": "string"
    }
  ]
}
```
