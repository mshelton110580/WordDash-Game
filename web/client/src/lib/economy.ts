// ============================================================
// WordDash Economy System
// Design: Midnight Glass — all economy values in GameEconomyConfig
// No hardcoded values; modular and configurable
// ============================================================

// ---- Economy Configuration (all tunable values) ----

export const GameEconomyConfig = {
  startingCoins: 500,

  // Base coins per level = levelNumber * baseCoinsPerLevelMultiplier
  baseCoinsPerLevelMultiplier: 5,

  // Star bonuses
  starBonus: { 1: 10, 2: 20, 3: 40 } as Record<number, number>,

  // Long word bonuses (per occurrence)
  longWordBonus: [
    { minLength: 8, coins: 6 },
    { minLength: 7, coins: 4 },
    { minLength: 6, coins: 2 },
  ],

  // Streak milestone bonuses
  streakBonus: [
    { threshold: 3.0, coins: 20 },
    { threshold: 2.5, coins: 10 },
    { threshold: 2.0, coins: 5 },
  ],

  // Cascade bonuses
  cascadeBonus: [
    { minCascade: 3, coins: 10 },
    { minCascade: 2, coins: 5 },
  ],

  // Efficiency bonuses
  timedEfficiencyThreshold: 0.2, // 20% time remaining
  timedEfficiencyBonus: 10,
  moveEfficiencyThreshold: 3, // 3+ moves remaining
  moveEfficiencyBonus: 10,

  // Anti-farming
  replayBaseMultiplier: 0.5,
  replayPerformanceCap: 50,
  maxCoinsPerLevel: 500,

  // Powerup store costs
  storePrices: {
    hint: 50,
    bomb: 75,
    laser: 100,
    crossLaser: 150,
    mine: 125,
  } as Record<string, number>,

  // Continue system
  continueCosts: [200, 300, 400],
  maxContinuesPerSession: 3,
  continueTimedBonus: 60, // +60 seconds (1 minute)
  continueMoveBonus: 5,   // +5 moves

  // Daily login rewards (day 1-7)
  dailyRewards: [25, 35, 50, 75, 100, 125, 150],
};

// ---- Coin Reason Enum ----

export type CoinReason =
  | 'levelBase'
  | 'starBonus'
  | 'streakBonus'
  | 'cascadeBonus'
  | 'efficiencyBonus'
  | 'longWordBonus'
  | 'dailyLogin'
  | 'dailyChallenge'
  | 'adReward';

export interface CoinTransaction {
  amount: number;
  reason: CoinReason;
  label: string;
}

// ---- Coin Manager ----

const COIN_STORAGE_KEY = 'worddash_coins';
const FIRST_LAUNCH_KEY = 'worddash_first_launch';

type CoinChangeListener = (balance: number, delta: number, reason: CoinReason) => void;

class CoinManagerClass {
  private _balance: number = 0;
  private _listeners: CoinChangeListener[] = [];

  constructor() {
    this.load();
  }

  get balance(): number {
    return this._balance;
  }

  private load(): void {
    const stored = localStorage.getItem(COIN_STORAGE_KEY);
    const firstLaunch = localStorage.getItem(FIRST_LAUNCH_KEY);

    if (stored !== null) {
      this._balance = parseInt(stored, 10) || 0;
    } else if (!firstLaunch) {
      // First launch: grant starting coins
      this._balance = GameEconomyConfig.startingCoins;
      localStorage.setItem(FIRST_LAUNCH_KEY, 'true');
      this.save();
    } else {
      this._balance = 0;
      this.save();
    }
  }

  private save(): void {
    localStorage.setItem(COIN_STORAGE_KEY, String(this._balance));
  }

  addCoins(amount: number, reason: CoinReason): void {
    if (amount <= 0) return;
    this._balance += amount;
    this.save();
    this.notifyListeners(amount, reason);
  }

  spendCoins(amount: number): boolean {
    if (amount <= 0) return true;
    if (this._balance < amount) return false;
    this._balance -= amount;
    this.save();
    this.notifyListeners(-amount, 'levelBase');
    return true;
  }

  canAfford(amount: number): boolean {
    return this._balance >= amount;
  }

  onBalanceChange(listener: CoinChangeListener): () => void {
    this._listeners.push(listener);
    return () => {
      this._listeners = this._listeners.filter(l => l !== listener);
    };
  }

  private notifyListeners(delta: number, reason: CoinReason): void {
    for (const listener of this._listeners) {
      listener(this._balance, delta, reason);
    }
  }

  // For testing/debug
  resetToStarting(): void {
    this._balance = GameEconomyConfig.startingCoins;
    this.save();
  }
}

export const CoinManager = new CoinManagerClass();

// ---- Level Completion Coin Calculator ----

