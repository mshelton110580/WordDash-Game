// ============================================================
// WordDash Game Engine — Complete Implementation
// Full port of iOS SpriteKit mechanics to TypeScript/Canvas
// ============================================================

// --- Letter values (Scrabble-like) ---
export const LETTER_VALUES: Record<string, number> = {
  A: 1, E: 1, I: 1, O: 1, N: 1, R: 1, T: 1, L: 1, S: 1, U: 1,
  D: 2, G: 2,
  B: 3, C: 3, M: 3, P: 3,
  F: 4, H: 4, V: 4, W: 4, Y: 4,
  K: 5,
  J: 8, X: 8,
  Q: 10, Z: 10,
};

// --- Letter frequency weights ---
const LETTER_WEIGHTS: [string, number][] = [
  ['E', 12], ['T', 9], ['A', 8], ['O', 7], ['I', 7], ['N', 7],
  ['S', 6], ['H', 6], ['R', 6], ['D', 4], ['L', 4], ['C', 3],
  ['U', 3], ['M', 3], ['W', 2], ['F', 2], ['G', 2], ['Y', 2],
  ['P', 2], ['B', 2], ['V', 1], ['K', 1], ['J', 1], ['X', 1],
  ['Q', 1], ['Z', 1],
];

const totalWeight = LETTER_WEIGHTS.reduce((s, [, w]) => s + w, 0);

export function randomLetter(): string {
  let r = Math.random() * totalWeight;
  for (const [letter, weight] of LETTER_WEIGHTS) {
    r -= weight;
    if (r <= 0) return letter;
  }
  return 'E';
}

// --- Tile types ---
export type SpecialType = 'bomb' | 'laser' | 'crossLaser' | 'wildcard' | 'mine' | 'link' | null;
export type IceState = 'none' | 'intact' | 'cracked';

export interface Tile {
  id: string;
  letter: string;
  row: number;
  col: number;
  specialType: SpecialType;
  iceState: IceState;
  isClearing: boolean;
  isFalling: boolean;
  fallFromRow: number;
  animProgress: number;
  hasMine: boolean; // Mine overlay placed by power-up
  letterMultiplier: number; // 1 = normal, 2 = double letter, 3 = triple letter
}

let tileIdCounter = 0;
export function createTile(letter: string, row: number, col: number, specialType: SpecialType = null, iceState: IceState = 'none'): Tile {
  return {
    id: `tile-${tileIdCounter++}`,
    letter,
    row,
    col,
    specialType,
    iceState,
    isClearing: false,
    isFalling: false,
    fallFromRow: row,
    animProgress: 1,
    hasMine: false,
    letterMultiplier: 1,
  };
}

// --- Level config ---
export type GoalType = 'scoreTimed' | 'clearIceMoves';

export interface LevelConfig {
  levelNumber: number;
  goalType: GoalType;
  boardSize: number;
  targetScore?: number;
  timeLimitSeconds?: number;
  iceTilesToClearTarget?: number;
  moveLimit?: number;
  icePositions?: { row: number; col: number }[];
  starThresholds: { oneStar: number; twoStar: number; threeStar: number };
}

export const LEVELS: LevelConfig[] = [
  { levelNumber: 1, goalType: 'scoreTimed', boardSize: 7, targetScore: 100, timeLimitSeconds: 120, starThresholds: { oneStar: 100, twoStar: 200, threeStar: 350 } },
  { levelNumber: 2, goalType: 'scoreTimed', boardSize: 7, targetScore: 200, timeLimitSeconds: 120, starThresholds: { oneStar: 200, twoStar: 350, threeStar: 500 } },
  { levelNumber: 3, goalType: 'clearIceMoves', boardSize: 7, iceTilesToClearTarget: 5, moveLimit: 15, icePositions: [{ row: 2, col: 2 }, { row: 2, col: 4 }, { row: 4, col: 2 }, { row: 4, col: 4 }, { row: 3, col: 3 }], starThresholds: { oneStar: 50, twoStar: 100, threeStar: 200 } },
  { levelNumber: 4, goalType: 'scoreTimed', boardSize: 7, targetScore: 350, timeLimitSeconds: 110, starThresholds: { oneStar: 350, twoStar: 500, threeStar: 700 } },
  { levelNumber: 5, goalType: 'clearIceMoves', boardSize: 7, iceTilesToClearTarget: 8, moveLimit: 18, icePositions: [{ row: 1, col: 1 }, { row: 1, col: 5 }, { row: 2, col: 3 }, { row: 3, col: 1 }, { row: 3, col: 5 }, { row: 4, col: 3 }, { row: 5, col: 1 }, { row: 5, col: 5 }], starThresholds: { oneStar: 75, twoStar: 150, threeStar: 300 } },
  { levelNumber: 6, goalType: 'scoreTimed', boardSize: 7, targetScore: 500, timeLimitSeconds: 100, starThresholds: { oneStar: 500, twoStar: 750, threeStar: 1000 } },
  { levelNumber: 7, goalType: 'clearIceMoves', boardSize: 7, iceTilesToClearTarget: 10, moveLimit: 20, icePositions: [{ row: 0, col: 3 }, { row: 1, col: 2 }, { row: 1, col: 4 }, { row: 2, col: 1 }, { row: 2, col: 5 }, { row: 3, col: 0 }, { row: 3, col: 6 }, { row: 4, col: 1 }, { row: 4, col: 5 }, { row: 5, col: 3 }], starThresholds: { oneStar: 100, twoStar: 200, threeStar: 400 } },
  { levelNumber: 8, goalType: 'scoreTimed', boardSize: 7, targetScore: 700, timeLimitSeconds: 90, starThresholds: { oneStar: 700, twoStar: 1000, threeStar: 1400 } },
  { levelNumber: 9, goalType: 'clearIceMoves', boardSize: 7, iceTilesToClearTarget: 12, moveLimit: 22, icePositions: [{ row: 0, col: 2 }, { row: 0, col: 4 }, { row: 1, col: 1 }, { row: 1, col: 3 }, { row: 1, col: 5 }, { row: 2, col: 2 }, { row: 2, col: 4 }, { row: 4, col: 2 }, { row: 4, col: 4 }, { row: 5, col: 1 }, { row: 5, col: 5 }, { row: 6, col: 3 }], starThresholds: { oneStar: 150, twoStar: 300, threeStar: 500 } },
  { levelNumber: 10, goalType: 'scoreTimed', boardSize: 7, targetScore: 1000, timeLimitSeconds: 90, starThresholds: { oneStar: 1000, twoStar: 1500, threeStar: 2000 } },
];

