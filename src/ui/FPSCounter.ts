export class FPSCounter {
  private element: HTMLDivElement;
  private lastUpdate: number = 0;

  constructor(container: HTMLElement) {
    this.element = document.createElement('div');
    this.element.style.position = 'fixed';
    this.element.style.top = '10px';
    this.element.style.right = '10px';
    this.element.style.background = 'rgba(0, 0, 0, 0.6)';
    this.element.style.color = '#fff';
    this.element.style.padding = '8px 12px';
    this.element.style.borderRadius = '6px';
    this.element.style.fontFamily = 'monospace';
    this.element.style.fontSize = '14px';
    this.element.style.pointerEvents = 'none'; // No bloquear clicks
    
    container.appendChild(this.element);
    this.element.innerText = 'FPS: --';
  }

  public update(deltaTime: number, elapsedTime: number): void {
    if (elapsedTime - this.lastUpdate > 0.5) { // Actualizar cada 500ms
      const fps = Math.round(1 / deltaTime);
      this.element.innerText = `FPS: ${fps}`;
      this.lastUpdate = elapsedTime;
    }
  }
}
