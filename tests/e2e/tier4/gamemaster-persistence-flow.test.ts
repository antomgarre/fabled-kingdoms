import { describe, it, expect, afterAll } from 'vitest';
import { GameMaster, Persistence } from '../../../src/ai/GameMaster';
import fs from 'fs';
import path from 'path';

describe('GameMaster & Persistence Flow (Tier 4 Scenario 2)', () => {
  const testRegionId = 'tier4-e2e-test-region';
  
  afterAll(() => {
    // Clean up side-effects
    const dataDir = path.join(process.cwd(), 'data');
    const filePath = path.join(dataDir, `${testRegionId}.json`);
    if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
    }
  });

  it('Game master generates region, saves to disk, loads from disk', async () => {
    const gameMaster = new GameMaster();
    const region = await gameMaster.generateRegion();
    
    expect(region).toBeDefined();
    
    Persistence.saveRegion(testRegionId, region);
    
    const loadedRegion = Persistence.loadRegion(testRegionId);
    expect(loadedRegion).toEqual(region);
  });
});
