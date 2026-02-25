/**
 * WordDash — "Midnight Glass" Premium Dark UI
 * Main game page with coin economy, store, continue system, daily login, and all game screens.
 */
import { useState, useEffect, useRef, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import GameBoard from '@/components/GameBoard';
import {
  createGameState,
  LEVELS,
  loadWordList,
  useShuffle,
  useBombPowerUp,
  useLaserPowerUp,
  useCrossLaserPowerUp,
  useMinePowerUp,
  useHintPowerUp,
  type GameState,
  type LevelConfig,
} from '@/lib/gameEngine';
import {
  CoinManager,
  DailyLoginManager,
  GameEconomyConfig,
  calculateLevelCoins,
  loadInventory,
  saveInventory,
  purchasePowerup,
  createContinueSession,
  getContinueCost,
  canContinueWithCoins,
  continueWithCoins,
  canContinueWithAd,
  continueWithAd,
  type CoinBreakdown,
  type ContinueSession,
  type PowerupInventory,
} from '@/lib/economy';
import { motion, AnimatePresence } from 'framer-motion';
import { toast } from 'sonner';

const BG_URL = 'https://private-us-east-1.manuscdn.com/sessionFile/SLncvH8jfLBUJFhJyzxsVd/sandbox/5W0yPyMY9zoRERJvmzw3Nf-img-1_1771961155000_na1fn_d29yZGRhc2gtYmc.png?x-oss-process=image/resize,w_1920,h_1920/format,webp/quality,q_80&Expires=1798761600&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9wcml2YXRlLXVzLWVhc3QtMS5tYW51c2Nkbi5jb20vc2Vzc2lvbkZpbGUvU0xuY3ZIOGpmTEJVSkZoSnl6eHNWZC9zYW5kYm94LzVXMHlQeU1ZOXpvUkVSSnZtenczTmYtaW1nLTFfMTc3MTk2MTE1NTAwMF9uYTFmbl9kMjl5WkdSaGMyZ3RZbWMucG5nP3gtb3NzLXByb2Nlc3M9aW1hZ2UvcmVzaXplLHdfMTkyMCxoXzE5MjAvZm9ybWF0LHdlYnAvcXVhbGl0eSxxXzgwIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoxNzk4NzYxNjAwfX19XX0_&Key-Pair-Id=K2HSFNDJXOU9YS&Signature=WSet-d934Y64HeIMczBFxJgACfg5RGuoiLWvl7ZzfWMHJo7mEbOLK10F9XwvLfdpByU0thYA~ZgpPY8ZcfCxobJpdWREtjILrEBiKuPSr58LPGZgb6z-tEn~VUUrTxWTKSVud6~hexXyjWS~ibDGP39~04wa4id8l~LrFpsL6v-VnhU0b131hc96oYlHNdHb4bNqw0WRjdAur6y1ZiGpVN6-TbfZbJwIY30Evfv9-nsgYDVeJreFu~vXJI0B~crh6oxyIa-QN7RRwE-SB6rhZDfHHcKICiIfqhoP9nHnptEMT0YAqKJIloOsVv5l5mRj~PDtWIXh09KKbm0wYW9XJg__';

const TILES_URL = 'https://private-us-east-1.manuscdn.com/sessionFile/SLncvH8jfLBUJFhJyzxsVd/sandbox/5W0yPyMY9zoRERJvmzw3Nf-img-3_1771961159000_na1fn_d29yZGRhc2gtdGlsZXMtaGVybw.png?x-oss-process=image/resize,w_1920,h_1920/format,webp/quality,q_80&Expires=1798761600&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9wcml2YXRlLXVzLWVhc3QtMS5tYW51c2Nkbi5jb20vc2Vzc2lvbkZpbGUvU0xuY3ZIOGpmTEJVSkZoSnl6eHNWZC9zYW5kYm94LzVXMHlQeU1ZOXpvUkVSSnZtenczTmYtaW1nLTNfMTc3MTk2MTE1OTAwMF9uYTFmbl9kMjl5WkdSaGMyZ3RkR2xzWlhNdGFHVnlidy5wbmc~eC1vc3MtcHJvY2Vzcz1pbWFnZS9yZXNpemUsd18xOTIwLGhfMTkyMC9mb3JtYXQsd2VicC9xdWFsaXR5LHFfODAiLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE3OTg3NjE2MDB9fX1dfQ__&Key-Pair-Id=K2HSFNDJXOU9YS&Signature=Hk2p4vpvKgZsp8hQpLuPSENPDP9bGmjFt5cXZsKHXaGGPdFchTvE07Tlyq4lB8k~J8--O-N5Q5LRJPxWH7PuJfTyGpoa06QlbdgUFuPuURC4uP2v0wSv-05iZ35HbwY~UW08PXlMV3RTSK4YtBkeq~X1GvB6UQr7VgQuEYHssVE8KsUbzVZq61xc81OZS3aSDYF2fkZ6jSbEEdkcxxWkKx6TOhyr8dW9VEHgfyyqdEf0tw5Hz0RBlKEFbBNSNWJlmWD1DGT1zNneNCO7xQEpQFCwzDgCWpjsRSVlVQLOyyZmVOUz4q6IKgFobT5b-3ojn97WH3CFD5wlbdzQH56ABg__';

type Screen = 'menu' | 'levels' | 'game' | 'result' | 'store' | 'continue';

// --- Coin display with animated changes ---
function CoinDisplay({ size = 'md', className = '' }: { size?: 'sm' | 'md' | 'lg'; className?: string }) {
  const [coins, setCoins] = useState(CoinManager.balance);
  const [flash, setFlash] = useState(false);

  useEffect(() => {
    const unsub = CoinManager.onBalanceChange((bal) => {
      setCoins(bal);
      setFlash(true);
      setTimeout(() => setFlash(false), 600);
    });
    setCoins(CoinManager.balance);
    return unsub;
  }, []);

  const sizeClasses = {
    sm: 'text-xs px-2 py-0.5',
    md: 'text-sm px-3 py-1',
    lg: 'text-base px-4 py-1.5',
  };

  return (
    <motion.div
      animate={flash ? { scale: [1, 1.15, 1] } : {}}
      transition={{ duration: 0.4 }}
      className={`inline-flex items-center gap-1.5 rounded-full border border-amber-500/30 bg-amber-500/10 backdrop-blur-sm ${sizeClasses[size]} ${className}`}
    >
      <span className="text-amber-400">🪙</span>
      <span className={`font-mono font-bold ${flash ? 'text-amber-300' : 'text-amber-400'} transition-colors`}>
        {coins.toLocaleString()}
      </span>
    </motion.div>
  );
}

export default function Home() {
  const [screen, setScreen] = useState<Screen>('menu');
  const [gameState, setGameState] = useState<GameState | null>(null);
  const [selectedLevel, setSelectedLevel] = useState<LevelConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [bestScores, setBestScores] = useState<Record<number, { score: number; stars: number }>>({});
  const [coinBreakdown, setCoinBreakdown] = useState<CoinBreakdown | null>(null);
  const [continueSession, setContinueSession] = useState<ContinueSession>(createContinueSession());
  const [dailyRewardShown, setDailyRewardShown] = useState(false);
  const [dailyRewardAmount, setDailyRewardAmount] = useState(0);
  const [dailyRewardDay, setDailyRewardDay] = useState(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Load word list on mount + check daily login
  useEffect(() => {
    loadWordList().then(() => setLoading(false));
    try {
      const saved = localStorage.getItem('worddash_progress');
      if (saved) setBestScores(JSON.parse(saved));
    } catch {}

    // Check daily login reward
    const reward = DailyLoginManager.checkDailyReward();
    if (reward.canClaim) {
      setDailyRewardAmount(reward.amount);
      setDailyRewardDay(reward.day);
      setDailyRewardShown(true);
    }
  }, []);

  // Timer for timed levels
  useEffect(() => {
    if (screen === 'game' && gameState && gameState.level.goalType === 'scoreTimed' && !gameState.isGameOver) {
      timerRef.current = setInterval(() => {
        setGameState(prev => {
          if (!prev || prev.isGameOver || !prev.timerStarted) return prev;
          const next = { ...prev, timeRemaining: prev.timeRemaining - 1 };
          if (next.timeRemaining <= 0) {
            next.timeRemaining = 0;
            if (!next.isWon) {
              next.isGameOver = true;
              next.stars = 0;
            }
          }
          return next;
        });
      }, 1000);
    }
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [screen, gameState?.isGameOver, gameState?.level.goalType]);

  // Handle game over transition
  useEffect(() => {
    if (gameState?.isGameOver && screen === 'game') {
      if (timerRef.current) clearInterval(timerRef.current);
      if (gameState.isWon) {
        // Calculate and award coins
        const lvl = gameState.level.levelNumber;
        const current = bestScores[lvl];
        const isReplay = !!current;
        const breakdown = calculateLevelCoins({
          levelNumber: lvl,
          stars: gameState.stars,
          wordsFound: gameState.wordsFound,
          maxStreakReached: gameState.maxStreakReached,
          maxCascadeReached: gameState.maxCascadeReached,
          timeRemaining: gameState.timeRemaining,
          totalTime: gameState.level.timeLimitSeconds || 0,
          movesRemaining: gameState.movesRemaining,
          goalType: gameState.level.goalType,
          isReplay,
        });
        setCoinBreakdown(breakdown);
        CoinManager.addCoins(breakdown.total, 'levelBase');

        // Save power-up inventory
        saveInventory({
          hint: gameState.powerUps.hint,
          bomb: gameState.powerUps.bomb,
          laser: gameState.powerUps.laser,
          crossLaser: gameState.powerUps.crossLaser,
          mine: gameState.powerUps.mine,
        });

        if (!current || gameState.score > current.score || gameState.stars > current.stars) {
          const updated = {
            ...bestScores,
            [lvl]: { score: Math.max(gameState.score, current?.score || 0), stars: Math.max(gameState.stars, current?.stars || 0) },
          };
          setBestScores(updated);
          localStorage.setItem('worddash_progress', JSON.stringify(updated));
        }
        setTimeout(() => setScreen('result'), 800);
      } else {
        // Level failed — show continue modal
        setCoinBreakdown(null);
        setTimeout(() => setScreen('continue'), 800);
      }
    }
  }, [gameState?.isGameOver]);

  const startLevel = useCallback((level: LevelConfig) => {
    setSelectedLevel(level);
    const state = createGameState(level);
    // Load persisted power-up inventory
    const inv = loadInventory();
    state.powerUps.hint = inv.hint;
    state.powerUps.bomb = inv.bomb;
    state.powerUps.laser = inv.laser;
    state.powerUps.crossLaser = inv.crossLaser;
    state.powerUps.mine = inv.mine;
    setGameState(state);
    setContinueSession(createContinueSession());
    setScreen('game');
  }, []);

  const handleWordSubmitted = useCallback((word: string, score: number, valid: boolean) => {
    if (valid) {
      toast.success(`"${word}" +${score}`, { duration: 1500 });
    } else if (word.length >= 3) {
      toast.error(`"${word}" not in dictionary`, { duration: 1200 });
    }
  }, []);

  const handleStateChange = useCallback((state: GameState) => {
    setGameState({ ...state });
  }, []);

  const handleNextLevel = useCallback(() => {
    if (!selectedLevel) return;
    const nextIdx = LEVELS.findIndex(l => l.levelNumber === selectedLevel.levelNumber + 1);
    if (nextIdx >= 0) {
      startLevel(LEVELS[nextIdx]);
    } else {
      setScreen('levels');
    }
  }, [selectedLevel, startLevel]);

  const handleContinue = useCallback((method: 'coins' | 'ad') => {
    if (!gameState || !selectedLevel) return;
    let success = false;
    if (method === 'coins') {
      success = continueWithCoins(continueSession);
    } else {
      success = continueWithAd(continueSession);
    }
    if (!success) {
      toast.error('Not enough coins!');
      return;
    }
    // Resume the level
    const isTimedLevel = gameState.level.goalType === 'scoreTimed';
    const updated = { ...gameState, isGameOver: false };
    if (isTimedLevel) {
      updated.timeRemaining += GameEconomyConfig.continueTimedBonus;
    } else {
      updated.movesRemaining += GameEconomyConfig.continueMoveBonus;
    }
    setGameState(updated);
    setScreen('game');
  }, [gameState, selectedLevel, continueSession]);

  const claimDailyReward = useCallback(() => {
    const amount = DailyLoginManager.claimDailyReward();
    if (amount > 0) {
      toast.success(`Daily reward: +${amount} coins!`, { duration: 2000 });
    }
    setDailyRewardShown(false);
  }, []);

  // --- Screens ---
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: '#0a0e27' }}>
        <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="text-center">
          <div className="w-12 h-12 border-2 border-emerald-400 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-white/60 font-medium">Loading dictionary...</p>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen relative overflow-hidden" style={{ background: 'linear-gradient(135deg, #0a0e27 0%, #1a1040 50%, #0d1530 100%)' }}>
      <div className="absolute inset-0 opacity-30" style={{ backgroundImage: `url(${BG_URL})`, backgroundSize: 'cover', backgroundPosition: 'center' }} />
      <div className="relative z-10">
        {/* Daily Login Reward Modal */}
        <AnimatePresence>
          {dailyRewardShown && (
            <DailyLoginModal day={dailyRewardDay} amount={dailyRewardAmount} onClaim={claimDailyReward} />
          )}
        </AnimatePresence>

        <AnimatePresence mode="wait">
          {screen === 'menu' && <MenuScreen key="menu" onPlay={() => setScreen('levels')} onStore={() => setScreen('store')} />}
          {screen === 'store' && <StoreScreen key="store" onBack={() => setScreen('menu')} />}
          {screen === 'levels' && (
            <LevelSelectScreen key="levels" onBack={() => setScreen('menu')} onSelectLevel={startLevel} bestScores={bestScores} />
          )}
          {screen === 'game' && gameState && (
            <GameScreen
              key="game"
              gameState={gameState}
              onStateChange={handleStateChange}
              onWordSubmitted={handleWordSubmitted}
              onQuit={() => { if (timerRef.current) clearInterval(timerRef.current); saveInventory({ hint: gameState.powerUps.hint, bomb: gameState.powerUps.bomb, laser: gameState.powerUps.laser, crossLaser: gameState.powerUps.crossLaser, mine: gameState.powerUps.mine }); setScreen('levels'); }}
            />
          )}
          {screen === 'result' && gameState && (
            <ResultScreen
              key="result"
              gameState={gameState}
              coinBreakdown={coinBreakdown}
              onReplay={() => selectedLevel && startLevel(selectedLevel)}
              onLevels={() => setScreen('levels')}
              onNextLevel={handleNextLevel}
              hasNextLevel={!!selectedLevel && selectedLevel.levelNumber < LEVELS.length}
            />
          )}
          {screen === 'continue' && gameState && (
            <ContinueScreen
              key="continue"
              gameState={gameState}
              session={continueSession}
              onContinue={handleContinue}
              onRetry={() => selectedLevel && startLevel(selectedLevel)}
              onLevels={() => setScreen('levels')}
              onStore={() => setScreen('store')}
            />
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

// --- Daily Login Modal ---
function DailyLoginModal({ day, amount, onClaim }: { day: number; amount: number; onClaim: () => void }) {
  const rewards = GameEconomyConfig.dailyRewards;
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm px-4"
    >
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.8, opacity: 0 }}
        className="w-full max-w-sm p-6 rounded-2xl border border-amber-500/20 bg-gradient-to-b from-[#1a1040] to-[#0d1530] text-center"
      >
        <div className="text-3xl mb-2">🎁</div>
        <h2 className="text-xl font-bold text-white mb-1">Daily Login Reward</h2>
        <p className="text-white/50 text-sm mb-4">Day {day} of 7</p>

        <div className="flex justify-center gap-1.5 mb-4">
          {rewards.map((r, i) => (
            <div
              key={i}
              className={`flex flex-col items-center px-2 py-1.5 rounded-lg text-[10px] ${
                i + 1 === day
                  ? 'bg-amber-500/20 border border-amber-500/40 text-amber-300 font-bold'
                  : i + 1 < day
                  ? 'bg-white/5 text-white/30 line-through'
                  : 'bg-white/5 text-white/40'
              }`}
            >
              <span>D{i + 1}</span>
              <span className="text-amber-400 font-mono">{r}</span>
            </div>
          ))}
        </div>

        <div className="text-2xl font-bold text-amber-400 mb-4">
          <span className="text-amber-300">+{amount}</span> 🪙
        </div>

        <Button onClick={onClaim} className="w-full bg-amber-500 hover:bg-amber-400 text-black font-bold rounded-xl">
          Claim Reward
        </Button>
      </motion.div>
    </motion.div>
  );
}

// --- Menu Screen ---
function MenuScreen({ onPlay, onStore }: { onPlay: () => void; onStore: () => void }) {
  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="min-h-screen flex flex-col items-center justify-center px-4">
      <div className="absolute top-4 right-4">
        <CoinDisplay size="md" />
      </div>
      <motion.h1
        className="text-5xl md:text-7xl font-bold mb-2 drop-shadow-2xl"
        style={{
          background: 'linear-gradient(135deg, #10b981 0%, #34d399 30%, #fbbf24 60%, #f59e0b 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          fontFamily: "'Space Grotesk', sans-serif",
          letterSpacing: '-0.02em',
        }}
        initial={{ y: -30, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1, type: 'spring', stiffness: 100 }}
      >
        WordDash
      </motion.h1>
      <motion.img src={TILES_URL} alt="Floating tiles" className="w-80 md:w-[28rem] mb-8 opacity-80" initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 0.8 }} transition={{ delay: 0.3 }} />
      <motion.div initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.5 }} className="flex gap-4">
        <Button onClick={onPlay} size="lg" className="text-lg px-12 py-6 bg-emerald-500 hover:bg-emerald-400 text-white font-bold rounded-xl shadow-lg shadow-emerald-500/30 transition-all hover:shadow-emerald-400/40 hover:scale-105">
          Play
        </Button>
        <Button onClick={onStore} size="lg" variant="outline" className="text-lg px-8 py-6 border-amber-500/30 text-amber-400 hover:bg-amber-500/10 hover:text-amber-300 font-bold rounded-xl transition-all hover:scale-105">
          🛒 Store
        </Button>
      </motion.div>
      <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.7 }} className="mt-6 text-white/30 text-sm">
        Drag across tiles to form words. Longer words earn special tiles!
      </motion.p>
    </motion.div>
  );
}

