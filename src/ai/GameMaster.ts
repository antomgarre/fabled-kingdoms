import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import type { IRegionBlueprint } from './types.js';
import { MOCK_BLUEPRINT } from './mockBlueprint.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export type RegionData = IRegionBlueprint;

export class GameMaster {
  public async generateRegion(): Promise<RegionData> {
    return Promise.resolve(MOCK_BLUEPRINT);
  }
}

export class Persistence {
  private static get dataDir() {
    return path.join(__dirname, '../../data');
  }

  public static saveRegion(regionId: string, data: RegionData): void {
    if (!fs.existsSync(this.dataDir)) {
      fs.mkdirSync(this.dataDir, { recursive: true });
    }
    const filePath = path.join(this.dataDir, `${regionId}.json`);
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');
  }

  public static loadRegion(regionId: string): RegionData | null {
    const filePath = path.join(this.dataDir, `${regionId}.json`);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf-8');
      return JSON.parse(content) as RegionData;
    }
    return null;
  }
}
