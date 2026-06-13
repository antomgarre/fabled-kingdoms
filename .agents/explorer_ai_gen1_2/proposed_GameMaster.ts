import fs from 'fs';
import path from 'path';
import type { IRegionBlueprint } from './types.js';
import { MOCK_BLUEPRINT } from './mockBlueprint.js';

export class Persistence {
  static saveRegion(regionId: string, data: IRegionBlueprint): void {
    const dataDir = path.resolve(process.cwd(), 'data');
    if (!fs.existsSync(dataDir)) {
      fs.mkdirSync(dataDir, { recursive: true });
    }
    const filePath = path.join(dataDir, `${regionId}.json`);
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');
  }

  static loadRegion(regionId: string): IRegionBlueprint | null {
    const filePath = path.resolve(process.cwd(), 'data', `${regionId}.json`);
    if (!fs.existsSync(filePath)) {
      return null;
    }
    try {
      const content = fs.readFileSync(filePath, 'utf-8');
      return JSON.parse(content) as IRegionBlueprint;
    } catch (e) {
      console.error(`Error reading region data:`, e);
      return null;
    }
  }
}

export class GameMaster {
  async generateRegion(): Promise<IRegionBlueprint> {
    console.log('[GameMaster] Simulating AI generation...');
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(MOCK_BLUEPRINT);
      }, 1000);
    });
  }
}
