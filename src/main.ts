import "./style.css";
import { Game } from "./game/Game";

const canvas = document.querySelector<HTMLCanvasElement>("#game-canvas");

if (!canvas) throw new Error("Canvas do jogo não encontrado.");
const gameCanvas = canvas;

async function startGame(): Promise<void> {
  try {
    const game = new Game(gameCanvas);
    await game.start();
  } catch (error: unknown) {
    console.error(error);
    const loading = document.querySelector<HTMLDivElement>("#loading");
    if (loading) {
      loading.textContent = "Este navegador não conseguiu iniciar os gráficos 3D.";
    }
  }
}

void startGame();
