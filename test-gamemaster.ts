import { GameMaster, Persistence } from './src/ai/GameMaster.js';

async function main() {
  const gm = new GameMaster();
  const regionId = 'velanthi_reach';
  
  console.log(`Checking if region '${regionId}' exists...`);
  let region = Persistence.loadRegion(regionId);
  
  if (region) {
    console.log(`Loaded region '${regionId}' from disk.`);
  } else {
    console.log(`Region '${regionId}' not found. Generating...`);
    region = await gm.generateRegion();
    console.log(`Generated region '${region.name}'. Saving to disk...`);
    Persistence.saveRegion(region.regionId, region);
  }
  
  console.log('Region Data (Summary):');
  console.log(`Name: ${region.name}`);
  console.log(`Locations: ${region.locations.length}`);
  console.log(`NPCs: ${region.npcs.length}`);
}

main().catch(console.error);
