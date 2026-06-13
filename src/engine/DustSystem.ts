import * as THREE from 'three';

export class DustSystem {
  private mesh: THREE.InstancedMesh;
  private maxParticles = 200;
  private particleData: { active: boolean, life: number, maxLife: number, velY: number }[] = [];
  private dummy = new THREE.Object3D();

  constructor(scene: THREE.Scene) {
    const geo = new THREE.PlaneGeometry(0.6, 0.6);
    // Giramos para que esté plano
    geo.rotateX(-Math.PI / 2);

    const mat = new THREE.MeshLambertMaterial({ 
      color: 0xddccbb, 
      transparent: true, 
      opacity: 0.4, 
      depthWrite: false 
    });
    
    this.mesh = new THREE.InstancedMesh(geo, mat, this.maxParticles);
    
    // Ocultar iniciales
    this.dummy.scale.set(0, 0, 0);
    this.dummy.updateMatrix();
    
    for (let i = 0; i < this.maxParticles; i++) {
      this.mesh.setMatrixAt(i, this.dummy.matrix);
      this.particleData.push({ active: false, life: 0, maxLife: 0, velY: 0 });
    }
    
    scene.add(this.mesh);
  }

  public spawn(x: number, y: number, z: number) {
    // Spawnea 3-4 particulas de polvo
    for (let i = 0; i < 4; i++) {
      const idx = this.particleData.findIndex(p => !p.active);
      if (idx !== -1) {
        const p = this.particleData[idx];
        p.active = true;
        p.life = 0;
        p.maxLife = 0.4 + Math.random() * 0.3;
        p.velY = 0.8 + Math.random() * 1.5;
        
        const offsetX = (Math.random() - 0.5) * 0.8;
        const offsetZ = (Math.random() - 0.5) * 0.8;
        
        this.dummy.position.set(x + offsetX, y + 0.1, z + offsetZ);
        this.dummy.rotation.set(0, Math.random() * Math.PI, 0);
        this.dummy.scale.set(1, 1, 1);
        this.dummy.updateMatrix();
        
        this.mesh.setMatrixAt(idx, this.dummy.matrix);
      }
    }
    this.mesh.instanceMatrix.needsUpdate = true;
  }

  public update(dt: number) {
    let needsUpdate = false;
    for (let i = 0; i < this.maxParticles; i++) {
      const p = this.particleData[i];
      if (p.active) {
        p.life += dt;
        if (p.life >= p.maxLife) {
          p.active = false;
          this.dummy.scale.set(0, 0, 0);
          this.dummy.updateMatrix();
          this.mesh.setMatrixAt(i, this.dummy.matrix);
          needsUpdate = true;
        } else {
          // Animación de subida y encogimiento
          this.mesh.getMatrixAt(i, this.dummy.matrix);
          this.dummy.position.setFromMatrixPosition(this.dummy.matrix);
          this.dummy.position.y += p.velY * dt;
          
          const progress = p.life / p.maxLife;
          const currentScale = 1 - progress; // se hace pequeño y desaparece
          this.dummy.scale.set(currentScale, currentScale, currentScale);
          
          this.dummy.updateMatrix();
          this.mesh.setMatrixAt(i, this.dummy.matrix);
          needsUpdate = true;
        }
      }
    }
    if (needsUpdate) {
      this.mesh.instanceMatrix.needsUpdate = true;
    }
  }
}