// --- Scoring helpers ---
export function lengthMultiplier(len: number): number {
  if (len <= 3) return 1.0;
  if (len === 4) return 1.2;
  if (len === 5) return 1.5;
  if (len === 6) return 1.9;
  if (len === 7) return 2.4;
  return 3.0;
}

export function diminishingMultiplier(usageCount: number): number {
  if (usageCount <= 1) return 1.0;
  if (usageCount === 2) return 0.5;
  return 0.1;
}

export function cascadeBonus(step: number): number {
  if (step <= 0) return 0;
  if (step === 1) return 10;
  if (step === 2) return 25;
  if (step === 3) return 50;
  return 100;
}

export function specialTileForWordLength(len: number): SpecialType {
  if (len === 5) return 'bomb';
  if (len === 6) return 'laser';
  if (len === 7) return 'crossLaser';
  if (len >= 8) return 'wildcard';
  return null;
}

// --- Adjacency ---
export function areAdjacent(a: Tile, b: Tile): boolean {
  const dr = Math.abs(a.row - b.row);
  const dc = Math.abs(a.col - b.col);
  if (dr === 0 && dc === 0) return false;
  return dr <= 1 && dc <= 1;
}

// --- Dictionary sources (loaded async) ---
// Gameplay validation uses TWL06 (Official Scrabble Tournament Word List, ~178K words).
// Hint generation uses Oxford 3000 list (~2935 common English words).
let collinsWordSet: Set<string> = new Set();
let oxfordHintWordSet: Set<string> = new Set();
let wordListLoaded = false;

const DEFAULT_OXFORD_HINT_WORDS = ['THE','AND','FOR','ARE','BUT','NOT','YOU','ALL','CAN','HER','WAS','ONE','OUR','OUT','DAY','HAD','HAS','HIS','HOW','MAN','NEW','NOW','OLD','SEE','WAY','WHO','BOY','DID','GET','HIM','LET','SAY','SHE','TOO','USE','CAT','DOG','RUN','SIT','TOP','RED','BIG','FUN','SUN','CUP','BUS','MAP','PEN','TEN','WIN','AIR','EAT','FAR','HOT','OWN','PAY','AGE','AGO','BAD','BED','CUT','END','FEW','GOT','HIT','JOB','KEY','LAW','LOT','LOW','MET','OIL','PUT','RAN','SET','SIX','TRY','TWO','WAR','YES','YET','ART','BAR','BIT','BOX','CAR','DIE','EAR','EYE','FIT','GAS','ICE','LAY','LEG','LIE','LOG','PIN','RAW','ROW','RUB','SEA','SKI','TAX','TIE','WET','WORD','GAME','PLAY','TILE','STAR','FIRE','GOLD','BLUE','DARK','FAST','SLOW','JUMP','FLIP','SPIN','SWAP','BURN','COOL','WARM','COLD','HEAT','RAIN','SNOW','WIND','WAVE','ROCK','SAND','IRON','WOOD','TREE','LEAF','ROOT','SEED','GROW','ROSE','POND','LAKE','POOL','DEEP','WIDE','LONG','TALL','THIN','FLAT','SOFT','HARD','LOUD','CALM','WILD','RICH','POOR','FULL','OPEN','LOCK','FREE','LINK','LOOP','RING','BAND','ROPE','WIRE','CHAIN','FENCE','WALL','GATE','DOOR','PATH','ROAD','LANE','TRACK','ROUTE','BRIDGE','TOWER','HOUSE','SCHOOL','STORE','MARKET','GARDEN','FOREST','DESERT','ISLAND','OCEAN','RIVER','CREEK','BROOK','STREAM'];
// Used only when Collins files are unavailable.
const DEFAULT_COLLINS_FALLBACK_WORDS = [...DEFAULT_OXFORD_HINT_WORDS, 'AAHED', 'AARDVARK', 'ZOO', 'ZOOLOGIST'];

// Simple profanity block list
const profanitySet: Set<string> = new Set([
  'FUCK', 'SHIT', 'DAMN', 'HELL', 'ASS', 'BITCH', 'CRAP', 'DICK',
  'PISS', 'SLUT', 'WHORE', 'CUNT', 'COCK', 'TITS', 'TWAT', 'WANK',
]);

export function isWordListLoaded(): boolean {
  return wordListLoaded;
}

function parseUpperWords(text: string): string[] {
  return text
    .split('\n')
    .map(w => w.trim().toUpperCase())
    .filter(w => w.length >= 3 && /^[A-Z]+$/.test(w));
}

export async function loadWordList(): Promise<void> {
  // Reset sets so repeated loads do not retain stale dictionary data.
  collinsWordSet = new Set();
  oxfordHintWordSet = new Set();

  try {
    // Collins dictionary for gameplay validation.
    let collinsResp: Response;
    try {
      collinsResp = await fetch('/wordlist.txt');
      if (!collinsResp.ok) throw new Error('Local Collins fetch failed');
    } catch {
      collinsResp = await fetch('https://files.manuscdn.com/user_upload_by_module/session_file/310519663270198678/xhhiGnVTPnhcwIee.txt');
    }

    collinsWordSet = new Set(parseUpperWords(await collinsResp.text()));

    // Oxford 3000 for hints only (no legacy common_words fallback).
    try {
      const oxfordResp = await fetch('/oxford3000.txt');
      if (oxfordResp.ok) {
        const oxfordWords = parseUpperWords(await oxfordResp.text());
        oxfordHintWordSet = new Set(oxfordWords.filter(w => collinsWordSet.has(w)));
      }
    } catch {
      // ignore optional hint dictionary load failure
    }

    if (oxfordHintWordSet.size === 0) {
      oxfordHintWordSet = new Set(DEFAULT_OXFORD_HINT_WORDS.filter(w => collinsWordSet.has(w)));
    }

    wordListLoaded = true;
    console.log(`Loaded Collins words=${collinsWordSet.size}, Oxford hints=${oxfordHintWordSet.size}`);
  } catch (e) {
    console.error('Failed to load Collins dictionary, using bundled fallback list', e);
    collinsWordSet = new Set(DEFAULT_COLLINS_FALLBACK_WORDS.map(w => w.toUpperCase()));
    oxfordHintWordSet = new Set(DEFAULT_OXFORD_HINT_WORDS.map(w => w.toUpperCase()).filter(w => collinsWordSet.has(w)));
    wordListLoaded = true;
  }
}

export function isValidWord(word: string): boolean {
  const upper = word.toUpperCase();
  if (profanitySet.has(upper)) return false;
  return collinsWordSet.has(upper);
}

function isHintWord(word: string): boolean {
  const upper = word.toUpperCase();
  return oxfordHintWordSet.has(upper) && upper.length >= 3 && upper.length <= 8;
}

