import { JSDOM } from 'jsdom';

const dom = new JSDOM(`<!DOCTYPE html><html lang="en"><body><div id="app"></div><canvas></canvas></body></html>`, {
  url: 'http://localhost/'
});

global.window = dom.window as any;
global.document = dom.window.document as any;
global.HTMLElement = dom.window.HTMLElement;
global.HTMLCanvasElement = dom.window.HTMLCanvasElement;

// Mock RequestAnimationFrame
global.requestAnimationFrame = (cb) => setTimeout(cb, 16) as any;

// Mock WebGL/WebGPU
HTMLCanvasElement.prototype.getContext = () => ({
  getExtension: () => null,
  getParameter: () => null,
  clearColor: () => {},
  clear: () => {},
  enable: () => {},
  depthFunc: () => {},
  frontFace: () => {},
  cullFace: () => {},
  viewport: () => {},
} as any);

import { Game } from './src/engine/Game.js';

async function run() {
  try {
    const game = Game.instance;
    await game.init();
    console.log("SUCCESS");
  } catch (err) {
    console.error("FATAL ERROR:", err);
  }
}

run();
