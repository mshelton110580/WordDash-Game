// ============================================================
// WordDash Game Stats — Persistent Statistics Tracking
// Matches iOS GameStats + PersistenceManager stats methods
// ============================================================

const STATS_STORAGE_KEY = 'worddash_game_stats';

export interface GameStats {
  totalWordsFound: number;
  totalScore: number;
  levelsCompleted: number;
  bestStreak: number;        // max streak multiplier ever reached
  bestCascade: number;       // max cascade step ever reached
  longestWord: string;       // longest word ever found
  totalCoinsEarned: number;
  sessionsPlayed: number;
  lastPlayedDate: string;    // short date string
  levelBestTimes: Record<number, number>;   // level → seconds remaining
  levelBestScores: Record<number, number>;  // level → best score
  levelStars: Record<number, number>;       // level → stars (1–3)
}

function defaultStats(): GameStats {
  return {
    totalWordsFound: 0,
    totalScore: 0,
    levelsCompleted: 0,
    bestStreak: 1.0,
    bestCascade: 0,
    longestWord: '',
    totalCoinsEarned: 0,
    sessionsPlayed: 0,
    lastPlayedDate: '',
    levelBestTimes: {},
    levelBestScores: {},
    levelStars: {},
  };
}

class GameStatsManagerClass {
  private _stats: GameStats;

  constructor() {
    this._stats = this.load();
  }

  get stats(): GameStats {
    return { ...this._stats };
  }

  private load(): GameStats {
    try {
      const stored = localStorage.getItem(STATS_STORAGE_KEY);
      if (stored) {
        const parsed = JSON.parse(stored);
        return { ...defaultStats(), ...parsed };
      }
    } catch {}
    return defaultStats();
  }

  private save(): void {
    localStorage.setItem(STATS_STORAGE_KEY, JSON.stringify(this._stats));
  }

  /** Update stats after a level is completed (mirrors iOS updateStatsOnLevelComplete) */
  updateOnLevelComplete(params: {
    levelNumber: number;
    wordsFound: number;
    score: number;
    stars: number;
    maxStreak: number;
    maxCascade: number;
    timeRemaining: number;
    coinsEarned: number;
    longestWord: string;
  }): void {
    const s = this._stats;
    s.totalWordsFound += params.wordsFound;
    s.totalScore += params.score;
    s.levelsCompleted += 1;
    s.sessionsPlayed += 1;
    s.totalCoinsEarned += params.coinsEarned;

    if (params.maxStreak > s.bestStreak) s.bestStreak = params.maxStreak;
    if (params.maxCascade > s.bestCascade) s.bestCascade = params.maxCascade;
    if (params.longestWord.length > s.longestWord.length) s.longestWord = params.longestWord;

    // Per-level bests
    const prevTime = s.levelBestTimes[params.levelNumber] ?? -1;
    if (params.timeRemaining > prevTime) s.levelBestTimes[params.levelNumber] = params.timeRemaining;

    const prevScore = s.levelBestScores[params.levelNumber] ?? 0;
    if (params.score > prevScore) s.levelBestScores[params.levelNumber] = params.score;

    const prevStars = s.levelStars[params.levelNumber] ?? 0;
    if (params.stars > prevStars) s.levelStars[params.levelNumber] = params.stars;

    // Last played date
    s.lastPlayedDate = new Date().toLocaleDateString();

    this.save();
  }

  /** Increment sessions played (called when a level starts) */
  incrementSessions(): void {
    this._stats.sessionsPlayed += 1;
    this._stats.lastPlayedDate = new Date().toLocaleDateString();
    this.save();
  }

  /** Reset all stats */
  reset(): void {
    this._stats = defaultStats();
    this.save();
  }

  /** Reload from storage (useful after reset) */
  reload(): void {
    this._stats = this.load();
  }
}

export const GameStatsManager = new GameStatsManagerClass();