// --- Laser effect tracking for visual rendering ---
export interface LaserEffect {
  type: 'row' | 'col' | 'cross';
  row: number;
  col: number;
  timestamp: number;
}

// --- Game State ---
export interface GameState {
  board: (Tile | null)[][];
  boardSize: number;
  level: LevelConfig;
  score: number;
  timeRemaining: number;
  movesRemaining: number;
  iceCleared: number;
  totalIce: number;
  streakMultiplier: number;
  lastWordTime: number | null;
  wordUsage: Record<string, number>;
  cascadeStep: number;
  selectedPath: Tile[];
  isGameOver: boolean;
  isWon: boolean;
  stars: number;
  wordsFound: string[];
  lastWordScore: number;
  lastWord: string;
  showWordPopup: boolean;
  popupTimer: number;
  // Timer starts on first interaction
  timerStarted: boolean;
  // Power-ups (all 5 from spec + shuffle)
  powerUps: { hint: number; bomb: number; laser: number; crossLaser: number; mine: number; shuffle: number; link: number };
  activePowerUp: string | null;
  // Hint path (highlighted for 3 seconds)
  hintPath: Tile[];
  hintTimer: number;
  // Enhanced visual effects
  particles: Particle[];
  shockwaves: Shockwave[];
  tileClearAnims: TileClearAnim[];
  screenShake: ScreenShake;
  // Laser visual effects
  laserEffects: LaserEffect[];
  // Mine detonation tracking
  mineDetonations: { row: number; col: number }[];
  // Tiles cleared by explosions (for visual effects in renderer)
  explosionClears: { row: number; col: number; specialType: SpecialType }[];
  // Track word submissions for multiplier tile spawn frequency
  wordSubmitCount: number;
  // Track max streak and cascade for coin economy
  maxStreakReached: number;
  maxCascadeReached: number;
  // Real-time coin tracking during gameplay
  coinsEarnedThisLevel: number;
  coinFlyEvents: CoinFlyEvent[];
  scoreFlyEvents: CoinFlyEvent[];
  chainMode: ChainModeState;
  uiMessage: string;
  uiMessageTimer: number;
  chainResolutionFx: ChainResolutionFx | null;
  refillCountSinceLinkSpawn: number;
  // Deferred clear system: tiles animate before removal
  pendingClear: boolean; // true while clear animation is playing
  pendingClearTimestamp: number; // when the clear started (Date.now())
  pendingClearDuration: number; // ms to wait before flushing
  pendingGravity: boolean; // gravity+refill needs to run after flush
  _pendingSpecialSpawn: { row: number; col: number; specialType: SpecialType } | null;
  _particlesSpawnedSet: Set<string>; // tracks which clearing tiles already spawned particles
}

export interface ChainModeState {
  chainActive: boolean;
  linkedTiles: Set<string>;
  chainWordCount: number;
  chainBasePoints: number;
  pendingWord: PendingWord | null;
}

export interface PendingWord {
  coords: { row: number; col: number }[];
  word: string;
}

export interface ChainResolutionFx {
  timestamp: number;
  multiplier: number;
  words: number;
  points: number;
  coins: number;
}

export const LinkModeConfig = {
  pointsPerCoin: 250,
  linkSpawnChancePerRefill: 0.05,
  linkSpawnCooldownDrops: 10,
  maxLinkSpawnsPerRefill: 1,
  scoreFlyThreshold: 1000,
  maxFlyFragments: 25,
  flyDurationMs: 750,
};

const keyFor = (row: number, col: number) => `${row},${col}`;

export function getChainMultiplier(chainWordCount: number, explosiveEnded = false): number {
  const effective = explosiveEnded ? Math.max(1, chainWordCount - 1) : chainWordCount;
  if (effective <= 1) return 1;
  if (effective === 2) return 2;
  if (effective === 3) return 3;
  if (effective === 4) return 4;
  if (effective === 5) return 6;
  if (effective === 6) return 8;
  return 10;
}

export interface CoinFlyEvent {
  id: string;
  amount: number;
  fromRow: number;
  fromCol: number;
  timestamp: number;
}

// --- Enhanced Particle System: Multi-emitter with roles ---
export type ParticleRole = 'chip' | 'dust' | 'sparkle' | 'debris';
export type ParticleBlend = 'alpha' | 'add';

export interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  color: string;
  size: number;
  role: ParticleRole;
  blend: ParticleBlend;
  rotation: number;
  rotationSpeed: number;
  shape: 'circle' | 'rect'; // rect for chips, circle for dust/sparkle
}

// --- Shockwave ring effect ---
export interface Shockwave {
  x: number;
  y: number;
  startTime: number;
  duration: number; // ms
  maxScale: number;
  color: string;
}

// --- Tile clear animation state ---
export interface TileClearAnim {
  row: number;
  col: number;
  letter: string;
  specialType: SpecialType;
  phase: 'squash' | 'pop' | 'fade'; // squash -> pop -> fade
  progress: number; // 0-1
  delay: number; // stagger delay in frames
  color: string; // themed color for particles
}

// --- Screen shake state ---
export interface ScreenShake {
  intensity: number; // pixels
  duration: number; // frames remaining
  offsetX: number;
  offsetY: number;
}

export function createGameState(level: LevelConfig): GameState {
  const board: (Tile | null)[][] = [];
  const size = level.boardSize;

  for (let r = 0; r < size; r++) {
    board[r] = [];
    for (let c = 0; c < size; c++) {
      const letter = randomLetter();
      let iceState: IceState = 'none';
      if (level.icePositions) {
        const isIce = level.icePositions.some(p => p.row === r && p.col === c);
        if (isIce) iceState = 'intact';
      }
      board[r][c] = createTile(letter, r, c, null, iceState);
    }
  }

  const totalIce = level.icePositions ? level.icePositions.length : 0;

  return {
    board,
    boardSize: size,
    level,
    score: 0,
    timeRemaining: level.timeLimitSeconds || 999,
    movesRemaining: level.moveLimit || 999,
    iceCleared: 0,
    totalIce,
    streakMultiplier: 1.0,
    lastWordTime: null,
    wordUsage: {},
    cascadeStep: 0,
    selectedPath: [],
    isGameOver: false,
    isWon: false,
    stars: 0,
    wordsFound: [],
    lastWordScore: 0,
    lastWord: '',
    showWordPopup: false,
    popupTimer: 0,
    timerStarted: false,
    powerUps: { hint: 3, bomb: 2, laser: 2, crossLaser: 1, mine: 2, shuffle: 2, link: 0 }, // defaults, overridden by economy loadInventory in Home.tsx
    activePowerUp: null,
    hintPath: [],
    hintTimer: 0,
    particles: [],
    shockwaves: [],
    tileClearAnims: [],
    screenShake: { intensity: 0, duration: 0, offsetX: 0, offsetY: 0 },
    laserEffects: [],
    mineDetonations: [],
    explosionClears: [],
    wordSubmitCount: 0,
    maxStreakReached: 1.0,
    maxCascadeReached: 0,
    coinsEarnedThisLevel: 0,
    coinFlyEvents: [],
    scoreFlyEvents: [],
    chainMode: {
      chainActive: false,
      linkedTiles: new Set<string>(),
      chainWordCount: 0,
      chainBasePoints: 0,
      pendingWord: null,
    },
    uiMessage: '',
    uiMessageTimer: 0,
    chainResolutionFx: null,
    refillCountSinceLinkSpawn: 0,
    pendingClear: false,
    pendingClearTimestamp: 0,
    pendingClearDuration: 0,
    pendingGravity: false,
    _pendingSpecialSpawn: null,
    _particlesSpawnedSet: new Set<string>(),
  };
}