// --- Store Screen ---
function StoreScreen({ onBack }: { onBack: () => void }) {
  const [inventory, setInventory] = useState<PowerupInventory>(loadInventory());
  const [, forceUpdate] = useState(0);

  const powerups = [
    { key: 'hint' as const, icon: '💡', name: 'Hint', desc: 'Highlights a valid word on the board', cost: GameEconomyConfig.storePrices.hint },
    { key: 'bomb' as const, icon: '💣', name: 'Bomb', desc: 'Places a bomb tile that clears 3×3', cost: GameEconomyConfig.storePrices.bomb },
    { key: 'laser' as const, icon: '⚡', name: 'Laser', desc: 'Places a laser tile that clears a row or column', cost: GameEconomyConfig.storePrices.laser },
    { key: 'crossLaser' as const, icon: '✦', name: 'Cross Laser', desc: 'Places a cross laser that clears row + column', cost: GameEconomyConfig.storePrices.crossLaser },
    { key: 'mine' as const, icon: '💥', name: 'Mine', desc: 'Places a mine that detonates on clear', cost: GameEconomyConfig.storePrices.mine },
  ];

  const handlePurchase = (key: keyof PowerupInventory) => {
    const success = purchasePowerup(key);
    if (success) {
      setInventory(loadInventory());
      forceUpdate(n => n + 1);
      toast.success(`Purchased ${key}!`);
    } else {
      toast.error('Not enough coins!');
    }
  };

  return (
    <motion.div initial={{ opacity: 0, x: 50 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -50 }} className="min-h-screen px-4 py-8">
      <div className="max-w-lg mx-auto">
        <div className="flex items-center justify-between mb-6">
          <Button variant="ghost" onClick={onBack} className="text-white/60 hover:text-white">← Back</Button>
          <h2 className="text-xl font-bold text-white">Power-Up Store</h2>
          <CoinDisplay size="sm" />
        </div>

        <div className="space-y-3">
          {powerups.map((pu) => {
            const owned = inventory[pu.key];
            const affordable = CoinManager.canAfford(pu.cost);
            return (
              <motion.div
                key={pu.key}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="flex items-center gap-4 p-4 rounded-xl border border-white/10 bg-white/5 backdrop-blur-sm"
              >
                <div className="text-3xl w-12 text-center">{pu.icon}</div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-white font-bold">{pu.name}</span>
                    <span className="text-xs px-2 py-0.5 rounded-full bg-white/10 text-white/50 font-mono">×{owned}</span>
                  </div>
                  <p className="text-xs text-white/40 mt-0.5">{pu.desc}</p>
                </div>
                <Button
                  onClick={() => handlePurchase(pu.key)}
                  disabled={!affordable}
                  size="sm"
                  className={`rounded-lg font-bold ${
                    affordable
                      ? 'bg-amber-500 hover:bg-amber-400 text-black'
                      : 'bg-white/10 text-white/30 cursor-not-allowed'
                  }`}
                >
                  🪙 {pu.cost}
                </Button>
              </motion.div>
            );
          })}
        </div>
      </div>
    </motion.div>
  );
}

