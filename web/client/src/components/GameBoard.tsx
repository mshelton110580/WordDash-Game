/**
 * GameBoard — "Premium Wood" Design v2
 * Canvas-based 7×7 game board with drag-to-connect word formation.
 *
 * DESIGN: Warm Scrabble-style wood tiles with DEFERRED CLEAR system.
 * Tiles animate (squash+pop+flash+particles) BEFORE being removed from the board.
 * Gravity and refill only happen after the animation completes.
 */
import { useRef, useEffect, useCallback, useState } from 'react';
import type { GameState, Tile, CoinFlyEvent, Particle, Shockwave, TileClearAnim } from '@/lib/gameEngine';
import {
  areAdjacent,
  LETTER_VALUES,
  getWordFromPath,
  submitWord,
  updateParticles,
  spawnLayeredParticles,
  spawnShockwave,
  spawnTileClearAnim,
  triggerScreenShake,
  getClearThemeColor,
  isValidWord,
  isWordListLoaded,
  flushPendingClears,
  LinkModeConfig,
} from '@/lib/gameEngine';

interface GameBoardProps {
  gameState: GameState;
  onStateChange: (state: GameState) => void;
  onWordSubmitted: (word: string, score: number, valid: boolean, reason?: string) => void;
}

const TILE_GAP = 4;
const BOARD_PADDING = 12;
const CORNER_RADIUS = 10;

// --- CDN tile asset URLs ---
const TILE_ASSETS: Record<string, string> = {
  normal: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/sMwEnXqAauLWOLXy.png',
  selected: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/pkKhTTWdtPbZrLPF.png',
  bomb: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/zLYkSWfBaTZROrRp.png',
  laser: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/MfReTvSbtccVftXr.png',
  crossLaser: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/wdZSZEIJuSGZKWNk.png',
  mine: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/LmmaSHPYhfDiLjFC.png',
  link: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/LxEjQslaAlnqYqjT.png',
  wildcard: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/GFpBKksaSHjobFRk.png',
  hint: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/BrvxbORXvhGTFatg.png',
  ice1: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/lWmNspyoIymfDLYF.png',
  ice2: 'https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/lWmNspyoIymfDLYF.png',
};

// Image cache
const imageCache: Record<string, HTMLImageElement> = {};
let imagesLoaded = false;
let imagesReady = false;

function preloadImages(onAllLoaded?: () => void) {
  if (imagesLoaded) {
    if (imagesReady && onAllLoaded) onAllLoaded();
    return;
  }
  imagesLoaded = true;
  let loadedCount = 0;
  const totalCount = Object.keys(TILE_ASSETS).length;
  for (const [key, url] of Object.entries(TILE_ASSETS)) {
    const img = new Image();
    let retries = 0;
    img.onload = () => {
      loadedCount++;
      if (loadedCount >= totalCount) {
        imagesReady = true;
        if (onAllLoaded) onAllLoaded();
      }
    };
    img.onerror = () => {
      if (retries < 3) {
        retries++;
        setTimeout(() => { img.src = ''; img.src = url; }, retries * 500);
      } else {
        loadedCount++;
        if (loadedCount >= totalCount) {
          imagesReady = true;
          if (onAllLoaded) onAllLoaded();
        }
      }
    };
    img.src = url;
    imageCache[key] = img;
  }
}

function isImageReady(img: HTMLImageElement | null | undefined): img is HTMLImageElement {
  return !!img && img.complete && img.naturalWidth > 0 && img.naturalHeight > 0;
}

function getImageForTile(tile: Tile, isSelected: boolean): HTMLImageElement | null {
  if (tile.specialType) {
    const key = tile.specialType === 'crossLaser' ? 'crossLaser' : tile.specialType;
    return imageCache[key] || null;
  }
  if (tile.iceState === 'intact') return imageCache['ice1'] || null;
  if (tile.iceState === 'cracked') return imageCache['ice2'] || null;
  if (isSelected) return imageCache['selected'] || null;
  return imageCache['normal'] || null;
}