// --- Core game actions ---
export function getWordFromPath(path: Tile[]): string {
  return path.map(t => t.letter === '★' ? '*' : t.letter).join('');
}

// --- Hit ice on a tile (2-hit mechanic) ---
function hitIce(state: GameState, r: number, c: number) {
  const tile = state.board[r]?.[c];
  if (!tile || tile.iceState === 'none') return;
  if (tile.iceState === 'intact') {
    tile.iceState = 'cracked';
  } else if (tile.iceState === 'cracked') {
    tile.iceState = 'none';
    state.iceCleared++;
  }
}

// --- Clear a single tile (handles mine triggers) ---
// Now marks tile as isClearing instead of removing immediately.
// The tile stays on the board for the animation, then flushPendingClears removes it.
function clearTile(state: GameState, r: number, c: number) {
  const tile = state.board[r]?.[c];
  if (!tile || tile.isClearing) return;
  // Hit ice on this tile
  hitIce(state, r, c);
  // If tile has a mine (either specialType or legacy hasMine overlay), queue detonation
  if (tile.hasMine || tile.specialType === 'mine') {
    state.mineDetonations.push({ row: r, col: c });
  }
  tile.isClearing = true; // Mark for deferred removal
}

// --- Flush pending clears: actually remove tiles, apply gravity, refill ---
// Called by the renderer after the clear animation finishes.
export function flushPendingClears(state: GameState) {
  if (!state.pendingClear) return;

  // Remove all tiles marked as isClearing
  for (let r = 0; r < state.boardSize; r++) {
    for (let c = 0; c < state.boardSize; c++) {
      const tile = state.board[r]?.[c];
      if (tile && tile.isClearing) {
        state.board[r][c] = null;
      }
    }
  }

  // Spawn special tile if earned
  if (state._pendingSpecialSpawn) {
    const { row, col, specialType } = state._pendingSpecialSpawn;
    // Only spawn if the position is now empty
    if (!state.board[row][col]) {
      const newTile = createTile(
        specialType === 'wildcard' ? '\u2605' : randomLetter(),
        row,
        col,
        specialType
      );
      state.board[row][col] = newTile;
    }
    state._pendingSpecialSpawn = null;
  }

  // Apply gravity and refill
  applyGravity(state);
  refillBoard(state);

  // Check win conditions
  checkWinCondition(state);

  // Reset pending state
  state.pendingClear = false;
  state.pendingGravity = false;
  state.pendingClearTimestamp = 0;
  state.pendingClearDuration = 0;
  state.explosionClears = [];
  state._particlesSpawnedSet.clear();
}

function calculateWordScore(state: GameState, path: Tile[], word: string): number {
  const rawScore = path.reduce((sum, t) => {
    if (t.specialType === 'wildcard') return sum + 2;
    return sum + (LETTER_VALUES[t.letter] || 2);
  }, 0);
  const combinedLetterMult = path.reduce((m, t) => m * (t.letterMultiplier || 1), 1);
  const baseScore = rawScore * combinedLetterMult;
  const lenMult = lengthMultiplier(path.length);

  const now = Date.now();
  if (state.lastWordTime && (now - state.lastWordTime) < 4000) {
    state.streakMultiplier = Math.min(3.0, state.streakMultiplier + 0.2);
  } else {
    state.streakMultiplier = 1.0;
  }
  state.lastWordTime = now;
  if (state.streakMultiplier > state.maxStreakReached) state.maxStreakReached = state.streakMultiplier;

  const usage = (state.wordUsage[word.toUpperCase()] || 0) + 1;
  state.wordUsage[word.toUpperCase()] = usage;
  const dimMult = diminishingMultiplier(usage);
  return Math.round(baseScore * lenMult * state.streakMultiplier * dimMult);
}

function markDeferredClear(state: GameState, path: Tile[]) {
  const totalAnimTiles = path.length + state.explosionClears.length;
  const staggerMs = Math.min(totalAnimTiles * 25, 200);
  const animDuration = staggerMs + 350;
  state.pendingClear = true;
  state.pendingClearTimestamp = Date.now();
  state.pendingClearDuration = animDuration;
  state.pendingGravity = true;
}

function resolveChain(state: GameState, explosiveEnded = false) {
  const cm = state.chainMode;
  if (!cm.chainActive || cm.linkedTiles.size === 0 || cm.chainWordCount <= 0) return;

  const multiplier = getChainMultiplier(cm.chainWordCount, explosiveEnded);
  const points = cm.chainBasePoints * multiplier;
  const coins = Math.floor(points / LinkModeConfig.pointsPerCoin);

  state.score += points;
  state.coinsEarnedThisLevel += coins;
  state.chainResolutionFx = {
    timestamp: Date.now(),
    multiplier,
    words: cm.chainWordCount,
    points,
    coins,
  };

  const linkedCoords: { row: number; col: number }[] = [];
  cm.linkedTiles.forEach((key) => {
    const [r, c] = key.split(',').map(Number);
    linkedCoords.push({ row: r, col: c });
  });

  for (const coord of linkedCoords) {
    if (state.board[coord.row]?.[coord.col]) {
      state.explosionClears.push({ row: coord.row, col: coord.col, specialType: 'link' });
      clearTile(state, coord.row, coord.col);
    }
  }

  if (coins > 0 && linkedCoords.length > 0) {
    const center = linkedCoords[Math.floor(linkedCoords.length / 2)];
    state.coinFlyEvents.push({
      id: `chain-coin-${Date.now()}-${Math.random()}`,
      amount: coins,
      fromRow: center.row,
      fromCol: center.col,
      timestamp: Date.now(),
    });
  }

  if (points >= LinkModeConfig.scoreFlyThreshold && linkedCoords.length > 0) {
    const center = linkedCoords[Math.floor(linkedCoords.length / 2)];
    state.scoreFlyEvents.push({
      id: `chain-score-${Date.now()}-${Math.random()}`,
      amount: points,
      fromRow: center.row,
      fromCol: center.col,
      timestamp: Date.now(),
    });
  }

  markDeferredClear(state, linkedCoords.map(c => state.board[c.row]?.[c.col]).filter(Boolean) as Tile[]);

  cm.chainActive = false;
  cm.linkedTiles.clear();
  cm.chainWordCount = 0;
  cm.chainBasePoints = 0;
}

