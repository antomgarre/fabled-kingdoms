export class DialogUI {
  private container: HTMLDivElement;
  private nameEl: HTMLDivElement;
  private roleEl: HTMLDivElement;
  private textEl: HTMLDivElement;
  
  private isVisible: boolean = false;

  constructor() {
    this.container = document.createElement('div');
    this.container.style.position = 'absolute';
    this.container.style.bottom = '10%';
    this.container.style.left = '50%';
    this.container.style.transform = 'translateX(-50%)';
    this.container.style.width = '60%';
    this.container.style.maxWidth = '800px';
    this.container.style.backgroundColor = 'rgba(20, 20, 30, 0.9)';
    this.container.style.border = '2px solid #8b5a2b';
    this.container.style.borderRadius = '8px';
    this.container.style.padding = '20px';
    this.container.style.color = '#fff';
    this.container.style.fontFamily = 'serif';
    this.container.style.display = 'none';
    this.container.style.boxShadow = '0 10px 30px rgba(0,0,0,0.5)';
    this.container.style.zIndex = '1000';

    const header = document.createElement('div');
    header.style.display = 'flex';
    header.style.justifyContent = 'space-between';
    header.style.borderBottom = '1px solid #444';
    header.style.paddingBottom = '10px';
    header.style.marginBottom = '15px';

    this.nameEl = document.createElement('div');
    this.nameEl.style.fontSize = '24px';
    this.nameEl.style.fontWeight = 'bold';
    this.nameEl.style.color = '#ffcc00';

    this.roleEl = document.createElement('div');
    this.roleEl.style.fontSize = '16px';
    this.roleEl.style.color = '#aaaaaa';
    this.roleEl.style.fontStyle = 'italic';
    this.roleEl.style.marginTop = '6px';

    header.appendChild(this.nameEl);
    header.appendChild(this.roleEl);

    this.textEl = document.createElement('div');
    this.textEl.style.fontSize = '20px';
    this.textEl.style.lineHeight = '1.5';
    this.textEl.style.textShadow = '1px 1px 2px #000';

    const promptText = document.createElement('div');
    promptText.innerText = '[ E ] Continuar';
    promptText.style.marginTop = '15px';
    promptText.style.textAlign = 'right';
    promptText.style.fontSize = '14px';
    promptText.style.color = '#888';

    this.container.appendChild(header);
    this.container.appendChild(this.textEl);
    this.container.appendChild(promptText);

    document.body.appendChild(this.container);
  }

  public show(name: string, role: string, text: string) {
    this.nameEl.innerText = name;
    this.roleEl.innerText = role.toUpperCase();
    this.textEl.innerText = `"${text}"`;
    this.container.style.display = 'block';
    this.isVisible = true;
  }

  public hide() {
    this.container.style.display = 'none';
    this.isVisible = false;
  }

  public get isOpen(): boolean {
    return this.isVisible;
  }
}
