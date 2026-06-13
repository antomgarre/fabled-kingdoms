import { describe, it, expect, vi, beforeEach } from 'vitest';
import fs from 'fs';
import path from 'path';
import { Persistence } from '../../../src/ai/GameMaster.js';
import type { IRegionBlueprint } from '../../../src/ai/types.js';

vi.mock('fs');

describe('Persistence Boundary Tests (Tier 2)', () => {
  const dummyData = {
    regionId: 'test_region',
    name: 'Test Region'
  } as unknown as IRegionBlueprint;

  beforeEach(() => {
    vi.resetAllMocks();
  });

  it('1. Missing File Returns Null', () => {
    // Action: Call Persistence.loadRegion('non_existent_region')
    vi.mocked(fs.existsSync).mockReturnValue(false);
    
    const result = Persistence.loadRegion('non_existent_region');
    
    // Assertion: Verify it returns null
    expect(result).toBeNull();
    // Also verify existsSync was called correctly
    const expectedPath = path.join(process.cwd(), 'data', 'non_existent_region.json');
    expect(fs.existsSync).toHaveBeenCalledWith(expectedPath);
  });

  it('2. Corrupted JSON Save File Throws SyntaxError', () => {
    // Action: simulate file exists with corrupted JSON
    vi.mocked(fs.existsSync).mockReturnValue(true);
    vi.mocked(fs.readFileSync).mockReturnValue('{ corrupted_data }');
    
    // Assertion: Verify that it throws a SyntaxError
    expect(() => {
      Persistence.loadRegion('corrupted_region');
    }).toThrow(SyntaxError);
  });

  it('3. Out of Disk Space (ENOSPC) Throws Error', () => {
    // Action: Mock fs.writeFileSync to throw an error with code ENOSPC
    vi.mocked(fs.existsSync).mockReturnValue(true); // Pretend dir exists to avoid mkdirSync
    
    const enospcError = new Error('ENOSPC');
    (enospcError as any).code = 'ENOSPC';
    vi.mocked(fs.writeFileSync).mockImplementation(() => {
      throw enospcError;
    });

    // Assertion: Verify the error is propagated/thrown
    expect(() => {
      Persistence.saveRegion('full_disk_region', dummyData);
    }).toThrow('ENOSPC');
  });

  it('4. Path Traversal Region ID (Special Characters)', () => {
    // Action: Call Persistence.saveRegion('../../../malicious_region', dummyData)
    vi.mocked(fs.existsSync).mockReturnValue(true); // dir exists
    
    Persistence.saveRegion('../../../malicious_region', dummyData);
    
    // Assertion: Check if fs.writeFileSync is called with the traversed path
    const traversedPath = path.join(process.cwd(), 'data', '../../../malicious_region.json');
    
    expect(fs.writeFileSync).toHaveBeenCalledWith(
      traversedPath,
      JSON.stringify(dummyData, null, 2),
      'utf-8'
    );
  });

  it('5. Directory Creation Failure (EACCES)', () => {
    // Action: Mock fs.existsSync to return false for dataDir, and fs.mkdirSync to throw EACCES
    vi.mocked(fs.existsSync).mockReturnValue(false);
    
    const eaccesError = new Error('EACCES');
    (eaccesError as any).code = 'EACCES';
    vi.mocked(fs.mkdirSync).mockImplementation(() => {
      throw eaccesError;
    });

    // Assertion: Verify the error is thrown up the stack
    expect(() => {
      Persistence.saveRegion('no_access_region', dummyData);
    }).toThrow('EACCES');
  });
});