function applyNonChainWord(state: GameState, path: Tile[], word: string, totalScore: number): { valid: boolean; score: number; word: string } {
  state.lastWordScore = totalScore;
  state.lastWord = word;
  state.showWordPopup = true;
  state.popupTimer = 60;
  state.wordsFound.push(word);
  state.cascadeStep = 0;
  state.mineDetonations = [];
  state.explosionClears = [];

  if (state.level.goalType === 'clearIceMoves') state.movesRemaining--;
  for (const tile of path) hitIce(state, tile.row, tile.col);

  const specialType = specialTileForWordLength(path.length);
  const specialEffects: { type: SpecialType; tile: Tile }[] = [];
  for (const tile of path) {
    const boardTile = state.board[tile.row]?.[tile.col];
    if (boardTile?.specialType && boardTile.specialType !== 'wildcard' && boardTile.specialType !== 'link') {
      specialEffects.push({ type: boardTile.specialType, tile: boardTile });
    }
  }

  for (const tile of path) clearTile(state, tile.row, tile.col);

  const explosiveEnded = specialEffects.some(e => e.type === 'bomb' || e.type === 'laser' || e.type === 'crossLaser' || e.type === 'mine');
  if (explosiveEnded && state.chainMode.chainActive) {
    resolveChain(state, true);
  }

  const bombCount = specialEffects.filter(e => e.type === 'bomb').length;
  if (bombCount >= 2) {
    state.cascadeStep++;
    triggerBoardExplosion(state);
    state.score += cascadeBonus(state.cascadeStep) * 3;
    for (const effect of specialEffects) {
      if (effect.type === 'laser') {
        state.cascadeStep++;
        triggerLaser(state, effect.tile, path);
        state.score += cascadeBonus(state.cascadeStep);
      } else if (effect.type === 'crossLaser') {
        state.cascadeStep++;
        triggerCrossLaser(state, effect.tile);
        state.score += cascadeBonus(state.cascadeStep);
      } else if (effect.type === 'mine') {
        state.cascadeStep++;
        triggerMine(state, effect.tile.row, effect.tile.col);
        state.score += cascadeBonus(state.cascadeStep);
      }
    }
  } else {
    for (const effect of specialEffects) {
      state.cascadeStep++;
      if (effect.type === 'bomb') triggerBomb(state, effect.tile);
      else if (effect.type === 'laser') triggerLaser(state, effect.tile, path);
      else if (effect.type === 'crossLaser') triggerCrossLaser(state, effect.tile);
      else if (effect.type === 'mine') triggerMine(state, effect.tile.row, effect.tile.col);
      state.score += cascadeBonus(state.cascadeStep);
    }
  }

  processMineDetonations(state);
  if (state.cascadeStep > state.maxCascadeReached) state.maxCascadeReached = state.cascadeStep;

  state._pendingSpecialSpawn = null;
  if (specialType && path.length > 0) {
    const lastTile = path[path.length - 1];
    state._pendingSpecialSpawn = { row: lastTile.row, col: lastTile.col, specialType };
  }

  markDeferredClear(state, path);
  state.selectedPath = [];
  return { valid: true, score: totalScore, word };
}

export function submitWord(state: GameState): { valid: boolean; score: number; word: string } {
  const path = state.selectedPath;
  if (path.length < 3) return { valid: false, score: 0, word: '' };

  const word = getWordFromPath(path);
  if (!isValidWord(word)) {
    triggerScreenShake(state, 4, 12);
    state.selectedPath = [];
    return { valid: false, score: 0, word };
  }

  state.timerStarted = true;
  state.hintPath = [];
  state.hintTimer = 0;
  state.wordSubmitCount++;

  const totalScore = calculateWordScore(state, path, word);
  const hasOverlap = path.some(t => state.chainMode.linkedTiles.has(keyFor(t.row, t.col)));
  const hasLinkTile = path.some(t => t.specialType === 'link');

  if (state.chainMode.chainActive && !hasOverlap) {
    state.chainMode.pendingWord = {
      word,
      coords: path.map(t => ({ row: t.row, col: t.col })),
    };

    resolveChain(state, false);
    if (state.pendingClear) flushPendingClears(state);

    const pending = state.chainMode.pendingWord;
    state.chainMode.pendingWord = null;
    if (pending) {
      const reboundPath: Tile[] = [];
      for (const c of pending.coords) {
        const tile = state.board[c.row]?.[c.col];
        if (!tile) {
          state.selectedPath = [];
          state.uiMessage = 'Board Shifted';
          state.uiMessageTimer = 90;
          return { valid: true, score: 0, word: pending.word };
        }
        reboundPath.push(tile);
      }
      const reboundWord = getWordFromPath(reboundPath);
      if (!isValidWord(reboundWord)) {
        state.selectedPath = [];
        state.uiMessage = 'Board Shifted';
        state.uiMessageTimer = 90;
        return { valid: true, score: 0, word: pending.word };
      }
      state.selectedPath = reboundPath;
      return applyNonChainWord(state, reboundPath, reboundWord, calculateWordScore(state, reboundPath, reboundWord));
    }
  }

  if (hasLinkTile || state.chainMode.chainActive) {
    state.chainMode.chainActive = true;
    state.chainMode.chainWordCount++;
    state.chainMode.chainBasePoints += totalScore;
    for (const tile of path) state.chainMode.linkedTiles.add(keyFor(tile.row, tile.col));

    state.lastWordScore = totalScore;
    state.lastWord = word;
    state.showWordPopup = true;
    state.popupTimer = 60;
    state.wordsFound.push(word);
    state.selectedPath = [];
    return { valid: true, score: totalScore, word };
  }

  return applyNonChainWord(state, path, word, totalScore);
}

export function forceResolveChainOnTimer(state: GameState) {
  if (!state.chainMode.chainActive) return;
  state.explosionClears = [];
  resolveChain(state, false);
  checkWinCondition(state);
}

// Award base letter points for a tile destroyed by explosion (no multiplier bonuses)
function awardExplosionPoints(state: GameState, r: number, c: number) {
  const tile = state.board[r]?.[c];
  if (!tile) return;
  // Base letter value only — no letterMultiplier for explosions
  const pts = LETTER_VALUES[tile.letter] || 2;
  state.score += pts;
}

