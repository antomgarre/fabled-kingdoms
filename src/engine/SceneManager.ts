import * as THREE from 'three';
import { WebGLRenderer } from 'three';

export class SceneManager {
  public renderer!: WebGLRenderer;
  public scene: THREE.Scene;
  public camera: THREE.PerspectiveCamera;

  constructor() {
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(
      60,                                             // FOV
      window.innerWidth / window.innerHeight,         // Aspect ratio
      0.1,                                            // Near plane
      1000                                            // Far plane
    );
  }

  async init(): Promise<HTMLCanvasElement> {
    this.renderer = new WebGLRenderer({ antialias: true });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); // Limitar para rendimiento
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.0;
    this.renderer.shadowMap.enabled = true;

    document.getElementById('app')!.appendChild(this.renderer.domElement);

    window.addEventListener('resize', this.onResize.bind(this));

    return this.renderer.domElement;
  }

  private onResize(): void {
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(window.innerWidth, window.innerHeight);
  }

  render(): void {
    this.renderer.render(this.scene, this.camera);
  }
}
