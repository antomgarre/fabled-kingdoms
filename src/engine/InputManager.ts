export class InputManager {
  private keys: Set<string> = new Set();
  private mouseMovement: { x: number; y: number } = { x: 0, y: 0 };
  private _isPointerLocked: boolean = false;
  public scrollDelta: number = 0;

    private _isRightMouseDown: boolean = false;
    private _isLeftMouseDown: boolean = false;
    private _leftClickJustPressed: boolean = false;

    constructor(canvas: HTMLCanvasElement) {
      window.addEventListener('keydown', (e) => {
        this.keys.add(e.code);
      });
      window.addEventListener('keyup', (e) => {
        this.keys.delete(e.code);
      });
      canvas.addEventListener('click', () => {
        canvas.requestPointerLock();
      });
      canvas.addEventListener('contextmenu', (e) => {
        e.preventDefault();
      });
      window.addEventListener('mousedown', (e) => {
        if (e.button === 2) this._isRightMouseDown = true;
        if (e.button === 0) {
          this._isLeftMouseDown = true;
          this._leftClickJustPressed = true;
        }
      });
      window.addEventListener('mouseup', (e) => {
        if (e.button === 2) this._isRightMouseDown = false;
        if (e.button === 0) this._isLeftMouseDown = false;
      });
    document.addEventListener('pointerlockchange', () => {
      this._isPointerLocked = document.pointerLockElement === canvas;
    });
    document.addEventListener('mousemove', (e) => {
      if (this._isPointerLocked) {
        this.mouseMovement.x += e.movementX;
        this.mouseMovement.y += e.movementY;
      }
    });
    canvas.addEventListener('wheel', (e) => {
      this.scrollDelta += e.deltaY;
      e.preventDefault();
    }, { passive: false });
  }

  isKeyDown(code: string): boolean {
    return this.keys.has(code);
  }

  isRightMouseDown(): boolean {
    return this._isRightMouseDown;
  }

  isLeftMouseDown(): boolean {
    return this._isLeftMouseDown;
  }

  consumeLeftClick(): boolean {
    if (this._leftClickJustPressed) {
      this._leftClickJustPressed = false;
      return true;
    }
    return false;
  }

  getMouseDelta(): { x: number; y: number } {
    const delta = { ...this.mouseMovement };
    this.mouseMovement.x = 0;
    this.mouseMovement.y = 0;
    return delta;
  }

  consumeScrollDelta(): number {
    const delta = this.scrollDelta;
    this.scrollDelta = 0;
    return delta;
  }

  get isPointerLocked(): boolean {
    return this._isPointerLocked;
  }
}
