const fs = require('fs');

function scanFile(filepath) {
    console.log(`Scanning ${filepath}...`);
    try {
        const data = fs.readFileSync(filepath);
        const str = data.toString('utf8', 0, Math.min(data.length, 5000000));
        
        const regex = /"name"\s*:\s*"([^"]+)"/g;
        let match;
        const names = new Set();
        while ((match = regex.exec(str)) !== null) {
            const name = match[1];
            if (!name.startsWith('mixamo') && !name.startsWith('Armature') && !name.startsWith('Bone')) {
                names.add(name);
            }
        }
        console.log(Array.from(names).join(', '));
    } catch (e) {
        console.log(`Error reading ${filepath}:`, e.message);
    }
}

scanFile('godot_project/assets/models/UAL1_Standard.glb');
scanFile('godot_project/assets/models/UAL2_Standard.glb');
scanFile('godot_project/assets/models/Superhero_Male_FullBody.gltf');
