import './style.css';
import { Game } from './engine/Game';

async function main(): Promise<void> {
  const game = Game.instance;
  await game.init();
}

main().catch(console.error);