function triggerBomb(state: GameState, center: Tile) {
  for (let dr = -1; dr <= 1; dr++) {
    for (let dc = -1; dc <= 1; dc++) {
      const r = center.row + dr;
      const c = center.col + dc;
      if (r >= 0 && r < state.boardSize && c >= 0 && c < state.boardSize) {
        if (state.board[r]?.[c]) state.explosionClears.push({ row: r, col: c, specialType: 'bomb' });
        awardExplosionPoints(state, r, c);
        hitIce(state, r, c);
        clearTile(state, r, c);
      }
    }
  }
}

// Dual-bomb board explosion: if a word path contains 2+ bomb tiles, clear the entire board
function triggerBoardExplosion(state: GameState) {
  for (let r = 0; r < state.boardSize; r++) {
    for (let c = 0; c < state.boardSize; c++) {
      if (state.board[r]?.[c]) state.explosionClears.push({ row: r, col: c, specialType: 'bomb' });
      awardExplosionPoints(state, r, c);
      hitIce(state, r, c);
      clearTile(state, r, c);
    }
  }
}

function triggerLaser(state: GameState, tile: Tile, path: Tile[]) {
  // Determine direction: check if the drag into the laser tile was more horizontal or vertical
  const idx = path.findIndex(t => t.id === tile.id);
  let isHorizontal = true; // default to row
  if (idx > 0) {
    const prev = path[idx - 1];
    const dRow = Math.abs(tile.row - prev.row);
    const dCol = Math.abs(tile.col - prev.col);
    isHorizontal = dCol >= dRow;
  }

  // Track laser effect for visual rendering
  state.laserEffects.push({
    type: isHorizontal ? 'row' : 'col',
    row: tile.row,
    col: tile.col,
    timestamp: Date.now(),
  });

  if (isHorizontal) {
    for (let c = 0; c < state.boardSize; c++) {
      if (state.board[tile.row]?.[c]) state.explosionClears.push({ row: tile.row, col: c, specialType: 'laser' });
      awardExplosionPoints(state, tile.row, c);
      hitIce(state, tile.row, c);
      clearTile(state, tile.row, c);
    }
  } else {
    for (let r = 0; r < state.boardSize; r++) {
      if (state.board[r]?.[tile.col]) state.explosionClears.push({ row: r, col: tile.col, specialType: 'laser' });
      awardExplosionPoints(state, r, tile.col);
      hitIce(state, r, tile.col);
      clearTile(state, r, tile.col);
    }
  }
}

function triggerCrossLaser(state: GameState, tile: Tile) {
  // Track laser effect for visual rendering
  state.laserEffects.push({
    type: 'cross',
    row: tile.row,
    col: tile.col,
    timestamp: Date.now(),
  });

  for (let c = 0; c < state.boardSize; c++) {
    if (state.board[tile.row]?.[c]) state.explosionClears.push({ row: tile.row, col: c, specialType: 'crossLaser' });
    awardExplosionPoints(state, tile.row, c);
    hitIce(state, tile.row, c);
    clearTile(state, tile.row, c);
  }
  for (let r = 0; r < state.boardSize; r++) {
    if (state.board[r]?.[tile.col]) state.explosionClears.push({ row: r, col: tile.col, specialType: 'crossLaser' });
    awardExplosionPoints(state, r, tile.col);
    hitIce(state, r, tile.col);
    clearTile(state, r, tile.col);
  }
}

function triggerMine(state: GameState, row: number, col: number) {
  // Mine clears surrounding 3x3
  for (let dr = -1; dr <= 1; dr++) {
    for (let dc = -1; dc <= 1; dc++) {
      const r = row + dr;
      const c = col + dc;
      if (r >= 0 && r < state.boardSize && c >= 0 && c < state.boardSize) {
        if (state.board[r]?.[c]) state.explosionClears.push({ row: r, col: c, specialType: 'mine' });
        awardExplosionPoints(state, r, c);
        hitIce(state, r, c);
        clearTile(state, r, c);
      }
    }
  }
}

function processMineDetonations(state: GameState) {
  let safety = 0;
  while (state.mineDetonations.length > 0 && safety < 20) {
    safety++;
    const mines = [...state.mineDetonations];
    state.mineDetonations = [];
    for (const mine of mines) {
      state.cascadeStep++;
      triggerMine(state, mine.row, mine.col);
      state.score += cascadeBonus(state.cascadeStep);
    }
  }
}

export function applyGravity(state: GameState) {
  for (let c = 0; c < state.boardSize; c++) {
    let writeRow = state.boardSize - 1;
    for (let r = state.boardSize - 1; r >= 0; r--) {
      if (state.board[r][c] !== null) {
        const tile = state.board[r][c]!;
        if (r !== writeRow) {
          tile.fallFromRow = r;
          tile.row = writeRow;
          tile.isFalling = true;
          tile.animProgress = 0;
          state.board[writeRow][c] = tile;
          state.board[r][c] = null;
        }
        writeRow--;
      }
    }
  }
}

export function refillBoard(state: GameState) {
  const canSpawnMultipliers = state.wordSubmitCount >= 2 && state.wordSubmitCount % 3 === 0;
  const canSpawnLink = state.refillCountSinceLinkSpawn >= LinkModeConfig.linkSpawnCooldownDrops;
  const shouldRollLink = canSpawnLink && Math.random() < LinkModeConfig.linkSpawnChancePerRefill;
  const nulls: { row: number; col: number }[] = [];
  for (let c = 0; c < state.boardSize; c++) {
    for (let r = state.boardSize - 1; r >= 0; r--) {
      if (state.board[r][c] === null) nulls.push({ row: r, col: c });
    }
  }
  const linkTarget = shouldRollLink && nulls.length > 0
    ? nulls[Math.floor(Math.random() * nulls.length)]
    : null;

  for (let c = 0; c < state.boardSize; c++) {
    for (let r = state.boardSize - 1; r >= 0; r--) {
      if (state.board[r][c] === null) {
        const tile = createTile(randomLetter(), r, c);
        tile.fallFromRow = -1;
        tile.isFalling = true;
        tile.animProgress = 0;

        if (linkTarget && linkTarget.row === r && linkTarget.col === c) {
          tile.specialType = 'link';
          state.refillCountSinceLinkSpawn = 0;
        }

        if (canSpawnMultipliers && !tile.specialType) {
          const roll = Math.random();
          if (roll < 0.06) tile.letterMultiplier = 3;
          else if (roll < 0.18) tile.letterMultiplier = 2;
        }

        state.board[r][c] = tile;
      }
    }
  }

  if (!linkTarget) state.refillCountSinceLinkSpawn++;
}

