const fs = require('fs');
const path = require('path');

const GODOT_MODELS = path.join(__dirname, 'godot_project', 'assets', 'models');

const toCopy = [
    // Outfits
    {
        dir: 'downloads/Modular Character Outfits - Fantasy[Standard]/Exports/glTF (Godot-Unreal)/Outfits',
        files: ['Female_Peasant.gltf', 'Female_Peasant.bin', 'Male_Peasant.gltf', 'Male_Peasant.bin', 'Female_Ranger.gltf', 'Female_Ranger.bin', 'T_Peasant_BaseColor.png', 'T_Peasant_Normal.png', 'T_Ranger_BaseColor.png', 'T_Ranger_Normal.png']
    },
    // Fantasy Props
    {
        dir: 'downloads/Fantasy Props MegaKit[Standard]/Exports/glTF',
        files: ['Stall_Empty.gltf', 'Stall_Empty.bin', 'Barrel.gltf', 'Barrel.bin', 'Bench.gltf', 'Bench.bin', 'Prop_Crate.gltf', 'Prop_Crate.bin', 'T_Trim_Props_BaseColor.png', 'T_WoodTrim_BaseColor.png', 'T_WoodTrim_Normal.png']
    },
    // Stylized Nature
    {
        dir: 'downloads/Stylized Nature MegaKit[Standard]/glTF',
        files: ['Pine_1.gltf', 'Pine_1.bin', 'Pine_2.gltf', 'Pine_2.bin', 'CommonTree_1.gltf', 'CommonTree_1.bin', 'CommonTree_2.gltf', 'CommonTree_2.bin', 'Bark_NormalTree.png', 'Leaves_NormalTree.png', 'Leaf_Pine.png', 'Bark_DeadTree.png', 'Rock_Medium_1.gltf', 'Rock_Medium_1.bin', 'Rock_Medium_2.gltf', 'Rock_Medium_2.bin', 'RockPath_Round_Wide.gltf', 'RockPath_Round_Wide.bin', 'Rocks_Diffuse.png', 'PathRocks_Diffuse.png']
    },
    // Weapons
    {
        dir: 'downloads/Medieval Weapons Pack by @Quaternius-20260612T103455Z-3-001/Medieval Weapons Pack by @Quaternius/OBJ',
        files: ['Sword.obj', 'Sword.mtl']
    }
];

if (!fs.existsSync(GODOT_MODELS)) {
    fs.mkdirSync(GODOT_MODELS, { recursive: true });
}

let copiedCount = 0;
for (const entry of toCopy) {
    const srcDir = path.join(__dirname, entry.dir);
    for (const file of entry.files) {
        const srcPath = path.join(srcDir, file);
        const destPath = path.join(GODOT_MODELS, file);
        
        if (fs.existsSync(srcPath)) {
            fs.copyFileSync(srcPath, destPath);
            console.log(`Copied: ${file}`);
            copiedCount++;
        } else {
            console.log(`MISSING: ${srcPath}`);
        }
    }
}
console.log(`Finished copying ${copiedCount} files.`);