export interface LevelPerformance {
  levelNumber: number;
  stars: number;
  wordsFound: string[];
  maxStreakReached: number;
  maxCascadeReached: number;
  timeRemaining: number;  // seconds remaining (for timed levels)
  totalTime: number;      // total time for the level
  movesRemaining: number; // moves remaining (for move-based levels)
  goalType: 'scoreTimed' | 'clearIceMoves';
  isReplay: boolean;      // has the player already completed this level before?
}

export interface CoinBreakdown {
  base: number;
  starBonus: number;
  longWordBonus: number;
  streakBonus: number;
  cascadeBonus: number;
  efficiencyBonus: number;
  total: number;
  transactions: CoinTransaction[];
}

export function calculateLevelCoins(perf: LevelPerformance): CoinBreakdown {
  const cfg = GameEconomyConfig;
  const txns: CoinTransaction[] = [];

  // Base coins
  let base = perf.levelNumber * cfg.baseCoinsPerLevelMultiplier;
  if (perf.isReplay) {
    base = Math.floor(base * cfg.replayBaseMultiplier);
  }
  txns.push({ amount: base, reason: 'levelBase', label: 'Base Reward' });

  // Star bonus
  let starBonus = 0;
  if (!perf.isReplay && perf.stars > 0) {
    starBonus = cfg.starBonus[perf.stars] || 0;
    if (starBonus > 0) {
      txns.push({ amount: starBonus, reason: 'starBonus', label: `${perf.stars}★ Bonus` });
    }
  }

  // Long word bonuses
  let longWordBonus = 0;
  for (const word of perf.wordsFound) {
    for (const lwb of cfg.longWordBonus) {
      if (word.length >= lwb.minLength) {
        longWordBonus += lwb.coins;
        break; // only highest tier per word
      }
    }
  }
  if (longWordBonus > 0) {
    txns.push({ amount: longWordBonus, reason: 'longWordBonus', label: 'Long Words' });
  }

  // Streak bonuses (highest milestone reached)
  let streakBonus = 0;
  for (const sb of cfg.streakBonus) {
    if (perf.maxStreakReached >= sb.threshold) {
      streakBonus = sb.coins;
      break; // highest first
    }
  }
  if (streakBonus > 0) {
    txns.push({ amount: streakBonus, reason: 'streakBonus', label: `Streak ${perf.maxStreakReached.toFixed(1)}x` });
  }

  // Cascade bonuses (highest milestone reached)
  let cascadeBonus = 0;
  for (const cb of cfg.cascadeBonus) {
    if (perf.maxCascadeReached >= cb.minCascade) {
      cascadeBonus = cb.coins;
      break;
    }
  }
  if (cascadeBonus > 0) {
    txns.push({ amount: cascadeBonus, reason: 'cascadeBonus', label: `Cascade ${perf.maxCascadeReached}+` });
  }

  // Efficiency bonuses
  let efficiencyBonus = 0;
  if (perf.goalType === 'scoreTimed' && perf.totalTime > 0) {
    const pctRemaining = perf.timeRemaining / perf.totalTime;
    if (pctRemaining >= cfg.timedEfficiencyThreshold) {
      efficiencyBonus = cfg.timedEfficiencyBonus;
      txns.push({ amount: efficiencyBonus, reason: 'efficiencyBonus', label: 'Time Efficiency' });
    }
  } else if (perf.goalType === 'clearIceMoves') {
    if (perf.movesRemaining >= cfg.moveEfficiencyThreshold) {
      efficiencyBonus = cfg.moveEfficiencyBonus;
      txns.push({ amount: efficiencyBonus, reason: 'efficiencyBonus', label: 'Move Efficiency' });
    }
  }

  // Apply anti-farming caps on performance bonuses
  let performanceTotal = longWordBonus + streakBonus + cascadeBonus + efficiencyBonus;
  if (perf.isReplay && performanceTotal > cfg.replayPerformanceCap) {
    const scale = cfg.replayPerformanceCap / performanceTotal;
    longWordBonus = Math.floor(longWordBonus * scale);
    streakBonus = Math.floor(streakBonus * scale);
    cascadeBonus = Math.floor(cascadeBonus * scale);
    efficiencyBonus = Math.floor(efficiencyBonus * scale);
    performanceTotal = longWordBonus + streakBonus + cascadeBonus + efficiencyBonus;
  }

  let total = base + starBonus + performanceTotal;
  if (total > cfg.maxCoinsPerLevel) {
    total = cfg.maxCoinsPerLevel;
  }

  return {
    base,
    starBonus,
    longWordBonus,
    streakBonus,
    cascadeBonus,
    efficiencyBonus,
    total,
    transactions: txns,
  };
}

// ---- Daily Login Manager ----

const DAILY_LOGIN_KEY = 'worddash_daily_login';

interface DailyLoginState {
  lastLoginDate: string; // YYYY-MM-DD
  currentStreak: number; // 0-6 (index into dailyRewards)
}

class DailyLoginManagerClass {
  private state: DailyLoginState;

  constructor() {
    this.state = this.load();
  }