// --- Level Select ---
function LevelSelectScreen({ onBack, onSelectLevel, bestScores }: {
  onBack: () => void;
  onSelectLevel: (level: LevelConfig) => void;
  bestScores: Record<number, { score: number; stars: number }>;
}) {
  return (
    <motion.div initial={{ opacity: 0, x: 50 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -50 }} className="min-h-screen px-4 py-8">
      <div className="max-w-lg mx-auto">
        <div className="flex items-center justify-between mb-8">
          <Button variant="ghost" onClick={onBack} className="text-white/60 hover:text-white">← Back</Button>
          <h2 className="text-xl font-bold text-white">Select Level</h2>
          <CoinDisplay size="sm" />
        </div>
        <div className="grid grid-cols-2 gap-4">
          {LEVELS.map((level) => {
            const best = bestScores[level.levelNumber];
            const prevBest = bestScores[level.levelNumber - 1];
            const isUnlocked = level.levelNumber === 1 || !!prevBest;
            return (
              <motion.button
                key={level.levelNumber}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: level.levelNumber * 0.05 }}
                onClick={() => isUnlocked && onSelectLevel(level)}
                disabled={!isUnlocked}
                className={`relative p-5 rounded-xl border transition-all ${
                  isUnlocked
                    ? 'border-white/10 bg-white/5 backdrop-blur-sm hover:bg-white/10 hover:border-emerald-500/30 hover:shadow-lg hover:shadow-emerald-500/10'
                    : 'border-white/5 bg-white/[0.02] opacity-40 cursor-not-allowed'
                }`}
              >
                <div className="text-2xl font-bold text-white mb-1">{level.levelNumber}</div>
                <div className="text-xs text-white/40 mb-2">
                  {level.goalType === 'scoreTimed' ? `Score ${level.targetScore}` : `Clear ${level.iceTilesToClearTarget} ice`}
                </div>
                <div className="flex gap-1 justify-center">
                  {[1, 2, 3].map(s => (
                    <span key={s} className={`text-sm ${best && best.stars >= s ? 'text-amber-400' : 'text-white/15'}`}>★</span>
                  ))}
                </div>
                {best && <div className="text-[10px] text-white/30 mt-1 font-mono">Best: {best.score}</div>}
                {!isUnlocked && (
                  <div className="absolute inset-0 flex items-center justify-center"><span className="text-2xl">🔒</span></div>
                )}
              </motion.button>
            );
          })}
        </div>
      </div>
    </motion.div>
  );
}

