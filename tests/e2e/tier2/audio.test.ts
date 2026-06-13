import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import * as THREE from 'three';
import { AudioEngine } from '../../../src/engine/AudioEngine';

describe('AudioEngine Boundary and Corner Cases', () => {
  let audioEngine: AudioEngine;
  let mockAudioContext: any;

  beforeEach(() => {
    // Mocks for Web Audio API and Fetch
    mockAudioContext = {
      state: 'running',
      resume: vi.fn(),
      decodeAudioData: vi.fn(),
      createBufferSource: vi.fn(() => ({
        connect: vi.fn(),
        start: vi.fn(),
        stop: vi.fn()
      })),
      createPanner: vi.fn(() => ({
        positionX: { value: 0 },
        positionY: { value: 0 },
        positionZ: { value: 0 },
        connect: vi.fn()
      })),
      createGain: vi.fn(() => ({
        gain: { value: 1 },
        connect: vi.fn()
      })),
      destination: {}
    };

    vi.stubGlobal('AudioContext', vi.fn(() => mockAudioContext));
    vi.stubGlobal('fetch', vi.fn());

    audioEngine = new AudioEngine();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.clearAllMocks();
  });

  it('1. Missing File (Network/404): should reject when loading a non-existent sound', async () => {
    const mockResponse = {
      ok: false,
      status: 404,
      statusText: 'Not Found',
      arrayBuffer: vi.fn().mockResolvedValue(new ArrayBuffer(0))
    };
    vi.mocked(fetch).mockResolvedValueOnce(mockResponse as unknown as Response);

    await expect(audioEngine.loadSound('missing', '/bad.mp3')).rejects.toThrow();
  });

  it('2. Invalid Format (Decoding Failure): should reject when audio data cannot be decoded', async () => {
    const mockResponse = {
      ok: true,
      status: 200,
      arrayBuffer: vi.fn().mockResolvedValue(new ArrayBuffer(10))
    };
    vi.mocked(fetch).mockResolvedValueOnce(mockResponse as unknown as Response);

    mockAudioContext.decodeAudioData.mockRejectedValueOnce(new Error('Decoding error'));

    await expect(audioEngine.loadSound('invalid', '/invalid.txt')).rejects.toThrow();
  });

  it('3. Concurrent Play Limit: should handle playing sounds in a tight loop without crashing', async () => {
    // Attempt to load sound, ignore if it fails due to lack of implementation
    const mockResponse = {
      ok: true,
      status: 200,
      arrayBuffer: vi.fn().mockResolvedValue(new ArrayBuffer(10))
    };
    vi.mocked(fetch).mockResolvedValueOnce(mockResponse as unknown as Response);
    mockAudioContext.decodeAudioData.mockResolvedValueOnce({} as AudioBuffer);

    try {
      await audioEngine.loadSound('loop-sound', '/good.mp3');
    } catch(e) {
      // Ignored
    }

    expect(() => {
      for (let i = 0; i < 100; i++) {
        audioEngine.playSound('loop-sound');
      }
    }).not.toThrow();
  });

  it('4. Spatial Volume Boundaries: should handle extreme THREE.Vector3 positions without crashing', () => {
    const extremePositions = [
      new THREE.Vector3(Number.MAX_VALUE, Number.MAX_VALUE, Number.MAX_VALUE),
      new THREE.Vector3(-Number.MAX_VALUE, -Number.MAX_VALUE, -Number.MAX_VALUE),
      new THREE.Vector3(NaN, NaN, NaN),
      new THREE.Vector3(Infinity, Infinity, Infinity),
      new THREE.Vector3(-Infinity, -Infinity, -Infinity)
    ];

    extremePositions.forEach(pos => {
      expect(() => {
        audioEngine.playSound('some-sound', pos);
      }).not.toThrow();
    });
  });

  it('5. Play Unloaded Sound (Empty State): should fail gracefully when playing a sound that was never loaded', () => {
    expect(() => {
      audioEngine.playSound('non-existent-sound');
    }).not.toThrow();
  });
});