export function checkWinCondition(state: GameState) {
  if (state.level.goalType === 'scoreTimed') {
    if (state.score >= (state.level.targetScore || 0)) {
      state.isWon = true;
      state.isGameOver = true;
      state.stars = calculateStars(state);
    }
    if (state.timeRemaining <= 0 && !state.isWon) {
      state.isGameOver = true;
      state.stars = 0;
    }
  } else if (state.level.goalType === 'clearIceMoves') {
    if (state.iceCleared >= state.totalIce) {
      state.isWon = true;
      state.isGameOver = true;
      state.stars = calculateStars(state);
    }
    if (state.movesRemaining <= 0 && !state.isWon) {
      state.isGameOver = true;
      state.stars = 0;
    }
  }
}

function calculateStars(state: GameState): number {
  const { starThresholds } = state.level;
  if (state.score >= starThresholds.threeStar) return 3;
  if (state.score >= starThresholds.twoStar) return 2;
  if (state.score >= starThresholds.oneStar) return 1;
  return 0;
}

// --- Power-up actions ---
export function useShuffle(state: GameState) {
  if (state.powerUps.shuffle <= 0) return;
  state.powerUps.shuffle--;
  state.timerStarted = true;
  for (let r = 0; r < state.boardSize; r++) {
    for (let c = 0; c < state.boardSize; c++) {
      const tile = state.board[r][c];
      if (tile && !tile.specialType) {
        tile.letter = randomLetter();
      }
    }
  }
}

// Helper: find a random normal tile on the board (no special type, not in ice)
function findRandomNormalTile(state: GameState): { row: number; col: number } | null {
  const candidates: { row: number; col: number }[] = [];
  for (let r = 0; r < state.boardSize; r++) {
    for (let c = 0; c < state.boardSize; c++) {
      const tile = state.board[r]?.[c];
      if (tile && !tile.specialType && !tile.hasMine) {
        candidates.push({ row: r, col: c });
      }
    }
  }
  if (candidates.length === 0) return null;
  return candidates[Math.floor(Math.random() * candidates.length)];
}

// Bomb power-up: places a bomb special tile at a random position on the board.
// The tile keeps its letter and triggers when included in a valid word.
export function useBombPowerUp(state: GameState) {
  if (state.powerUps.bomb <= 0) return;
  const pos = findRandomNormalTile(state);
  if (!pos) return;
  state.powerUps.bomb--;
  state.timerStarted = true;
  const tile = state.board[pos.row][pos.col]!;
  tile.specialType = 'bomb';
  state.activePowerUp = null;
}

// Laser power-up: places a laser special tile at a random position on the board.
// The tile keeps its letter and triggers when included in a valid word.
export function useLaserPowerUp(state: GameState) {
  if (state.powerUps.laser <= 0) return;
  const pos = findRandomNormalTile(state);
  if (!pos) return;
  state.powerUps.laser--;
  state.timerStarted = true;
  const tile = state.board[pos.row][pos.col]!;
  tile.specialType = 'laser';
  state.activePowerUp = null;
}

// Cross Laser power-up: places a crossLaser special tile at a random position.
// The tile keeps its letter and triggers when included in a valid word.
export function useCrossLaserPowerUp(state: GameState) {
  if (state.powerUps.crossLaser <= 0) return;
  const pos = findRandomNormalTile(state);
  if (!pos) return;
  state.powerUps.crossLaser--;
  state.timerStarted = true;
  const tile = state.board[pos.row][pos.col]!;
  tile.specialType = 'crossLaser';
  state.activePowerUp = null;
}

// Mine power-up: places a mine overlay on a random tile.
// The mine detonates when the tile is cleared (included in a word or destroyed by another effect).
export function useMinePowerUp(state: GameState) {
  if (state.powerUps.mine <= 0) return;
  const pos = findRandomNormalTile(state);
  if (!pos) return;
  state.powerUps.mine--;
  state.timerStarted = true;
  const tile = state.board[pos.row][pos.col]!;
  tile.specialType = 'mine';
  state.activePowerUp = null;
}


export function useLinkPowerUp(state: GameState) {
  if (state.powerUps.link <= 0) return;
  const pos = findRandomNormalTile(state);
  if (!pos) return;
  state.powerUps.link--;
  state.timerStarted = true;
  state.board[pos.row][pos.col]!.specialType = 'link';
  state.activePowerUp = null;
}

// --- Hint system: find a valid word on the board ---
export function findHintPath(state: GameState): Tile[] {
  const size = state.boardSize;
  const board = state.board;
  let bestPath: Tile[] = [];

  // DFS to find valid words, prefer longer ones
  function dfs(path: Tile[], visited: Set<string>) {
    if (path.length >= 3) {
      const word = path.map(t => t.letter).join('');
      if (isHintWord(word) && path.length > bestPath.length) {
        bestPath = [...path];
        if (bestPath.length >= 5) return; // Good enough
      }
    }
    if (path.length >= 7) return; // Limit search depth

    const last = path[path.length - 1];
    for (let dr = -1; dr <= 1; dr++) {
      for (let dc = -1; dc <= 1; dc++) {
        if (dr === 0 && dc === 0) continue;
        const nr = last.row + dr;
        const nc = last.col + dc;
        if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
        const tile = board[nr]?.[nc];
        if (!tile) continue;
        const key = `${nr},${nc}`;
        if (visited.has(key)) continue;

        visited.add(key);
        path.push(tile);
        dfs(path, visited);
        path.pop();
        visited.delete(key);

        if (bestPath.length >= 5) return;
      }
    }
  }

  // Try starting from each tile
  for (let r = 0; r < size && bestPath.length < 5; r++) {
    for (let c = 0; c < size && bestPath.length < 5; c++) {
      const tile = board[r]?.[c];
      if (!tile) continue;
      const visited = new Set<string>([`${r},${c}`]);
      dfs([tile], visited);
    }
  }

  return bestPath;
}

export function useHintPowerUp(state: GameState) {
  if (state.powerUps.hint <= 0) return;
  const path = findHintPath(state);
  if (path.length === 0) return;
  state.powerUps.hint--;
  state.hintPath = path;
  state.hintTimer = 180; // 3 seconds at 60fps
}

// ============================================================
// ENHANCED VISUAL EFFECTS SYSTEM
// ============================================================

// --- Themed colors for different clear types ---
export function getClearThemeColor(specialType: SpecialType): string {
  switch (specialType) {
    case 'bomb': return '#FF6B35';    // warm orange
    case 'laser': return '#4DA6FF';   // cool blue
    case 'crossLaser': return '#B266FF'; // purple
    case 'wildcard': return '#FFD700'; // gold
    case 'mine': return '#FF4444';    // sharp red
    case 'link': return '#22d3ee';    // cyan link
    default: return '#D4A574';         // warm wood/dust
  }
}