// --- Game Screen ---
function GameScreen({ gameState, onStateChange, onWordSubmitted, onQuit }: {
  gameState: GameState;
  onStateChange: (state: GameState) => void;
  onWordSubmitted: (word: string, score: number, valid: boolean) => void;
  onQuit: () => void;
}) {
  const level = gameState.level;
  const isTimedLevel = level.goalType === 'scoreTimed';

  const progressPercent = isTimedLevel
    ? (gameState.score / (level.targetScore || 1)) * 100
    : (gameState.iceCleared / Math.max(gameState.totalIce, 1)) * 100;

  const formatTime = (s: number) => {
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return `${m}:${sec.toString().padStart(2, '0')}`;
  };

  const activatePowerUp = (name: string) => {
    if (name === 'shuffle') {
      useShuffle(gameState);
      onStateChange({ ...gameState });
      toast.info('Board shuffled!');
      return;
    }
    if (name === 'hint') {
      useHintPowerUp(gameState);
      onStateChange({ ...gameState });
      if (gameState.hintPath.length > 0) {
        toast.info(`Hint: "${gameState.hintPath.map(t => t.letter).join('')}"`, { duration: 3000 });
      } else {
        toast.error('No valid words found!');
      }
      return;
    }
    const placementFns: Record<string, (s: GameState) => void> = {
      bomb: useBombPowerUp,
      laser: useLaserPowerUp,
      crossLaser: useCrossLaserPowerUp,
      mine: useMinePowerUp,
    };
    const fn = placementFns[name];
    if (fn) {
      fn(gameState);
      onStateChange({ ...gameState });
      const labels: Record<string, string> = {
        bomb: '💣 Bomb placed on a random tile!',
        laser: '⚡ Laser placed on a random tile!',
        crossLaser: '✦ Cross Laser placed on a random tile!',
        mine: '💥 Mine placed on a random tile!',
      };
      toast.info(labels[name] || 'Power-up placed!');
    }
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="min-h-screen px-3 py-4 flex flex-col">
      {/* Top HUD */}
      <div className="max-w-[560px] mx-auto w-full mb-3">
        <div className="flex items-center justify-between mb-2">
          <Button variant="ghost" size="sm" onClick={onQuit} className="text-white/50 hover:text-white text-xs px-2">✕ Quit</Button>
          <div className="text-center">
            <div className="text-xs text-white/40">Level {level.levelNumber}</div>
            <div className="text-xs text-white/30">
              {isTimedLevel ? `Score ${level.targetScore}` : `Clear ${level.iceTilesToClearTarget} ice`}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <CoinDisplay size="sm" />
            {isTimedLevel ? (
              <div className={`font-mono text-sm font-bold ${gameState.timeRemaining <= 10 && gameState.timerStarted ? 'text-red-400 animate-pulse' : 'text-white/70'}`}>
                {formatTime(gameState.timeRemaining)}
                {!gameState.timerStarted && <span className="text-[9px] text-white/30 block">starts on play</span>}
              </div>
            ) : (
              <div className="font-mono text-sm text-white/70">
                <span className={gameState.movesRemaining <= 3 ? 'text-red-400 font-bold' : ''}>{gameState.movesRemaining}</span> moves
              </div>
            )}
          </div>
        </div>

        {/* Score bar */}
        <div className="relative mb-2">
          <Progress value={Math.min(100, progressPercent)} className="h-2 bg-white/5" />
          <div className="flex justify-between mt-1">
            <span className="text-xs font-mono text-emerald-400 font-bold">{gameState.score}</span>
            {gameState.coinsEarnedThisLevel > 0 && (
              <motion.span
                key={gameState.coinsEarnedThisLevel}
                initial={{ scale: 1.4, color: '#fbbf24' }}
                animate={{ scale: 1, color: '#f59e0b' }}
                className="text-xs font-mono font-bold"
              >
                🪙 +{gameState.coinsEarnedThisLevel}
              </motion.span>
            )}
            {gameState.streakMultiplier > 1 && (
              <motion.span initial={{ scale: 1.3 }} animate={{ scale: 1 }} className="text-xs text-amber-400 font-bold">
                🔥 Streak ×{gameState.streakMultiplier.toFixed(1)}
              </motion.span>
            )}
            {!isTimedLevel && (
              <span className="text-xs text-cyan-300">❄ {gameState.iceCleared}/{gameState.totalIce}</span>
            )}
          </div>
        </div>
      </div>

      {/* Word popup */}
      <AnimatePresence>
        {gameState.showWordPopup && (
          <motion.div initial={{ opacity: 0, y: 10, scale: 0.9 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: -10 }} className="text-center mb-2">
            <span className="text-emerald-400 font-bold text-lg">{gameState.lastWord}</span>
            <span className="text-amber-400 font-mono ml-2">+{gameState.lastWordScore}</span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Game Board */}
      <div className="flex-1 flex items-start justify-center">
        <GameBoard gameState={gameState} onStateChange={onStateChange} onWordSubmitted={onWordSubmitted} />
      </div>

      {/* Power-ups bar */}
      <div className="max-w-[560px] mx-auto w-full mt-3">
        <div className="flex justify-center gap-2 flex-wrap">
          <PowerUpButton icon="💡" label="Hint" count={gameState.powerUps.hint} onClick={() => activatePowerUp('hint')} />
          <PowerUpButton icon="🔀" label="Shuffle" count={gameState.powerUps.shuffle} onClick={() => activatePowerUp('shuffle')} />
          <PowerUpButton icon="💣" label="Bomb" count={gameState.powerUps.bomb} onClick={() => activatePowerUp('bomb')} />
          <PowerUpButton icon="⚡" label="Laser" count={gameState.powerUps.laser} onClick={() => activatePowerUp('laser')} />
          <PowerUpButton icon="✦" label="Cross" count={gameState.powerUps.crossLaser} onClick={() => activatePowerUp('crossLaser')} />
          <PowerUpButton icon="💥" label="Mine" count={gameState.powerUps.mine} onClick={() => activatePowerUp('mine')} />
        </div>

        {/* Words found */}
        {gameState.wordsFound.length > 0 && (
          <div className="mt-3 flex flex-wrap gap-1.5 justify-center max-h-16 overflow-y-auto">
            {gameState.wordsFound.slice(-12).map((w, i) => (
              <span key={`${w}-${i}`} className="text-[10px] px-2 py-0.5 rounded-full bg-white/5 text-white/40 font-mono">{w}</span>
            ))}
          </div>
        )}
      </div>
    </motion.div>
  );
}

// --- Power-up Button ---
function PowerUpButton({ icon, label, count, onClick }: {
  icon: string; label: string; count: number; onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      disabled={count <= 0}
      className={`relative flex flex-col items-center gap-0.5 px-3 py-2 rounded-xl border transition-all ${
        count > 0
          ? 'border-white/10 bg-white/5 hover:bg-white/10 hover:scale-105'
          : 'border-white/5 bg-white/[0.02] opacity-30 cursor-not-allowed'
      }`}
    >
      <span className="text-lg">{icon}</span>
      <span className="text-[9px] text-white/50">{label}</span>
      <span className="absolute -top-1 -right-1 bg-white/10 text-white/70 text-[10px] font-mono w-4 h-4 rounded-full flex items-center justify-center">
        {count}
      </span>
    </button>
  );
}

// --- Continue Screen (on level failure) ---
function ContinueScreen({ gameState, session, onContinue, onRetry, onLevels, onStore }: {
  gameState: GameState;
  session: ContinueSession;
  onContinue: (method: 'coins' | 'ad') => void;
  onRetry: () => void;
  onLevels: () => void;
  onStore: () => void;
}) {
  const isIceLevel = gameState.level.goalType === 'clearIceMoves';
  const failureMessage = isIceLevel ? 'Out of Moves!' : "Time's Up!";
  const cost = getContinueCost(session);
  const canAfford = cost !== null && canContinueWithCoins(session);
  const canAd = canContinueWithAd(session);
  const continueBonus = isIceLevel
    ? `+${GameEconomyConfig.continueMoveBonus} moves`
    : `+${GameEconomyConfig.continueTimedBonus}s (1 min)`;
  const maxedOut = cost === null;
  const coinsAtRisk = gameState.coinsEarnedThisLevel;

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="min-h-screen flex items-center justify-center px-4">
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: 'spring', stiffness: 120 }}
        className="w-full max-w-sm p-8 rounded-2xl border border-white/10 bg-white/5 backdrop-blur-xl text-center"
      >
        <div className="text-4xl mb-3">😔</div>
        <h2 className="text-2xl font-bold text-white mb-2">{failureMessage}</h2>
        <div className="flex justify-center gap-4 mb-4">
          <div className="text-center">
            <div className="text-white/40 text-[10px] uppercase tracking-wider">Score</div>
            <div className="text-white font-mono font-bold">{gameState.score}</div>
          </div>
          <div className="text-center">
            <div className="text-white/40 text-[10px] uppercase tracking-wider">Words</div>
            <div className="text-white font-mono font-bold">{gameState.wordsFound.length}</div>
          </div>
          <div className="text-center">
            <div className="text-amber-400/60 text-[10px] uppercase tracking-wider">Coins Earned</div>
            <div className="text-amber-400 font-mono font-bold">🪙 {coinsAtRisk}</div>
          </div>
        </div>

        {!maxedOut && (
          <div className="mb-4 space-y-2">
            <p className="text-white/50 text-xs mb-1">Continue? ({continueBonus}) — attempt {session.continueCount + 1}/{GameEconomyConfig.maxContinuesPerSession}</p>

            {/* Watch Ad option */}
            {canAd && (
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => onContinue('ad')}
                className="w-full p-3 rounded-xl border border-emerald-500/30 bg-emerald-500/10 hover:bg-emerald-500/20 transition-all flex items-center justify-between"
              >
                <div className="flex items-center gap-2">
                  <span className="text-2xl">📺</span>
                  <div className="text-left">
                    <div className="text-emerald-400 font-bold text-sm">Watch Ad</div>
                    <div className="text-emerald-400/50 text-[10px]">Free continue</div>
                  </div>
                </div>
                <span className="text-emerald-400 font-bold text-sm">FREE</span>
              </motion.button>
            )}

            {/* Continue with Coins option */}
            <motion.button
              whileHover={canAfford ? { scale: 1.02 } : {}}
              whileTap={canAfford ? { scale: 0.98 } : {}}
              onClick={() => canAfford && onContinue('coins')}
              disabled={!canAfford}
              className={`w-full p-3 rounded-xl border transition-all flex items-center justify-between ${
                canAfford
                  ? 'border-amber-500/30 bg-amber-500/10 hover:bg-amber-500/20 cursor-pointer'
                  : 'border-white/5 bg-white/[0.02] opacity-40 cursor-not-allowed'
              }`}
            >
              <div className="flex items-center gap-2">
                <span className="text-2xl">🪙</span>
                <div className="text-left">
                  <div className={`font-bold text-sm ${canAfford ? 'text-amber-400' : 'text-white/30'}`}>Continue with Coins</div>
                  {!canAfford && <div className="text-white/20 text-[10px]">Not enough coins</div>}
                </div>
              </div>
              <span className={`font-bold font-mono text-sm ${canAfford ? 'text-amber-400' : 'text-white/30'}`}>{cost}</span>
            </motion.button>

            {!canAfford && cost !== null && (
              <button onClick={onStore} className="text-amber-400/70 text-xs underline hover:text-amber-300 transition-colors">
                Visit store to get more coins
              </button>
            )}
          </div>
        )}

        {maxedOut && (
          <p className="text-white/40 text-sm mb-4">Maximum continues reached</p>
        )}

        {/* Forfeit option */}
        <div className="mb-4 pt-3 border-t border-white/5">
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={onLevels}
            className="w-full p-3 rounded-xl border border-red-500/20 bg-red-500/5 hover:bg-red-500/10 transition-all flex items-center justify-between"
          >
            <div className="flex items-center gap-2">
              <span className="text-2xl">🚪</span>
              <div className="text-left">
                <div className="text-red-400 font-bold text-sm">Forfeit Level</div>
                <div className="text-red-400/50 text-[10px]">Return to level select</div>
              </div>
            </div>
            {coinsAtRisk > 0 && (
              <span className="text-red-400/80 font-mono text-xs font-bold">-{coinsAtRisk} 🪙</span>
            )}
          </motion.button>
        </div>

        {/* Retry button */}
        <Button onClick={onRetry} className="w-full bg-emerald-500 hover:bg-emerald-400 text-white font-bold rounded-xl">
          🔄 Retry Level
        </Button>
      </motion.div>
    </motion.div>
  );
}

