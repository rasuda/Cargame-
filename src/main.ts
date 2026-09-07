import "./style.css";
import { Game } from "./game/Game";

const canvas = document.querySelector<HTMLCanvasElement>("#game-canvas");

if (!canvas) throw new Error("Canvas do jogo não encontrado.");

const game = new Game(canvas);

game.start().catch((error: unknown) => {
  console.error(error);
  const loading = document.querySelector<HTMLDivElement>("#loading");
  if (loading) loading.textContent = "Não foi possível iniciar o jogo.";
});
