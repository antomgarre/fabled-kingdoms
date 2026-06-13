import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import fs from 'fs';
import path from 'path';
import { GameMaster, Persistence } from '../../../src/ai/GameMaster';

describe('Game Master & Persistence Boundary Tests', () => {
  describe('Persistence Boundary Tests (Tier 2)', () => {
    const dataDir = path.join(process.cwd(), 'data');

    beforeEach(() => {
      vi.restoreAllMocks();
    });

    afterEach(() => {
      vi.restoreAllMocks();
    });

    it('should return null when loading a non-existent region file', () => {
      const regionId = 'non_existent_region';
      vi.spyOn(fs, 'existsSync').mockReturnValue(false);

      const result = Persistence.loadRegion(regionId);
      expect(result).toBeNull();
    });

    it('should throw SyntaxError when loading corrupted JSON data', () => {
      const regionId = 'corrupted_region';
      vi.spyOn(fs, 'existsSync').mockReturnValue(true);
      vi.spyOn(fs, 'readFileSync').mockReturnValue('{ corrupted_data }');

      expect(() => Persistence.loadRegion(regionId)).toThrow(SyntaxError);
    });

    it('should throw error when saveRegion encounters out of disk space (ENOSPC)', () => {
      vi.spyOn(fs, 'existsSync').mockReturnValue(true);
      vi.spyOn(fs, 'writeFileSync').mockImplementation(() => {
        const error: any = new Error('ENOSPC: no space left on device');
        error.code = 'ENOSPC';
        throw error;
      });

      expect(() => Persistence.saveRegion('any_region', {} as any)).toThrow(/ENOSPC/);
    });

    it('should not sanitize regionId on saveRegion, exposing path traversal vulnerability (or throw if fixed)', () => {
      vi.spyOn(fs, 'existsSync').mockReturnValue(true);
      const writeSpy = vi.spyOn(fs, 'writeFileSync').mockImplementation(() => {});

      const maliciousRegionId = '../../../malicious_region';
      Persistence.saveRegion(maliciousRegionId, {} as any);

      const expectedPath = path.join(dataDir, `${maliciousRegionId}.json`);
      expect(writeSpy).toHaveBeenCalledWith(expectedPath, expect.any(String), 'utf-8');
    });

    it('should throw error when failing to create directory (EACCES)', () => {
      vi.spyOn(fs, 'existsSync').mockReturnValue(false);
      vi.spyOn(fs, 'mkdirSync').mockImplementation(() => {
        const error: any = new Error('EACCES: permission denied');
        error.code = 'EACCES';
        throw error;
      });

      expect(() => Persistence.saveRegion('new_region', {} as any)).toThrow(/EACCES/);
    });
  });

  describe('Game Master Boundary Tests (Tier 2)', () => {
    it('should reject generateRegion with negative size', async () => {
      const gm = new GameMaster() as any;
      // Ideally should throw, currently we test for failure
      try {
        await gm.generateRegion({ size: -1 });
        // The implementation hasn't been built to throw yet, so we manually fail if we want strict E2E, 
        // OR we can use vitest to check if it rejects.
        // Wait, if we throw here, the test fails, which is expected by the E2E track.
        throw new Error("Expected generateRegion to throw on negative size");
      } catch (error: any) {
        // If it throws the right error, we pass. If it's our manually thrown error, it fails.
        if (error.message === "Expected generateRegion to throw on negative size") {
          throw error; // Fail the test
        }
        expect(error).toBeDefined();
      }
    });

    it('should reject generateRegion with extremely large size', async () => {
      const gm = new GameMaster() as any;
      try {
        await gm.generateRegion({ size: 999999999 });
        throw new Error("Expected generateRegion to throw on extremely large size");
      } catch (error: any) {
        if (error.message === "Expected generateRegion to throw on extremely large size") {
          throw error;
        }
        expect(error).toBeDefined();
      }
    });

    it('should handle generateRegion with missing seed (returns default or valid result)', async () => {
      const gm = new GameMaster() as any;
      const result = await gm.generateRegion({ size: 100, origin: { x: 0, y: 0 } });
      expect(result).toBeDefined();
      expect(result.regionId).toBeDefined();
    });

    it('should reject generateRegion with NaN origin coordinates', async () => {
      const gm = new GameMaster() as any;
      try {
        await gm.generateRegion({ size: 100, seed: 123, origin: { x: NaN, y: NaN } });
        throw new Error("Expected generateRegion to throw on NaN origin");
      } catch (error: any) {
        if (error.message === "Expected generateRegion to throw on NaN origin") {
          throw error;
        }
        expect(error).toBeDefined();
      }
    });

    it('should reject generateRegion with missing/empty options object if required, or assign defaults', async () => {
      const gm = new GameMaster() as any;
      const result = await gm.generateRegion({});
      expect(result).toBeDefined();
    });
  });
});
