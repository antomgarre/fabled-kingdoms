const fs = require('fs');
const gltf = JSON.parse(fs.readFileSync('public/models/AnimatedKnight.gltf', 'utf8'));
const names = gltf.animations.map(a => a.name);
console.log(names);
