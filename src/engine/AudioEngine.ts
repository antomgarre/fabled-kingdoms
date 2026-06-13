import * as THREE from 'three';

export class AudioEngine {
  private context: AudioContext | null = null;
  private buffers: Map<string, AudioBuffer> = new Map();

  public async init() {
    // Only init if not already init
    if (this.context) return;
    
    try {
      this.context = new (window.AudioContext || (window as any).webkitAudioContext)();
      
      // We might need to wait for a user gesture, but modern browsers usually resume
      // automatically when context is created on click. We'll resume it just in case.
      if (this.context.state === 'suspended') {
        await this.context.resume();
      }

      console.log('[AudioEngine] Initialized');
    } catch (e) {
      console.warn('[AudioEngine] Could not initialize audio context', e);
    }
  }

  public async loadSound(name: string, url: string): Promise<void> {
    if (!this.context) return;
    try {
      const response = await fetch(url);
      const arrayBuffer = await response.arrayBuffer();
      const audioBuffer = await this.context.decodeAudioData(arrayBuffer);
      this.buffers.set(name, audioBuffer);
      console.log('[AudioEngine] Successfully loaded and decoded', name);
    } catch (e) {
      console.error('[AudioEngine] Error loading sound:', name, e);
    }
  }

  public playSound(name: string, position?: THREE.Vector3): void {
    if (!this.context) return;
    if (this.context.state === 'suspended') {
      this.context.resume();
    }

    const buffer = this.buffers.get(name);
    if (!buffer) {
      console.warn('[AudioEngine] Sound not loaded:', name);
      return;
    }

    const source = this.context.createBufferSource();
    source.buffer = buffer;

    if (position) {
      const panner = this.context.createPanner();
      panner.panningModel = 'HRTF';
      panner.distanceModel = 'inverse';
      panner.refDistance = 1;
      panner.maxDistance = 10000;
      panner.rolloffFactor = 1;

      // Note: we'd ideally also set the listener position, but for simplicity
      // we assume listener is near (0,0,0) or handled elsewhere.
      panner.positionX.value = position.x;
      panner.positionY.value = position.y;
      panner.positionZ.value = position.z;

      source.connect(panner);
      panner.connect(this.context.destination);
    } else {
      source.connect(this.context.destination);
    }

    source.start(0);
  }
}
