import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const LORE_DB_PATH = path.join(__dirname, 'lore_database');
const OUTPUT_PATH = path.join(__dirname, 'generated_worlds');

function compileRegion(regionName) {
    console.log(`[World Generator] Compiling Region: ${regionName}...`);
    
    // 1. Read Global Rules
    const globalPath = path.join(LORE_DB_PATH, 'global_gamemaster', 'global_rules.md');
    const globalRules = fs.readFileSync(globalPath, 'utf8');
    
    // 2. Read Region Prompts
    const regionPath = path.join(LORE_DB_PATH, 'regions', regionName, 'region_prompt.md');
    const regionPrompt = fs.readFileSync(regionPath, 'utf8');
    
    console.log(`[AI Simulator] Reading context: ${regionPrompt.length + globalRules.length} bytes.`);
    console.log(`[AI Simulator] Generating JSON based on markdown instructions...`);
    
    // 3. Simulate AI generating a JSON payload
    // In a real scenario, we would send 'globalRules' and 'regionPrompt' to Gemini/OpenAI
    // and parse the JSON response. For now, we simulate the output.
    
    const generatedJSON = {
        region_id: "thornhaven",
        region_name: "Thornhaven",
        biome: "temperate_forest_edge",
        level_range: [1, 5],
        npcs: [
            {
                id: "npc_maren",
                name: "Maren Ashfield",
                role: "NPC_MERCHANT",
                backstory: "Posadera directa que busca mantener su negocio a flote.",
                stats: { health: 300, speed: 1.5, aggressiveness: 0.0 },
                visuals: { base_body: "Superhero_Male_FullBody", outfit: "Female_Peasant" },
                position: { x: 3, y: 1, z: -5 },
                dialogue_opening: "Bienvenido al Ciervo Torcido. ¿Qué necesitas?"
            },
            {
                id: "npc_aldric",
                name: "Aldric Moln",
                role: "NPC_FRIENDLY",
                backstory: "Molinero pensativo preocupado por el nivel del río.",
                stats: { health: 250, speed: 1.8, aggressiveness: 0.0 },
                visuals: { base_body: "Superhero_Male_FullBody", outfit: "Male_Peasant" },
                position: { x: -4, y: 1, z: -2 },
                dialogue_opening: "El río lleva poca agua últimamente..."
            },
            {
                id: "npc_vael",
                name: "Sacerdotisa Vael Dorne",
                role: "NPC_FRIENDLY",
                backstory: "Sylvari que escucha la Corriente de la Tierra.",
                stats: { health: 400, speed: 2.0, aggressiveness: 0.0 },
                visuals: { base_body: "Superhero_Male_FullBody", outfit: "Female_Ranger" },
                position: { x: 0, y: 1, z: -8 },
                dialogue_opening: "La tierra recuerda. ¿Sabes escuchar?"
            },
            {
                id: "npc_bandit_1",
                name: "Bandido Desesperado",
                role: "ENEMY",
                backstory: "Superviviente de Coldmere que roba por necesidad.",
                stats: { health: 100, speed: 4.0, aggressiveness: 0.85 },
                visuals: { base_body: "Superhero_Male_FullBody", outfit: "Male_Ranger" },
                position: { x: 8, y: 1, z: -10 },
                dialogue_opening: "¡Dame todo lo que lleves!"
            }
        ],
        environment_props: [
            {
                id: "prop_stall_1",
                type: "Stall_Empty",
                position: { x: 3, y: 0.5, z: -4 },
                rotation: { y: 1.57 }
            },
            {
                id: "prop_barrel_1",
                type: "Barrel",
                position: { x: 4, y: 0.5, z: -4 },
                rotation: { y: 0 }
            },
            {
                id: "prop_barrel_2",
                type: "Barrel",
                position: { x: 4.2, y: 0.5, z: -3.5 },
                rotation: { y: 0.5 }
            },
            {
                id: "prop_bench_1",
                type: "Bench",
                position: { x: -3, y: 0.5, z: -1 },
                rotation: { y: -0.5 }
            },
            {
                id: "prop_crate_1",
                type: "Crate_Wooden",
                position: { x: 1, y: 0.5, z: -7 },
                rotation: { y: 0.2 }
            },
            {
                id: "tree_pine_1",
                type: "Pine_1",
                position: { x: -8, y: 0, z: -12 },
                rotation: { y: 0.5 }
            },
            {
                id: "tree_pine_2",
                type: "Pine_2",
                position: { x: 5, y: 0, z: -15 },
                rotation: { y: 1.2 }
            },
            {
                id: "tree_common_1",
                type: "CommonTree_1",
                position: { x: 10, y: 0, z: -5 },
                rotation: { y: 2.1 }
            },
            {
                id: "tree_common_2",
                type: "CommonTree_2",
                position: { x: -6, y: 0, z: -2 },
                rotation: { y: 0.8 }
            },
            {
                id: "rock_1",
                type: "Rock_Medium_1",
                position: { x: -3, y: 0, z: -10 },
                rotation: { y: 1.0 }
            },
            {
                id: "rock_2",
                type: "Rock_Medium_2",
                position: { x: 8, y: 0, z: -3 },
                rotation: { y: 2.5 }
            },
            {
                id: "rock_path",
                type: "RockPath_Round_Wide",
                position: { x: 2, y: 0.05, z: -4 },
                rotation: { y: 0.0 }
            }
        ],
        enemies: [
            {
                id: "goblin_1",
                type: "AnimatedEnemy",
                position: { x: -8, y: 0, z: -15 },
                stats: { hp: 50, damage: 10 }
            },
            {
                id: "goblin_2",
                type: "AnimatedEnemy",
                position: { x: 12, y: 0, z: -20 },
                stats: { hp: 50, damage: 10 }
            }
        ],
        terrain: {
            seed: 12345,
            noise_scale: 0.005,
            height_multiplier: 3.0,
            water_level: -1.0
        }
    };
    
    // 4. Persist to disk
    if (!fs.existsSync(OUTPUT_PATH)) {
        fs.mkdirSync(OUTPUT_PATH, { recursive: true });
    }
    
    const outputFile = path.join(OUTPUT_PATH, `${regionName}_compiled.json`);
    fs.writeFileSync(outputFile, JSON.stringify(generatedJSON, null, 4));
    
    console.log(`[Success] Saved persistent world data to ${outputFile}`);
}

// Run the script
compileRegion('dark_forest');
