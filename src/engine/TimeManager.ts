export class TimeManager {
  public deltaTime: number = 0;
  public elapsedTime: number = 0;
  private lastTime: number = 0;

  /** Llamar al inicio de cada frame */
  update(): void {
    const now = performance.now() / 1000; // en segundos
    this.deltaTime = this.lastTime === 0 ? 0.016 : Math.min(now - this.lastTime, 0.1); // cap a 100ms
    this.lastTime = now;
    this.elapsedTime += this.deltaTime;
  }
}
