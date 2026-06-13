import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { AssetManager } from '../../../src/engine/AssetManager';

describe('AssetManager Model Loading Boundary & Corner Cases', () => {
  let assetManager: AssetManager;

  beforeEach(() => {
    assetManager = new AssetManager();
    vi.spyOn(console, 'error').mockImplementation(() => {});
    vi.spyOn(console, 'log').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('Test 1: Invalid URLs - rejects when fetch returns 404', async () => {
    vi.spyOn(global, 'fetch').mockResolvedValueOnce({
      ok: false,
      status: 404,
      statusText: 'Not Found',
      text: async () => 'Not Found',
    } as any);

    await expect(assetManager.loadModel('invalid', 'http://example.com/missing.glb')).rejects.toThrow();
  });

  it('Test 2: Empty URLs - rejects when URL is empty', async () => {
    vi.spyOn(global, 'fetch').mockRejectedValueOnce(new Error('Invalid URL'));

    await expect(assetManager.loadModel('empty', '')).rejects.toThrow();
  });

  it('Test 3: Network failures - rejects when fetch throws TypeError', async () => {
    vi.spyOn(global, 'fetch').mockRejectedValueOnce(new TypeError('Failed to fetch'));

    await expect(assetManager.loadModel('networkFail', 'http://example.com/network.glb')).rejects.toThrow('Failed to fetch');
  });

  it('Test 4: Missing extension - rejects when fetch returns plain text body', async () => {
    vi.spyOn(global, 'fetch').mockResolvedValueOnce({
      ok: true,
      status: 200,
      arrayBuffer: async () => new TextEncoder().encode('this is not a gltf file').buffer,
      headers: new Headers({ 'Content-Type': 'text/plain' }),
    } as any);

    await expect(assetManager.loadModel('missingExt', 'http://example.com/model')).rejects.toThrow();
  });

  it('Test 5: Very large files - rejects securely without crashing when arrayBuffer() throws Out of Memory', async () => {
    vi.spyOn(global, 'fetch').mockResolvedValueOnce({
      ok: true,
      status: 200,
      arrayBuffer: async () => {
        throw new Error('Out of Memory');
      },
    } as any);

    await expect(assetManager.loadModel('largeFile', 'http://example.com/huge.glb')).rejects.toThrow('Out of Memory');
  });
});