// --- Result Screen ---
function ResultScreen({ gameState, coinBreakdown, onReplay, onLevels, onNextLevel, hasNextLevel }: {
  gameState: GameState;
  coinBreakdown: CoinBreakdown | null;
  onReplay: () => void;
  onLevels: () => void;
  onNextLevel: () => void;
  hasNextLevel: boolean;
}) {
  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="min-h-screen flex items-center justify-center px-4">
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: 'spring', stiffness: 120 }}
        className="w-full max-w-sm p-8 rounded-2xl border border-white/10 bg-white/5 backdrop-blur-xl text-center"
      >
        <div className="text-4xl mb-4">🎉</div>
        <h2 className="text-2xl font-bold text-white mb-2">Level Complete!</h2>

        {/* Stars */}
        <div className="flex justify-center gap-2 mb-4">
          {[1, 2, 3].map(s => (
            <motion.span
              key={s}
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{ delay: s * 0.2, type: 'spring' }}
              className={`text-3xl ${gameState.stars >= s ? 'text-amber-400' : 'text-white/15'}`}
            >★</motion.span>
          ))}
        </div>

        {/* Score summary */}
        <div className="space-y-1.5 mb-4">
          <div className="flex justify-between text-sm">
            <span className="text-white/50">Score</span>
            <span className="text-white font-mono font-bold">{gameState.score}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-white/50">Words Found</span>
            <span className="text-white font-mono">{gameState.wordsFound.length}</span>
          </div>
          {gameState.level.goalType === 'clearIceMoves' && (
            <div className="flex justify-between text-sm">
              <span className="text-white/50">Ice Cleared</span>
              <span className="text-white font-mono">{gameState.iceCleared}/{gameState.totalIce}</span>
            </div>
          )}
        </div>

        {/* Coin Breakdown */}
        {coinBreakdown && (
          <div className="mb-4 p-3 rounded-xl border border-amber-500/20 bg-amber-500/5">
            <h3 className="text-xs font-bold text-amber-400 mb-2 uppercase tracking-wider">Coins Earned</h3>
            <div className="space-y-1">
              {coinBreakdown.transactions.map((txn, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.8 + i * 0.15 }}
                  className="flex justify-between text-xs"
                >
                  <span className="text-white/50">{txn.label}</span>
                  <span className="text-amber-400 font-mono">+{txn.amount}</span>
                </motion.div>
              ))}
              <div className="border-t border-amber-500/20 pt-1 mt-1">
                <motion.div
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.8 + coinBreakdown.transactions.length * 0.15 }}
                  className="flex justify-between text-sm font-bold"
                >
                  <span className="text-amber-300">Total</span>
                  <span className="text-amber-300">🪙 +{coinBreakdown.total}</span>
                </motion.div>
              </div>
            </div>
          </div>
        )}

        <div className="flex gap-3">
          <Button onClick={onLevels} variant="outline" className="flex-1 border-white/10 text-white/70 hover:text-white hover:bg-white/10">
            Levels
          </Button>
          <Button onClick={onReplay} variant="outline" className="flex-1 border-white/10 text-white/70 hover:text-white hover:bg-white/10">
            Replay
          </Button>
          {hasNextLevel && (
            <Button onClick={onNextLevel} className="flex-1 bg-emerald-500 hover:bg-emerald-400 text-white font-bold">
              Next →
            </Button>
          )}
        </div>
      </motion.div>
    </motion.div>
  );
}
