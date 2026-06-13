import { GameMaster, Persistence } from './src/ai/GameMaster.js';

async function runTest() {
  const gm = new GameMaster();
  const regionId = 'velanthi_reach'; // using the mock's region ID
  
  console.log(`[Test] Checking for existing region '${regionId}' on disk...`);
  let region = Persistence.loadRegion(regionId);
  
  if (region) {
    console.log(`[Test] Success! Region loaded from disk: ${region.name}`);
    console.log(`[Test] Region description excerpt: ${region.description.substring(0, 50)}...`);
  } else {
    console.log(`[Test] Region not found on disk. Asking Game Master to generate...`);
    region = await gm.generateRegion();
    console.log(`[Test] Generated region: ${region.name}`);
    
    Persistence.saveRegion(region.regionId, region);
    console.log(`[Test] Region saved to disk at /data/${region.regionId}.json`);
    console.log(`[Test] Run the script again to test loading from disk.`);
  }
}

runTest().catch(console.error);