export default function GameBoard({ gameState, onStateChange, onWordSubmitted }: GameBoardProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const isDragging = useRef(false);
  const animFrameRef = useRef<number>(0);
  const [canvasSize, setCanvasSize] = useState(0);
  const [, forceUpdate] = useState(0);

  const boardSize = gameState.boardSize;
  const tileSize = canvasSize > 0 ? (canvasSize - BOARD_PADDING * 2 - TILE_GAP * (boardSize - 1)) / boardSize : 0;

  useEffect(() => {
    preloadImages(() => forceUpdate(n => n + 1));
  }, []);

  const getTilePos = useCallback((row: number, col: number) => {
    const x = BOARD_PADDING + col * (tileSize + TILE_GAP);
    const y = BOARD_PADDING + row * (tileSize + TILE_GAP);
    return { x, y };
  }, [tileSize]);

  const getTileFromPos = useCallback((cx: number, cy: number): Tile | null => {
    const hitRadius = (tileSize + TILE_GAP) * 0.55;
    let bestTile: Tile | null = null;
    let bestDist = Infinity;
    for (let r = 0; r < boardSize; r++) {
      for (let c = 0; c < boardSize; c++) {
        const tx = BOARD_PADDING + c * (tileSize + TILE_GAP) + tileSize / 2;
        const ty = BOARD_PADDING + r * (tileSize + TILE_GAP) + tileSize / 2;
        const dist = Math.sqrt((cx - tx) ** 2 + (cy - ty) ** 2);
        if (dist < hitRadius && dist < bestDist) {
          bestDist = dist;
          const tile = gameState.board[r]?.[c];
          // Don't allow selecting tiles that are clearing
          if (tile && !tile.isClearing) bestTile = tile;
        }
      }
    }
    return bestTile;
  }, [tileSize, boardSize, gameState.board]);

  // Resize canvas
  useEffect(() => {
    const updateSize = () => {
      if (containerRef.current) {
        const w = containerRef.current.clientWidth;
        const size = Math.min(w, 560);
        setCanvasSize(size);
      }
    };
    updateSize();
    window.addEventListener('resize', updateSize);
    return () => window.removeEventListener('resize', updateSize);
  }, []);

  // ===================== DRAW LOOP =====================
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || canvasSize === 0) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    canvas.width = canvasSize * dpr;
    canvas.height = canvasSize * dpr;
    canvas.style.width = `${canvasSize}px`;
    canvas.style.height = `${canvasSize}px`;
    ctx.scale(dpr, dpr);

    let running = true;

    const draw = () => {
      if (!running) return;
      ctx.clearRect(0, 0, canvasSize, canvasSize);

      const shakeX = gameState.screenShake.offsetX;
      const shakeY = gameState.screenShake.offsetY;

      ctx.save();
      ctx.translate(shakeX, shakeY);

      // Board background — warm wood tray
      const boardGrad = ctx.createLinearGradient(0, 0, 0, canvasSize);
      boardGrad.addColorStop(0, '#5C3D1E');
      boardGrad.addColorStop(0.5, '#4A3018');
      boardGrad.addColorStop(1, '#3D2612');
      ctx.fillStyle = boardGrad;
      roundRect(ctx, 0, 0, canvasSize, canvasSize, 16);
      ctx.fill();

      // Inner shadow
      ctx.strokeStyle = 'rgba(0,0,0,0.3)';
      ctx.lineWidth = 3;
      roundRect(ctx, 1, 1, canvasSize - 2, canvasSize - 2, 16);
      ctx.stroke();
      ctx.strokeStyle = 'rgba(255,220,160,0.15)';
      ctx.lineWidth = 1;
      roundRect(ctx, 3, 3, canvasSize - 6, canvasSize - 6, 14);
      ctx.stroke();

      // --- Draw tiles ---
      // Tiles marked as isClearing are drawn with the clear animation
      for (let r = 0; r < boardSize; r++) {
        for (let c = 0; c < boardSize; c++) {
          const tile = gameState.board[r]?.[c];
          if (!tile) continue;
          if (tile.isClearing) {
            drawClearingTile(ctx, tile, r, c);
          } else {
            drawTile(ctx, tile, r, c);
          }
          if (gameState.chainMode.linkedTiles.has(`${r},${c}`)) {
            const p = getTilePos(r, c);
            ctx.save();
            ctx.strokeStyle = 'rgba(34,211,238,0.95)';
            ctx.lineWidth = 3;
            ctx.shadowColor = '#22d3ee';
            ctx.shadowBlur = 10;
            roundRect(ctx, p.x + 2, p.y + 2, tileSize - 4, tileSize - 4, 8);
            ctx.stroke();
            ctx.restore();
          }
        }
      }

      // Hint path
      if (gameState.hintPath.length > 0) {
        const pulse = 0.75 + 0.25 * Math.sin(Date.now() / 400);
        drawHintPath(ctx, gameState.hintPath, pulse);
      }

      // Selection path
      if (gameState.selectedPath.length > 0) {
        drawPath(ctx, gameState.selectedPath);
      }

      // Word preview
      if (gameState.selectedPath.length >= 2) {
        drawWordPreview(ctx, gameState.selectedPath);
      }

      const now = Date.now();

      // Chain resolution flash and callouts
      if (gameState.chainResolutionFx) {
        const fx = gameState.chainResolutionFx;
        const age = now - fx.timestamp;
        if (age < 900) {
          const t = age / 900;
          const alpha = t < 0.5 ? 1 : 1 - (t - 0.5) / 0.5;
          ctx.save();
          ctx.globalAlpha = Math.max(0, alpha);
          ctx.fillStyle = 'rgba(34,211,238,0.12)';
          ctx.fillRect(0, 0, canvasSize, canvasSize);
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.shadowColor = '#22d3ee';
          ctx.shadowBlur = 22;
          const pop = 1 + Math.sin(Math.min(1, t) * Math.PI) * 0.2;
          ctx.font = `900 ${Math.max(24, 58 * pop)}px 'Space Grotesk', sans-serif`;
          ctx.fillStyle = '#67e8f9';
          ctx.fillText(`${fx.multiplier}X`, canvasSize / 2, canvasSize * 0.42);
          ctx.font = `700 20px 'Space Grotesk', sans-serif`;
          if (age > 180) ctx.fillText('CHAIN!', canvasSize / 2, canvasSize * 0.55);
          if (age > 320) ctx.fillText(`${fx.words} WORDS`, canvasSize / 2, canvasSize * 0.62);
          if (age > 460) ctx.fillText(`+${fx.points}`, canvasSize / 2, canvasSize * 0.69);
          if (age > 560) ctx.fillText(`+${fx.coins} COINS`, canvasSize / 2, canvasSize * 0.76);
          ctx.restore();
        } else {
          gameState.chainResolutionFx = null;
        }
      }

      // Laser effects
      gameState.laserEffects = gameState.laserEffects.filter(effect => {
        const age = now - effect.timestamp;
        if (age > 600) return false;
        const alpha = 1 - age / 600;
        const width = 4 + (1 - alpha) * 8;
        drawLaserEffect(ctx, effect.type, effect.row, effect.col, alpha, width);
        return true;
      });

      // --- Shockwave rings (BOLD) ---
      drawShockwaves(ctx);

      ctx.restore(); // End shake

      // --- Particles ---
      drawParticles(ctx, shakeX, shakeY);

      // Update effects
      updateParticles(gameState);

      // --- DEFERRED CLEAR: flush after animation duration ---
      if (gameState.pendingClear) {
        const elapsed = Date.now() - gameState.pendingClearTimestamp;
        if (elapsed >= gameState.pendingClearDuration) {
          flushPendingClears(gameState);
          onStateChange({ ...gameState });
        }
      }

      // Coin/score fly
      drawCoinFlyEvents(ctx);
      drawScoreFlyEvents(ctx);

      // Falling animations
      for (let r = 0; r < boardSize; r++) {
        for (let c = 0; c < boardSize; c++) {
          const tile = gameState.board[r]?.[c];
          if (tile && tile.isFalling) {
            tile.animProgress = Math.min(1, tile.animProgress + 0.08);
            if (tile.animProgress >= 1) {
              tile.isFalling = false;
            }
          }
        }
      }

      // Word popup timer
      if (gameState.uiMessageTimer > 0) gameState.uiMessageTimer--;
      if (gameState.showWordPopup && gameState.popupTimer > 0) {
        gameState.popupTimer--;
        if (gameState.popupTimer <= 0) {
          gameState.showWordPopup = false;
        }
      }

      animFrameRef.current = requestAnimationFrame(draw);
    };

    draw();
    return () => {
      running = false;
      cancelAnimationFrame(animFrameRef.current);
    };
  }, [canvasSize, gameState, boardSize, getTilePos, onStateChange]);

  // ===================== TILE RENDERING =====================
  function drawTile(ctx: CanvasRenderingContext2D, tile: Tile, row: number, col: number) {
    const pos = getTilePos(row, col);
    let { x, y } = pos;

    // Falling animation
    if (tile.isFalling) {
      const fromY = BOARD_PADDING + tile.fallFromRow * (tileSize + TILE_GAP);
      const toY = y;
      const eased = easeOutBounce(tile.animProgress);
      y = fromY + (toY - fromY) * eased;
    }

    const isSelected = gameState.selectedPath.some(t => t.id === tile.id);
    const isHinted = gameState.hintPath.some(t => t.id === tile.id);

    const img = getImageForTile(tile, isSelected);
    if (isImageReady(img)) {
      ctx.drawImage(img, x, y, tileSize, tileSize);
    } else {
      const fallbackGrad = ctx.createLinearGradient(x, y, x, y + tileSize);
      fallbackGrad.addColorStop(0, '#D4A574');
      fallbackGrad.addColorStop(0.5, '#C49660');
      fallbackGrad.addColorStop(1, '#B8884E');
      ctx.fillStyle = fallbackGrad;
      roundRect(ctx, x, y, tileSize, tileSize, CORNER_RADIUS);
      ctx.fill();
    }

    // Selection glow
    if (isSelected) {
      ctx.save();
      ctx.shadowColor = '#10b981';
      ctx.shadowBlur = 14;
      ctx.strokeStyle = 'rgba(16, 185, 129, 0.8)';
      ctx.lineWidth = 3;
      roundRect(ctx, x, y, tileSize, tileSize, CORNER_RADIUS);
      ctx.stroke();
      ctx.shadowBlur = 0;
      ctx.fillStyle = 'rgba(16, 185, 129, 0.15)';
      roundRect(ctx, x, y, tileSize, tileSize, CORNER_RADIUS);
      ctx.fill();
      ctx.restore();
    } else if (isHinted) {
      ctx.save();
      ctx.shadowColor = '#fbbf24';
      ctx.shadowBlur = 12;
      ctx.strokeStyle = 'rgba(251, 191, 36, 0.7)';
      ctx.lineWidth = 2.5;
      roundRect(ctx, x, y, tileSize, tileSize, CORNER_RADIUS);
      ctx.stroke();
      ctx.shadowBlur = 0;
      ctx.restore();
    }

    // Mine overlay (legacy hasMine — now mines use specialType='mine' with mine.png image)

    // Letter
    drawTileText(ctx, tile, x, y);
  }

  // ===================== CLEARING TILE ANIMATION =====================
  // Draws tiles marked isClearing with time-based squash+pop+flash+fade.
  // ALSO spawns particles/shockwaves at the right moment (once per tile).
  function drawClearingTile(ctx: CanvasRenderingContext2D, tile: Tile, row: number, col: number) {
    const pos = getTilePos(row, col);
    const { x, y } = pos;
    const cx = x + tileSize / 2;
    const cy = y + tileSize / 2;

    // Time-based animation
    const elapsed = Date.now() - gameState.pendingClearTimestamp;
    const anim = gameState.tileClearAnims.find(a => a.row === row && a.col === col);
    const staggerMs = anim ? anim.delay * (1000 / 60) : 0;
    const tileElapsed = elapsed - staggerMs;

    if (tileElapsed < 0) {
      drawTile(ctx, { ...tile, isClearing: false } as Tile, row, col);
      return;
    }

    const SQUASH_DUR = 80;
    const POP_DUR = 120;
    const FADE_DUR = 150;

    // --- SPAWN PARTICLES & SHOCKWAVE at squash→pop transition (once per tile) ---
    const tileKey = `${row},${col}`;
    if (tileElapsed >= SQUASH_DUR && !gameState._particlesSpawnedSet.has(tileKey)) {
      gameState._particlesSpawnedSet.add(tileKey);
      const themeColor = getClearThemeColor(tile.specialType || null);
      const intensity = tile.specialType ? 'big' : 'normal';
      spawnLayeredParticles(gameState, cx, cy, themeColor, intensity);
      // Shockwave for special tiles
      if (tile.specialType) {
        spawnShockwave(gameState, cx, cy, themeColor, 300, 2.0);
      }
      // Small shockwave even for normal tiles (subtle ring)
      if (!tile.specialType) {
        spawnShockwave(gameState, cx, cy, themeColor, 180, 0.8);
      }
    }

    ctx.save();

    if (tileElapsed < SQUASH_DUR) {
      // SQUASH: compress vertically, widen horizontally
      const t = tileElapsed / SQUASH_DUR;
      const scaleX = 1 + t * 0.15;
      const scaleY = 1 - t * 0.25;
      ctx.translate(cx, cy);
      ctx.scale(scaleX, scaleY);
      ctx.translate(-cx, -cy);
      ctx.globalAlpha = 1;

      const img = getImageForTile(tile, false);
      if (isImageReady(img)) {
        ctx.drawImage(img, x, y, tileSize, tileSize);
      } else {
        ctx.fillStyle = '#C49660';
        roundRect(ctx, x, y, tileSize, tileSize, CORNER_RADIUS);
        ctx.fill();
      }
      drawTileText(ctx, tile, x, y);

    } else if (tileElapsed < SQUASH_DUR + POP_DUR) {
      // POP + FLASH: scale up rapidly, bright flash overlay
      const t = (tileElapsed - SQUASH_DUR) / POP_DUR;
      const scale = 1 + t * 0.5;
      const alpha = Math.max(0, 1 - t * 0.8);
      ctx.translate(cx, cy);
      ctx.scale(scale, scale);
      ctx.translate(-cx, -cy);
      ctx.globalAlpha = alpha;

      const img = getImageForTile(tile, false);
      if (isImageReady(img)) {
        ctx.drawImage(img, x, y, tileSize, tileSize);
      } else {
        ctx.fillStyle = '#C49660';
        roundRect(ctx, x, y, tileSize, tileSize, CORNER_RADIUS);
        ctx.fill();
      }

      // WHITE/YELLOW FLASH overlay — the "juicy" flash
      const flashAlpha = (1 - t) * 0.85;
      ctx.globalAlpha = flashAlpha;
      ctx.globalCompositeOperation = 'lighter';
      const flashColor = tile.specialType === 'bomb' ? '#FF8844' :
                         tile.specialType === 'laser' ? '#88CCFF' :
                         tile.specialType === 'crossLaser' ? '#CC88FF' :
                         tile.specialType === 'mine' ? '#FF6666' :
                         '#FFFFCC';
      ctx.fillStyle = flashColor;
      roundRect(ctx, x - 6, y - 6, tileSize + 12, tileSize + 12, CORNER_RADIUS + 4);
      ctx.fill();
      ctx.globalCompositeOperation = 'source-over';

    } else if (tileElapsed < SQUASH_DUR + POP_DUR + FADE_DUR) {
      // FADE: tile image shrinks + fades with a warm glow halo
      const t = (tileElapsed - SQUASH_DUR - POP_DUR) / FADE_DUR;
      const scale = 1.3 - t * 0.6;
      const alpha = Math.max(0, (1 - t) * 0.5);
      ctx.translate(cx, cy);
      ctx.scale(scale, scale);
      ctx.translate(-cx, -cy);
      ctx.globalAlpha = alpha;

      // Draw the tile image fading out (not just a circle)
      const img = getImageForTile(tile, false);
      if (isImageReady(img)) {
        ctx.drawImage(img, x, y, tileSize, tileSize);
      } else {
        ctx.fillStyle = '#C49660';
        roundRect(ctx, x, y, tileSize, tileSize, CORNER_RADIUS);
        ctx.fill();
      }

      // Additive glow halo behind
      ctx.globalCompositeOperation = 'lighter';
      ctx.globalAlpha = alpha * 0.6;
      const color = getClearThemeColor(tile.specialType || null);
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.arc(cx, cy, tileSize * 0.5, 0, Math.PI * 2);
      ctx.fill();
      ctx.globalCompositeOperation = 'source-over';
    }
    // After FADE_DUR: tile is invisible, waiting for flushPendingClears

    ctx.restore();
  }

  // ===================== TILE TEXT (shared) =====================
  function drawTileText(ctx: CanvasRenderingContext2D, tile: Tile, x: number, y: number) {
    const isSpecial = !!tile.specialType;

    if (isSpecial) {
      // --- SPECIAL TILES: Letter in upper-left blank wood area ---
      // The new tile images have a diagonal split with blank wood in the upper-left
      const letterSize = tileSize * 0.32;
      const letterX = x + tileSize * 0.22;
      const letterY = y + tileSize * 0.24;

      ctx.save();
      ctx.font = `700 ${letterSize}px 'Space Grotesk', sans-serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';

      // Dark text on the light wood area (upper-left)
      ctx.fillStyle = 'rgba(0,0,0,0.15)';
      ctx.fillText(tile.letter, letterX + 1, letterY + 1);
      ctx.fillStyle = '#2D1B0E';
      ctx.fillText(tile.letter, letterX, letterY);

      // Point value — small, below the letter in the wood area
      const val = LETTER_VALUES[tile.letter] || 2;
      ctx.font = `600 ${tileSize * 0.14}px 'JetBrains Mono', monospace`;
      ctx.fillStyle = 'rgba(45, 27, 14, 0.55)';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(`${val}`, letterX, letterY + letterSize * 0.45);
      ctx.restore();
    } else {
      // --- NORMAL TILES: Letter centered ---
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.font = `700 ${tileSize * 0.44}px 'Space Grotesk', sans-serif`;

      const letterColor = '#2D1B0E';
      const letterShadow = 'rgba(255,255,255,0.3)';

      ctx.fillStyle = letterShadow;
      ctx.fillText(tile.letter, x + tileSize / 2 + 1, y + tileSize / 2 + 1);
      ctx.fillStyle = letterColor;
      ctx.fillText(tile.letter, x + tileSize / 2, y + tileSize / 2 - 1);

      const val = LETTER_VALUES[tile.letter] || 2;
      ctx.font = `600 ${tileSize * 0.19}px 'JetBrains Mono', monospace`;
      ctx.fillStyle = 'rgba(45, 27, 14, 0.5)';
      ctx.textAlign = 'right';
      ctx.textBaseline = 'bottom';
      ctx.fillText(`${val}`, x + tileSize - 5, y + tileSize - 3);
    }


    // Multiplier badge (both normal and special tiles)
    if (tile.letterMultiplier && tile.letterMultiplier > 1) {
      const badgeText = `${tile.letterMultiplier}x`;
      const badgeBg = tile.letterMultiplier === 3 ? 'rgba(220, 38, 38, 0.9)' : 'rgba(217, 119, 6, 0.9)';
      const badgeColor = tile.letterMultiplier === 3 ? '#dc2626' : '#d97706';
      const badgeW = tileSize * 0.36;
      const badgeH = tileSize * 0.22;
      // For special tiles, put badge in bottom-left; for normal, top-right
      const badgeX = isSpecial ? x + 2 : x + tileSize - badgeW - 2;
      const badgeY = isSpecial ? y + tileSize - badgeH - 2 : y + 2;

      ctx.fillStyle = badgeBg;
      ctx.beginPath();
      ctx.roundRect(badgeX, badgeY, badgeW, badgeH, 4);
      ctx.fill();
      ctx.shadowColor = badgeColor;
      ctx.shadowBlur = 6;
      ctx.beginPath();
      ctx.roundRect(badgeX, badgeY, badgeW, badgeH, 4);
      ctx.fill();
      ctx.shadowBlur = 0;

      ctx.font = `800 ${tileSize * 0.15}px 'Space Grotesk', sans-serif`;
      ctx.fillStyle = '#ffffff';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(badgeText, badgeX + badgeW / 2, badgeY + badgeH / 2);
    }
  }

  // ===================== SHOCKWAVE RINGS (BOLD) =====================
  function drawShockwaves(ctx: CanvasRenderingContext2D) {
    const now = Date.now();
    for (const sw of gameState.shockwaves) {
      const elapsed = now - sw.startTime;
      const t = Math.min(1, elapsed / sw.duration);
      const radius = tileSize * 0.2 + t * tileSize * sw.maxScale;
      const alpha = (1 - t * t) * 0.9; // quadratic fade for longer visibility
      const lineWidth = (6 + 4 * (1 - t)); // starts thick, thins out

      ctx.save();

      // Outer ring (main)
      ctx.globalAlpha = alpha;
      ctx.globalCompositeOperation = 'lighter'; // additive blend!
      ctx.strokeStyle = sw.color;
      ctx.lineWidth = lineWidth;
      ctx.beginPath();
      ctx.arc(sw.x, sw.y, Math.max(0.1, radius), 0, Math.PI * 2);
      ctx.stroke();

      // Inner glow ring (softer, wider)
      ctx.globalAlpha = alpha * 0.4;
      ctx.lineWidth = lineWidth * 2.5;
      ctx.beginPath();
      ctx.arc(sw.x, sw.y, Math.max(0.1, radius * 0.8), 0, Math.PI * 2);
      ctx.stroke();

      // Center flash (brief bright spot)
      if (t < 0.3) {
        const flashAlpha = (1 - t / 0.3) * 0.6;
        ctx.globalAlpha = flashAlpha;
        ctx.fillStyle = '#FFFFFF';
        ctx.beginPath();
        ctx.arc(sw.x, sw.y, Math.max(0.1, tileSize * 0.3 * (1 - t)), 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.globalCompositeOperation = 'source-over';
      ctx.restore();
    }
  }

  // ===================== MULTI-EMITTER PARTICLES =====================
  function drawParticles(ctx: CanvasRenderingContext2D, shakeX: number, shakeY: number) {
    for (const p of gameState.particles) {
      const alpha = Math.max(0, p.life / p.maxLife);
      const px = p.x + shakeX;
      const py = p.y + shakeY;

      ctx.save();

      if (p.blend === 'add') {
        ctx.globalCompositeOperation = 'lighter';
      }
      // Boosted alpha for visibility
      ctx.globalAlpha = alpha * (p.role === 'dust' ? 0.5 : p.role === 'sparkle' ? 0.9 : 0.85);

      if (p.shape === 'rect') {
        // Wood chips: rotated rectangles
        ctx.translate(px, py);
        ctx.rotate(p.rotation);
        ctx.fillStyle = p.color;
        const w = p.size * 2;
        const h = p.size * 0.8;
        ctx.fillRect(-w / 2, -h / 2, w, h);
      } else {
        ctx.fillStyle = p.color;
        ctx.beginPath();
        const radius = p.role === 'dust'
          ? p.size * (1 + (1 - alpha) * 0.8) // dust expands as it fades
          : p.size * (0.5 + alpha * 0.5); // sparkles shrink
        ctx.arc(px, py, Math.max(0.5, radius), 0, Math.PI * 2);
        ctx.fill();

        // Sparkle glow halo
        if (p.role === 'sparkle' && alpha > 0.2) {
          ctx.globalAlpha = alpha * 0.4;
          ctx.beginPath();
          ctx.arc(px, py, Math.max(0.5, radius * 3), 0, Math.PI * 2);
          ctx.fill();
        }
      }

      ctx.restore();
    }
  }

  // ===================== HINT / PATH / PREVIEW =====================
  function drawHintPath(ctx: CanvasRenderingContext2D, path: Tile[], alpha: number) {
    if (path.length < 2) return;
    ctx.strokeStyle = `rgba(251, 191, 36, ${alpha * 0.8})`;
    ctx.lineWidth = 4;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.shadowColor = '#fbbf24';
    ctx.shadowBlur = 12 * alpha;
    ctx.setLineDash([8, 4]);
    ctx.beginPath();
    for (let i = 0; i < path.length; i++) {
      const pos = getTilePos(path[i].row, path[i].col);
      const cx = pos.x + tileSize / 2;
      const cy = pos.y + tileSize / 2;
      if (i === 0) ctx.moveTo(cx, cy);
      else ctx.lineTo(cx, cy);
    }
    ctx.stroke();
    ctx.shadowBlur = 0;
    ctx.setLineDash([]);
  }

  function drawPath(ctx: CanvasRenderingContext2D, path: Tile[]) {
    if (path.length < 2) return;
    ctx.strokeStyle = 'rgba(16, 185, 129, 0.6)';
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.shadowColor = '#10b981';
    ctx.shadowBlur = 8;
    ctx.beginPath();
    for (let i = 0; i < path.length; i++) {
      const pos = getTilePos(path[i].row, path[i].col);
      const cx = pos.x + tileSize / 2;
      const cy = pos.y + tileSize / 2;
      if (i === 0) ctx.moveTo(cx, cy);
      else ctx.lineTo(cx, cy);
    }
    ctx.stroke();
    ctx.shadowBlur = 0;
  }

  function drawWordPreview(ctx: CanvasRenderingContext2D, path: Tile[]) {
    const word = getWordFromPath(path);
    const valid = isWordListLoaded() && isValidWord(word);
    ctx.font = `600 16px 'Space Grotesk', sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'bottom';
    ctx.fillStyle = valid ? '#10b981' : (path.length >= 3 ? '#ef4444' : 'rgba(255,255,255,0.5)');
    ctx.fillText(word, canvasSize / 2, BOARD_PADDING - 2);
  }

  // ===================== COIN FLY EVENTS =====================
  function drawCoinFlyEvents(ctx: CanvasRenderingContext2D) {
    const now = Date.now();
    const duration = LinkModeConfig.flyDurationMs;
    const targetX = canvasSize - 40;
    const targetY = 10;

    gameState.coinFlyEvents = gameState.coinFlyEvents.filter((evt: CoinFlyEvent) => {
      const elapsed = now - evt.timestamp;
      if (elapsed > duration) return false;
      const t = elapsed / duration;
      const eased = 1 - Math.pow(1 - t, 3);
      const startPos = getTilePos(evt.fromRow, evt.fromCol);
      const startX = startPos.x + tileSize / 2;
      const startY = startPos.y + tileSize / 2;
      const midX = (startX + targetX) / 2;
      const midY = Math.min(startY, targetY) - 40;
      const cx = (1 - eased) * (1 - eased) * startX + 2 * (1 - eased) * eased * midX + eased * eased * targetX;
      const cy = (1 - eased) * (1 - eased) * startY + 2 * (1 - eased) * eased * midY + eased * eased * targetY;
      const alpha = Math.max(0, t < 0.8 ? 1 : 1 - (t - 0.8) / 0.2);
      const scale = Math.max(0.01, t < 0.2 ? t / 0.2 : (t < 0.8 ? 1 : 1 - (t - 0.8) / 0.2));

      ctx.save();
      ctx.globalAlpha = alpha;
      const radius = Math.max(0.1, 12 * scale);
      ctx.beginPath();
      ctx.arc(cx, cy, radius, 0, Math.PI * 2);
      ctx.fillStyle = '#f59e0b';
      ctx.fill();
      ctx.strokeStyle = '#fbbf24';
      ctx.lineWidth = 1.5;
      ctx.stroke();
      ctx.font = `700 ${10 * scale}px 'Space Grotesk', sans-serif`;
      ctx.fillStyle = '#ffffff';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('$', cx, cy);
      if (t < 0.5) {
        ctx.font = `700 ${14 * scale}px 'Space Grotesk', sans-serif`;
        ctx.fillStyle = `rgba(251, 191, 36, ${1 - t * 2})`;
        ctx.fillText(`+${evt.amount}`, cx, cy - radius - 8);
      }
      ctx.restore();
      return true;
    });
  }

  // ===================== LASER EFFECTS =====================
  function drawLaserEffect(ctx: CanvasRenderingContext2D, type: string, row: number, col: number, alpha: number, width: number) {
    ctx.globalAlpha = alpha;
    if (type === 'row' || type === 'cross') {
      const pos = getTilePos(row, 0);
      const y = pos.y + tileSize / 2;
      const grad = ctx.createLinearGradient(0, y - width, 0, y + width);
      grad.addColorStop(0, 'rgba(77, 166, 255, 0)');
      grad.addColorStop(0.5, `rgba(77, 166, 255, ${alpha})`);
      grad.addColorStop(1, 'rgba(77, 166, 255, 0)');
      ctx.fillStyle = grad;
      ctx.fillRect(0, y - width, canvasSize, width * 2);
    }
    if (type === 'col' || type === 'cross') {
      const pos = getTilePos(0, col);
      const x = pos.x + tileSize / 2;
      const grad = ctx.createLinearGradient(x - width, 0, x + width, 0);
      grad.addColorStop(0, 'rgba(178, 102, 255, 0)');
      grad.addColorStop(0.5, `rgba(178, 102, 255, ${alpha})`);
      grad.addColorStop(1, 'rgba(178, 102, 255, 0)');
      ctx.fillStyle = grad;
      ctx.fillRect(x - width, 0, width * 2, canvasSize);
    }
    ctx.globalAlpha = 1;
  }


  function drawScoreFlyEvents(ctx: CanvasRenderingContext2D) {
    const now = Date.now();
    const duration = LinkModeConfig.flyDurationMs;
    const targetX = 28;
    const targetY = 8;

    gameState.scoreFlyEvents = gameState.scoreFlyEvents.filter((evt: CoinFlyEvent) => {
      const elapsed = now - evt.timestamp;
      if (elapsed > duration) return false;
      const t = elapsed / duration;
      const eased = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
      const startPos = getTilePos(evt.fromRow, evt.fromCol);
      const startX = startPos.x + tileSize / 2;
      const startY = startPos.y + tileSize / 2;
      const chunkCount = Math.min(LinkModeConfig.maxFlyFragments, Math.max(10, Math.floor(evt.amount / 180)));
      for (let i = 0; i < chunkCount; i++) {
        const jitter = (i / chunkCount - 0.5) * 36;
        const cx = startX + (targetX - startX) * eased + jitter * (1 - eased);
        const cy = startY + (targetY - startY) * eased + Math.sin(i * 1.8 + t * 6) * 3;
        ctx.globalAlpha = Math.max(0.12, 1 - t);
        ctx.fillStyle = '#34d399';
        ctx.beginPath();
        ctx.arc(cx, cy, 2.2, 0, Math.PI * 2);
        ctx.fill();
      }
      return true;
    });
    ctx.globalAlpha = 1;
  }

  // ===================== INPUT HANDLING =====================
  const getCanvasCoords = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    const canvas = canvasRef.current;
    if (!canvas) return { x: 0, y: 0 };
    const rect = canvas.getBoundingClientRect();
    let clientX: number, clientY: number;
    if ('touches' in e) {
      clientX = e.touches[0]?.clientX ?? e.changedTouches[0]?.clientX ?? 0;
      clientY = e.touches[0]?.clientY ?? e.changedTouches[0]?.clientY ?? 0;
    } else {
      clientX = e.clientX;
      clientY = e.clientY;
    }
    return { x: clientX - rect.left, y: clientY - rect.top };
  }, []);

  const handlePointerDown = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    if (gameState.isGameOver || gameState.pendingClear) return; // Block input during clear animation
    e.preventDefault();
    const { x, y } = getCanvasCoords(e);
    const tile = getTileFromPos(x, y);
    if (!tile) return;

    if (gameState.activePowerUp) {
      gameState.activePowerUp = null;
      onStateChange({ ...gameState });
    }

    isDragging.current = true;
    gameState.selectedPath = [tile];
    onStateChange({ ...gameState });
  }, [gameState, getCanvasCoords, getTileFromPos, onStateChange]);

  const lastPointerPos = useRef<{ x: number; y: number } | null>(null);

  const handlePointerMove = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    if (!isDragging.current || gameState.isGameOver || gameState.pendingClear) return;
    e.preventDefault();
    const { x, y } = getCanvasCoords(e);

    const path = gameState.selectedPath;
    if (path.length === 0) return;

    const lastTile = path[path.length - 1];
    const cellStep = tileSize + TILE_GAP;
    const lastCx = BOARD_PADDING + lastTile.col * cellStep + tileSize / 2;
    const lastCy = BOARD_PADDING + lastTile.row * cellStep + tileSize / 2;

    // Backtracking
    if (path.length >= 2) {
      const prevTile = path[path.length - 2];
      const prevCx = BOARD_PADDING + prevTile.col * cellStep + tileSize / 2;
      const prevCy = BOARD_PADDING + prevTile.row * cellStep + tileSize / 2;
      const distToPrev = Math.sqrt((x - prevCx) ** 2 + (y - prevCy) ** 2);
      if (distToPrev < tileSize * 0.45) {
        path.pop();
        onStateChange({ ...gameState });
        lastPointerPos.current = { x, y };
        return;
      }
    }

    const orthogonalHitRadius = tileSize * 0.48;
    const diagonalHitRadius = tileSize * 0.32;
    let bestCandidate: Tile | null = null;
    let bestDist = Infinity;

    for (let dr = -1; dr <= 1; dr++) {
      for (let dc = -1; dc <= 1; dc++) {
        if (dr === 0 && dc === 0) continue;
        const nr = lastTile.row + dr;
        const nc = lastTile.col + dc;
        if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize) continue;
        const candidate = gameState.board[nr]?.[nc];
        if (!candidate || candidate.isClearing) continue; // Don't select clearing tiles
        if (path.some(t => t.id === candidate.id)) continue;

        const isDiagonal = dr !== 0 && dc !== 0;
        const hitRadius = isDiagonal ? diagonalHitRadius : orthogonalHitRadius;
        const candCx = BOARD_PADDING + nc * cellStep + tileSize / 2;
        const candCy = BOARD_PADDING + nr * cellStep + tileSize / 2;
        const dist = Math.sqrt((x - candCx) ** 2 + (y - candCy) ** 2);

        if (dist < hitRadius && dist < bestDist) {
          if (isDiagonal) {
            const dx = x - lastCx;
            const dy = y - lastCy;
            const dragLen = Math.sqrt(dx * dx + dy * dy);
            if (dragLen > 0) {
              const ndx = dx / dragLen;
              const ndy = dy / dragLen;
              const dLen = Math.SQRT2;
              const diagX = dc / dLen;
              const diagY = dr / dLen;
              const dot = ndx * diagX + ndy * diagY;
              if (dot < 0.75) continue;
            }
          }
          bestDist = dist;
          bestCandidate = candidate;
        }
      }
    }

    if (bestCandidate) {
      path.push(bestCandidate);
      onStateChange({ ...gameState });
    }
    lastPointerPos.current = { x, y };
  }, [gameState, getCanvasCoords, boardSize, tileSize, onStateChange]);

  const handlePointerUp = useCallback((_e: React.MouseEvent | React.TouchEvent) => {
    if (!isDragging.current) return;
    isDragging.current = false;

    if (gameState.selectedPath.length >= 3) {
      const pathCopy = [...gameState.selectedPath];
      const result = submitWord(gameState);

      if (result.valid) {
        // --- PREMIUM EFFECTS (no setTimeout — particles spawn in draw loop) ---
        const hasBomb = pathCopy.some(t => t.specialType === 'bomb');
        const hasLaser = pathCopy.some(t => t.specialType === 'laser' || t.specialType === 'crossLaser');

        // Clear the particle spawn tracker for this new clear
        gameState._particlesSpawnedSet.clear();

        // Spawn tile clear anims (stagger timing for the draw loop)
        for (let i = 0; i < pathCopy.length; i++) {
          const tile = pathCopy[i];
          spawnTileClearAnim(gameState, tile.row, tile.col, tile.letter, tile.specialType || null, i);
        }

        // Explosion-cleared tiles (bomb radius, laser lines, etc.)
        if (gameState.explosionClears.length > 0) {
          const pathIds = new Set(pathCopy.map(t => `${t.row},${t.col}`));
          let explIdx = pathCopy.length;
          for (const ec of gameState.explosionClears) {
            const key = `${ec.row},${ec.col}`;
            if (pathIds.has(key)) continue;
            spawnTileClearAnim(gameState, ec.row, ec.col, '', ec.specialType, explIdx);
            explIdx++;
          }
        }

        // Screen shake (synchronous, works fine here)
        if (hasBomb) {
          triggerScreenShake(gameState, 8, 12);
        } else if (hasLaser) {
          triggerScreenShake(gameState, 5, 10);
        } else if (pathCopy.length >= 5) {
          triggerScreenShake(gameState, 3, 8);
        }
      }

      onWordSubmitted(result.word, result.score, result.valid, result.reason);
    } else {
      gameState.selectedPath = [];
    }
    onStateChange({ ...gameState });
  }, [gameState, getTilePos, tileSize, onStateChange, onWordSubmitted]);

  return (
    <div ref={containerRef} className="w-full max-w-[560px] mx-auto">
      <canvas
        ref={canvasRef}
        className="rounded-2xl cursor-pointer touch-none"
        style={{ width: canvasSize, height: canvasSize }}
        onMouseDown={handlePointerDown}
        onMouseMove={handlePointerMove}
        onMouseUp={handlePointerUp}
        onMouseLeave={handlePointerUp}
        onTouchStart={handlePointerDown}
        onTouchMove={handlePointerMove}
        onTouchEnd={handlePointerUp}
      />
    </div>
  );
}

// ===================== HELPERS =====================
function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}

function easeOutBounce(t: number): number {
  const n1 = 7.5625;
  const d1 = 2.75;
  if (t < 1 / d1) return n1 * t * t;
  if (t < 2 / d1) return n1 * (t -= 1.5 / d1) * t + 0.75;
  if (t < 2.5 / d1) return n1 * (t -= 2.25 / d1) * t + 0.9375;
  return n1 * (t -= 2.625 / d1) * t + 0.984375;
}