  private load(): DailyLoginState {
    const stored = localStorage.getItem(DAILY_LOGIN_KEY);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch {
        // corrupted, reset
      }
    }
    return { lastLoginDate: '', currentStreak: 0 };
  }

  private save(): void {
    localStorage.setItem(DAILY_LOGIN_KEY, JSON.stringify(this.state));
  }

  private todayStr(): string {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  private yesterdayStr(): string {
    const d = new Date();
    d.setDate(d.getDate() - 1);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  /**
   * Check if the player can claim daily login reward today.
   * Returns the reward amount, or 0 if already claimed today.
   */
  checkDailyReward(): { canClaim: boolean; amount: number; day: number } {
    const today = this.todayStr();
    const cfg = GameEconomyConfig;

    if (this.state.lastLoginDate === today) {
      // Already claimed today
      return { canClaim: false, amount: 0, day: this.state.currentStreak + 1 };
    }

    // Determine streak
    let streak = this.state.currentStreak;
    if (this.state.lastLoginDate === this.yesterdayStr()) {
      // Consecutive day
      streak = (streak + 1) % cfg.dailyRewards.length;
    } else {
      // Missed a day, reset
      streak = 0;
    }

    const amount = cfg.dailyRewards[streak] || cfg.dailyRewards[0];
    return { canClaim: true, amount, day: streak + 1 };
  }

  /**
   * Claim the daily reward. Returns coins earned, or 0 if already claimed.
   */
  claimDailyReward(): number {
    const reward = this.checkDailyReward();
    if (!reward.canClaim) return 0;

    const today = this.todayStr();
    let streak = this.state.currentStreak;
    if (this.state.lastLoginDate === this.yesterdayStr()) {
      streak = (streak + 1) % GameEconomyConfig.dailyRewards.length;
    } else {
      streak = 0;
    }

    this.state.lastLoginDate = today;
    this.state.currentStreak = streak;
    this.save();

    CoinManager.addCoins(reward.amount, 'dailyLogin');
    return reward.amount;
  }

  getCurrentStreak(): number {
    return this.state.currentStreak + 1;
  }

  getDailyRewards(): number[] {
    return GameEconomyConfig.dailyRewards;
  }
}

export const DailyLoginManager = new DailyLoginManagerClass();

// ---- Continue System ----

export interface ContinueSession {
  continueCount: number;
  adContinueUsed: boolean;
}

export function createContinueSession(): ContinueSession {
  return { continueCount: 0, adContinueUsed: false };
}

export function getContinueCost(session: ContinueSession): number | null {
  const cfg = GameEconomyConfig;
  if (session.continueCount >= cfg.maxContinuesPerSession) return null;
  return cfg.continueCosts[session.continueCount] || cfg.continueCosts[cfg.continueCosts.length - 1];
}

export function canContinueWithCoins(session: ContinueSession): boolean {
  const cost = getContinueCost(session);
  if (cost === null) return false;
  return CoinManager.canAfford(cost);
}

export function continueWithCoins(session: ContinueSession): boolean {
  const cost = getContinueCost(session);
  if (cost === null) return false;
  if (!CoinManager.spendCoins(cost)) return false;
  session.continueCount++;
  return true;
}

export function canContinueWithAd(session: ContinueSession): boolean {
  if (session.adContinueUsed) return false;
  if (session.continueCount >= GameEconomyConfig.maxContinuesPerSession) return false;
  return true;
}

export function continueWithAd(session: ContinueSession): boolean {
  if (!canContinueWithAd(session)) return false;
  session.adContinueUsed = true;
  session.continueCount++;
  // Ad reward stub — in production, trigger ad here
  return true;
}

// ---- Powerup Store ----

const INVENTORY_STORAGE_KEY = 'worddash_powerup_inventory';

export interface PowerupInventory {
  hint: number;
  bomb: number;
  laser: number;
  crossLaser: number;
  mine: number;
}

export function loadInventory(): PowerupInventory {
  const stored = localStorage.getItem(INVENTORY_STORAGE_KEY);
  if (stored) {
    try {
      const parsed = JSON.parse(stored);
      return {
        hint: parsed.hint ?? 3,
        bomb: parsed.bomb ?? 2,
        laser: parsed.laser ?? 2,
        crossLaser: parsed.crossLaser ?? 1,
        mine: parsed.mine ?? 2,
      };
    } catch {
      // corrupted
    }
  }
  // Default starting inventory
  return { hint: 3, bomb: 2, laser: 2, crossLaser: 1, mine: 2 };
}

export function saveInventory(inv: PowerupInventory): void {
  localStorage.setItem(INVENTORY_STORAGE_KEY, JSON.stringify(inv));
}

export function purchasePowerup(type: keyof PowerupInventory): boolean {
  const cost = GameEconomyConfig.storePrices[type];
  if (!cost) return false;
  if (!CoinManager.spendCoins(cost)) return false;
  const inv = loadInventory();
  inv[type]++;
  saveInventory(inv);
  return true;
}