// --- Multi-emitter particle spawner ---
// Spawns chips (small rects, gravity), dust (soft circles, quick fade), and sparkles (additive, upward)
// TUNED FOR VISIBILITY: particles are 3-4x larger and faster than v1
export function spawnLayeredParticles(
  state: GameState,
  x: number,
  y: number,
  themeColor: string,
  intensity: 'normal' | 'big' | 'mega' = 'normal'
) {
  const chipCount = intensity === 'mega' ? 16 : intensity === 'big' ? 12 : 8;
  const dustCount = intensity === 'mega' ? 10 : intensity === 'big' ? 7 : 5;
  const sparkleCount = intensity === 'mega' ? 10 : intensity === 'big' ? 7 : 4;

  // Wood chips: rectangles with gravity, randomized angle/speed for organic feel
  for (let i = 0; i < chipCount; i++) {
    const angle = Math.random() * Math.PI * 2;
    const speed = 4 + Math.random() * 8; // 3x faster
    state.particles.push({
      x: x + (Math.random() - 0.5) * 16,
      y: y + (Math.random() - 0.5) * 16,
      vx: Math.cos(angle) * speed * (0.7 + Math.random() * 0.6),
      vy: Math.sin(angle) * speed - 4,
      life: 25 + Math.random() * 20,
      maxLife: 45,
      color: themeColor,
      size: 4 + Math.random() * 6, // 2-3x bigger
      role: 'chip',
      blend: 'alpha',
      rotation: Math.random() * Math.PI * 2,
      rotationSpeed: (Math.random() - 0.5) * 0.5,
      shape: 'rect',
    });
  }

  // Dust puff: soft expanding circles, quick fade
  for (let i = 0; i < dustCount; i++) {
    const angle = Math.random() * Math.PI * 2;
    const speed = 1.5 + Math.random() * 3;
    state.particles.push({
      x: x + (Math.random() - 0.5) * 20,
      y: y + (Math.random() - 0.5) * 20,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed - 0.8,
      life: 18 + Math.random() * 14,
      maxLife: 32,
      color: themeColor,
      size: 10 + Math.random() * 14, // 2x bigger
      role: 'dust',
      blend: 'alpha',
      rotation: 0,
      rotationSpeed: 0,
      shape: 'circle',
    });
  }

  // Sparkles: additive glow, upward drift, bright white/gold
  for (let i = 0; i < sparkleCount; i++) {
    const angle = -Math.PI / 2 + (Math.random() - 0.5) * 1.5;
    const speed = 2.5 + Math.random() * 4;
    state.particles.push({
      x: x + (Math.random() - 0.5) * 12,
      y: y + (Math.random() - 0.5) * 12,
      vx: Math.cos(angle) * speed * 0.6,
      vy: Math.sin(angle) * speed - 2.5,
      life: 28 + Math.random() * 20,
      maxLife: 48,
      color: intensity === 'normal' ? '#FFFBE6' : '#FFFFFF',
      size: 3 + Math.random() * 5, // 2x bigger
      role: 'sparkle',
      blend: 'add',
      rotation: 0,
      rotationSpeed: 0,
      shape: 'circle',
    });
  }

  // Performance cap: limit total particles
  if (state.particles.length > 500) {
    state.particles = state.particles.slice(-400);
  }
}

// Legacy compat wrapper
export function spawnParticles(state: GameState, x: number, y: number, color: string, count: number = 12) {
  spawnLayeredParticles(state, x, y, color, count > 15 ? 'big' : 'normal');
}

// --- Shockwave spawner ---
export function spawnShockwave(
  state: GameState,
  x: number,
  y: number,
  color: string = 'rgba(255,255,255,0.6)',
  duration: number = 220,
  maxScale: number = 1.4
) {
  state.shockwaves.push({
    x,
    y,
    startTime: Date.now(),
    duration,
    maxScale,
    color,
  });
}

// --- Tile clear animation spawner (staggered squash+pop+fade) ---
export function spawnTileClearAnim(
  state: GameState,
  row: number,
  col: number,
  letter: string,
  specialType: SpecialType,
  delayIndex: number = 0
) {
  state.tileClearAnims.push({
    row,
    col,
    letter,
    specialType,
    phase: 'squash',
    progress: 0,
    delay: delayIndex * 1.5, // stagger by ~25ms per tile at 60fps
    color: getClearThemeColor(specialType),
  });
}

// --- Screen shake trigger ---
export function triggerScreenShake(
  state: GameState,
  intensity: number = 3,
  duration: number = 8
) {
  // Only override if stronger than current shake
  if (intensity > state.screenShake.intensity || state.screenShake.duration <= 0) {
    state.screenShake.intensity = intensity;
    state.screenShake.duration = duration;
  }
}

// --- Update all visual effects each frame ---
export function updateParticles(state: GameState) {
  // Update particles
  state.particles = state.particles.filter(p => {
    p.x += p.vx;
    p.y += p.vy;
    p.rotation += p.rotationSpeed;
    // Gravity varies by role
    if (p.role === 'chip' || p.role === 'debris') {
      p.vy += 0.15; // heavier gravity for chips
    } else if (p.role === 'dust') {
      p.vy += 0.02; // very light
      p.vx *= 0.97; // drag
    } else if (p.role === 'sparkle') {
      p.vy -= 0.02; // slight upward drift
      p.vx *= 0.98;
    }
    p.life--;
    return p.life > 0;
  });

  // Update shockwaves (remove expired)
  const now = Date.now();
  state.shockwaves = state.shockwaves.filter(s => (now - s.startTime) < s.duration);

  // Update tile clear animations
  state.tileClearAnims = state.tileClearAnims.filter(a => {
    if (a.delay > 0) {
      a.delay--;
      return true;
    }
    a.progress += 0.08; // ~12 frames total
    if (a.progress >= 1.0) {
      if (a.phase === 'squash') {
        a.phase = 'pop';
        a.progress = 0;
      } else if (a.phase === 'pop') {
        a.phase = 'fade';
        a.progress = 0;
      } else {
        return false; // animation complete
      }
    }
    return true;
  });

  // Update screen shake
  if (state.screenShake.duration > 0) {
    state.screenShake.duration--;
    const t = state.screenShake.duration / 8; // normalized
    const intensity = state.screenShake.intensity * t;
    state.screenShake.offsetX = (Math.random() - 0.5) * 2 * intensity;
    state.screenShake.offsetY = (Math.random() - 0.5) * 2 * intensity;
  } else {
    state.screenShake.offsetX = 0;
    state.screenShake.offsetY = 0;
  }
}
