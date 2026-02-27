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
  POWERUP_UNLOCK_LEVELS,
  loadWordList,
  useShuffle,
  useBombPowerUp,
  useLaserPowerUp,
  useCrossLaserPowerUp,
  useMinePowerUp,
  useHintPowerUp,
  useLinkPowerUp,
  loadUnlockedPowerups,
  saveUnlockedPowerups,
  getNewlyUnlockedPowerups,
  type GameState,
  type LevelConfig,
  type PowerupName,
  forceResolveChainOnTimer,
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
import { SoundEngine } from '@/lib/soundEngine';
import { GameStatsManager } from '@/lib/gameStats';
import { motion, AnimatePresence } from 'framer-motion';
import { toast } from 'sonner';

const TILES_URL = 'https://private-us-east-1.manuscdn.com/sessionFile/SLncvH8jfLBUJFhJyzxsVd/sandbox/5W0yPyMY9zoRERJvmzw3Nf-img-3_1771961159000_na1fn_d29yZGRhc2gtdGlsZXMtaGVybw.png?x-oss-process=image/resize,w_1920,h_1920/format,webp/quality,q_80&Expires=1798761600&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9wcml2YXRlLXVzLWVhc3QtMS5tYW51c2Nkbi5jb20vc2Vzc2lvbkZpbGUvU0xuY3ZIOGpmTEJVSkZoSnl6eHNWZC9zYW5kYm94LzVXMHlQeU1ZOXpvUkVSSnZtenczTmYtaW1nLTNfMTc3MTk2MTE1OTAwMF9uYTFmbl9kMjl5WkdSaGMyZ3RkR2xzWlhNdGFHVnlidy5wbmc~eC1vc3MtcHJvY2Vzcz1pbWFnZS9yZXNpemUsd18xOTIwLGhfMTkyMC9mb3JtYXQsd2VicC9xdWFsaXR5LHFfODAiLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE3OTg3NjE2MDB9fX1dfQ__&Key-Pair-Id=K2HSFNDJXOU9YS&Signature=Hk2p4vpvKgZsp8hQpLuPSENPDP9bGmjFt5cXZsKHXaGGPdFchTvE07Tlyq4lB8k~J8--O-N5Q5LRJPxWH7PuJfTyGpoa06QlbdgUFuPuURC4uP2v0wSv-05iZ35HbwY~UW08PXlMV3RTSK4YtBkeq~X1GvB6UQr7VgQuEYHssVE8KsUbzVZq61xc81OZS3aSDYF2fkZ6jSbEEdkcxxWkKx6TOhyr8dW9VEHgfyyqdEf0tw5Hz0RBlKEFbBNSNWJlmWD1DGT1zNneNCO7xQEpQFCwzDgCWpjsRSVlVQLOyyZmVOUz4q6IKgFobT5b-3ojn97WH3CFD5wlbdzQH56ABg__';

const APP_BG = {
  base: '#07110f',
  gradient: 'linear-gradient(155deg, #07110f 0%, #0d1f1a 40%, #13231e 68%, #1b211f 100%)',
  glowA: 'radial-gradient(circle at 18% 22%, rgba(16,185,129,0.18), transparent 44%)',
  glowB: 'radial-gradient(circle at 78% 10%, rgba(245,158,11,0.14), transparent 38%)',
  glowC: 'radial-gradient(circle at 70% 78%, rgba(34,211,238,0.08), transparent 40%)',
};


type Screen = 'menu' | 'levels' | 'game' | 'result' | 'store' | 'continue' | 'stats' | 'settings' | 'tutorial';

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
  const [testMode, setTestMode] = useState(false);
  const [unlockedPowerups, setUnlockedPowerups] = useState<Set<PowerupName>>(() => loadUnlockedPowerups());
  const [newUnlockNames, setNewUnlockNames] = useState<PowerupName[]>([]); // shown in unlock popup
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Load word list on mount + check daily login + tutorial
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

    // Show tutorial on first launch
    const tutorialSeen = localStorage.getItem('worddash_tutorial_seen');
    if (!tutorialSeen) {
      setTimeout(() => setScreen('tutorial'), 800);
    }
  }, []);

  // Timer for timed levels (scoreTimed and scoreTimedIce both need a countdown)
  useEffect(() => {
    const haTimer = gameState?.level.goalType === 'scoreTimed' || gameState?.level.goalType === 'scoreTimedIce';
    if (screen === 'game' && gameState && haTimer && !gameState.isGameOver) {
      timerRef.current = setInterval(() => {
        setGameState(prev => {
          if (!prev || prev.isGameOver || !prev.timerStarted) return prev;
          const next = { ...prev, timeRemaining: prev.timeRemaining - 1 };
          if (next.timeRemaining <= 0) {
            next.timeRemaining = 0;
            if (!next.isWon) {
              forceResolveChainOnTimer(next);
            }
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
  }, [screen, gameState?.isGameOver, gameState?.level?.goalType]);

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
        SoundEngine.playLevelComplete();

        // Track stats (matching iOS PersistenceManager.updateStatsOnLevelComplete)
        const longestWord = gameState.wordsFound.reduce((a, b) => b.length > a.length ? b : a, '');
        GameStatsManager.updateOnLevelComplete({
          levelNumber: lvl,
          wordsFound: gameState.wordsFound.length,
          score: gameState.score,
          stars: gameState.stars,
          maxStreak: gameState.maxStreakReached,
          maxCascade: gameState.maxCascadeReached,
          timeRemaining: gameState.timeRemaining,
          coinsEarned: breakdown.total,
          longestWord,
        });

        // Save power-up inventory
        saveInventory({
          hint: gameState.powerUps.hint,
          bomb: gameState.powerUps.bomb,
          laser: gameState.powerUps.laser,
          crossLaser: gameState.powerUps.crossLaser,
          mine: gameState.powerUps.mine,
          link: gameState.powerUps.link,
        });

        if (!current || gameState.score > current.score || gameState.stars > current.stars) {
          const updated = {
            ...bestScores,
            [lvl]: { score: Math.max(gameState.score, current?.score || 0), stars: Math.max(gameState.stars, current?.stars || 0) },
          };
          setBestScores(updated);
          localStorage.setItem('worddash_progress', JSON.stringify(updated));
        }

        // Check for newly unlocked powerups
        const newlyUnlocked = getNewlyUnlockedPowerups(lvl, unlockedPowerups);
        if (newlyUnlocked.length > 0) {
          const next = new Set(unlockedPowerups);
          newlyUnlocked.forEach(n => next.add(n));
          setUnlockedPowerups(next);
          saveUnlockedPowerups(next);
          setNewUnlockNames(newlyUnlocked);
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
    // Load persisted power-up inventory, gated by unlock state
    const inv = loadInventory();
    const ul = loadUnlockedPowerups();
    state.powerUps.hint       = ul.has('hint')       ? inv.hint       : 0;
    state.powerUps.bomb       = ul.has('bomb')       ? inv.bomb       : 0;
    state.powerUps.laser      = ul.has('laser')      ? inv.laser      : 0;
    state.powerUps.crossLaser = ul.has('crossLaser') ? inv.crossLaser : 0;
    state.powerUps.mine       = ul.has('mine')       ? inv.mine       : 0;
    state.powerUps.shuffle    = ul.has('shuffle')    ? inv.shuffle    : 0;
    state.powerUps.link       = ul.has('link')       ? inv.link       : 0;
    setGameState(state);
    setContinueSession(createContinueSession());
    setScreen('game');
  }, []);

  const handleWordSubmitted = useCallback((word: string, score: number, valid: boolean, reason?: string) => {
    if (valid) {
      SoundEngine.playWordSuccess();
      toast.success(`"${word}" +${score}`, { duration: 1500 });
    } else if (word.length >= 3) {
      SoundEngine.playWordFail();
      const msg = reason === 'already_used'
        ? `"${word}" already used!`
        : `"${word}" not in dictionary`;
      toast.error(msg, { duration: 1200 });
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
      <div className="min-h-screen flex items-center justify-center" style={{ background: APP_BG.gradient }}>
        <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="text-center">
          <div className="w-12 h-12 border-2 border-emerald-400 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-emerald-100/75 font-medium">Loading dictionary...</p>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen relative overflow-hidden" style={{ background: APP_BG.gradient }}>
      <div className="absolute inset-0" style={{ backgroundImage: `${APP_BG.glowA}, ${APP_BG.glowB}, ${APP_BG.glowC}` }} />
      <div className="relative z-10">
        {/* Daily Login Reward Modal */}
        <AnimatePresence>
          {dailyRewardShown && (
            <DailyLoginModal day={dailyRewardDay} amount={dailyRewardAmount} onClaim={claimDailyReward} />
          )}
        </AnimatePresence>

        {/* Powerup Unlock Popup */}
        <AnimatePresence>
          {newUnlockNames.length > 0 && (
            <PowerupUnlockModal names={newUnlockNames} onDismiss={() => setNewUnlockNames([])} />
          )}
        </AnimatePresence>

        <AnimatePresence mode="wait">
          {screen === 'menu' && <MenuScreen key="menu" onPlay={() => setScreen('levels')} onStore={() => setScreen('store')} onStats={() => setScreen('stats')} onSettings={() => setScreen('settings')} testMode={testMode} onToggleTestMode={() => {
            const newMode = !testMode;
            setTestMode(newMode);
            if (newMode) {
              CoinManager.setBalance(10000);
              toast.success('Test Mode ON: All levels unlocked, coins set to 10,000', { duration: 3000 });
            } else {
              toast.info('Test Mode OFF', { duration: 2000 });
            }
          }} />}
          {screen === 'store' && <StoreScreen key="store" onBack={() => setScreen('menu')} unlockedPowerups={unlockedPowerups} />}
          {screen === 'levels' && (
            <LevelSelectScreen key="levels" onBack={() => setScreen('menu')} onSelectLevel={startLevel} bestScores={bestScores} testMode={testMode} />
          )}
          {screen === 'game' && gameState && (
            <GameScreen
              key="game"
              gameState={gameState}
              unlockedPowerups={unlockedPowerups}
              onStateChange={handleStateChange}
              onWordSubmitted={handleWordSubmitted}
              onQuit={() => { if (timerRef.current) clearInterval(timerRef.current); saveInventory({ hint: gameState.powerUps.hint, bomb: gameState.powerUps.bomb, laser: gameState.powerUps.laser, crossLaser: gameState.powerUps.crossLaser, mine: gameState.powerUps.mine, link: gameState.powerUps.link }); setScreen('levels'); }}
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
          {screen === 'stats' && <StatsScreen key="stats" onBack={() => setScreen('menu')} />}
          {screen === 'settings' && <SettingsScreen key="settings" onBack={() => setScreen('menu')} />}
          {screen === 'tutorial' && <TutorialOverlay key="tutorial" onDismiss={() => { localStorage.setItem('worddash_tutorial_seen', 'true'); setScreen('menu'); }} />}
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
        className="w-full max-w-sm p-6 rounded-2xl border border-emerald-500/20 bg-gradient-to-b from-[#132821] to-[#111a18] text-center shadow-2xl shadow-emerald-900/25"
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
function MenuScreen({ onPlay, onStore, onStats, onSettings, testMode, onToggleTestMode }: { onPlay: () => void; onStore: () => void; onStats: () => void; onSettings: () => void; testMode: boolean; onToggleTestMode: () => void }) {
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
      <motion.div initial={{ y: 12, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.45 }} className="mb-4 px-4 py-2 rounded-full border border-emerald-300/20 bg-black/25 text-emerald-200/80 text-xs tracking-wide">
        Cozy wood + midnight glass theme
      </motion.div>
      <motion.div initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.5 }} className="flex gap-4">
        <Button onClick={onPlay} size="lg" className="text-lg px-12 py-6 bg-gradient-to-r from-emerald-500 to-emerald-400 hover:from-emerald-400 hover:to-emerald-300 text-black font-bold rounded-xl shadow-lg shadow-emerald-900/35 transition-all hover:shadow-emerald-700/35 hover:scale-105">
          Play
        </Button>
        <Button onClick={onStore} size="lg" variant="outline" className="text-lg px-8 py-6 border-amber-400/40 text-amber-300 hover:bg-amber-500/15 hover:text-amber-200 font-bold rounded-xl transition-all hover:scale-105 bg-black/20">
          🛒 Store
        </Button>
      </motion.div>
      <motion.div initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.6 }} className="flex gap-3 mt-4">
        <Button onClick={onStats} variant="outline" className="px-6 py-3 border-white/10 text-white/60 hover:text-white hover:bg-white/10 rounded-xl transition-all hover:scale-105">
          📊 Stats
        </Button>
        <Button onClick={onSettings} variant="outline" className="px-6 py-3 border-white/10 text-white/60 hover:text-white hover:bg-white/10 rounded-xl transition-all hover:scale-105">
          ⚙️ Settings
        </Button>
      </motion.div>
      <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.7 }} className="mt-6 text-emerald-100/55 text-sm">
        Drag across tiles to form words. Longer words earn special tiles!
      </motion.p>
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.9 }} className="mt-8">
        <button
          onClick={onToggleTestMode}
          className={`px-6 py-2.5 rounded-lg text-xs font-bold tracking-wide transition-all border ${
            testMode
              ? 'bg-red-500/20 border-red-400/40 text-red-300 hover:bg-red-500/30 shadow-lg shadow-red-900/20'
              : 'bg-white/5 border-white/10 text-white/40 hover:bg-white/10 hover:text-white/60'
          }`}
        >
          {testMode ? '🧪 TEST MODE ON' : '🧪 Enable Test Mode'}
        </button>
      </motion.div>
    </motion.div>
  );
}

// --- Store Screen ---
function StoreScreen({ onBack, unlockedPowerups }: { onBack: () => void; unlockedPowerups: Set<PowerupName> }) {
  const [inventory, setInventory] = useState<PowerupInventory>(loadInventory());
  const [, forceUpdate] = useState(0);

  const powerups: { key: PowerupName; icon: string; name: string; desc: string; cost: number; unlockLevel: number }[] = [
    { key: 'hint',       icon: '💡', name: 'Hint',        desc: 'Highlights a valid word on the board',               cost: GameEconomyConfig.storePrices.hint,       unlockLevel: POWERUP_UNLOCK_LEVELS.hint!       },
    { key: 'shuffle',    icon: '🔀', name: 'Shuffle',     desc: 'Randomizes all tile letters',                        cost: GameEconomyConfig.storePrices.hint,       unlockLevel: POWERUP_UNLOCK_LEVELS.shuffle!    },
    { key: 'bomb',       icon: '💣', name: 'Bomb',        desc: 'Places a bomb tile that clears 3×3',                 cost: GameEconomyConfig.storePrices.bomb,       unlockLevel: POWERUP_UNLOCK_LEVELS.bomb!       },
    { key: 'laser',      icon: '⚡', name: 'Laser',       desc: 'Places a laser tile that clears a row or column',    cost: GameEconomyConfig.storePrices.laser,      unlockLevel: POWERUP_UNLOCK_LEVELS.laser!      },
    { key: 'mine',       icon: '💥', name: 'Mine',        desc: 'Places a mine that detonates on clear',              cost: GameEconomyConfig.storePrices.mine,       unlockLevel: POWERUP_UNLOCK_LEVELS.mine!       },
    { key: 'crossLaser', icon: '✦',  name: 'Cross Laser', desc: 'Places a cross laser that clears row + column',      cost: GameEconomyConfig.storePrices.crossLaser, unlockLevel: POWERUP_UNLOCK_LEVELS.crossLaser! },
    { key: 'link',       icon: '🔗', name: 'Chain Link',  desc: 'Starts Chain Mode; overlap words to build a mult.',  cost: GameEconomyConfig.storePrices.link,       unlockLevel: POWERUP_UNLOCK_LEVELS.link!       },
  ];

  const handlePurchase = (key: PowerupName) => {
    const success = purchasePowerup(key as keyof PowerupInventory);
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
        <div className="flex items-center justify-between mb-3">
          <Button variant="ghost" onClick={onBack} className="text-white/60 hover:text-white">← Back</Button>
          <h2 className="text-xl font-bold text-white">Power-Up Store</h2>
          <CoinDisplay size="sm" />
        </div>

        <p className="text-xs text-white/30 mb-4">Complete levels to unlock new power-ups for purchase.</p>

        <div className="space-y-3 max-h-[70vh] overflow-y-auto pr-1">
          {powerups.map((pu) => {
            const isUnlocked = unlockedPowerups.has(pu.key);
            const owned = isUnlocked ? (inventory[pu.key as keyof PowerupInventory] ?? 0) : 0;
            const affordable = isUnlocked && CoinManager.canAfford(pu.cost);
            return (
              <motion.div
                key={pu.key}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className={`flex items-center gap-4 p-4 rounded-xl border backdrop-blur-sm shadow-lg shadow-black/20 transition-all ${
                  isUnlocked
                    ? 'border-emerald-200/10 bg-black/20'
                    : 'border-white/5 bg-white/[0.02] opacity-60'
                }`}
              >
                <div className="text-3xl w-12 text-center">{isUnlocked ? pu.icon : '🔒'}</div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className={`font-bold ${isUnlocked ? 'text-white' : 'text-white/40'}`}>{pu.name}</span>
                    {isUnlocked
                      ? <span className="text-xs px-2 py-0.5 rounded-full bg-white/10 text-white/50 font-mono">×{owned}</span>
                      : <span className="text-xs px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-400/70 font-mono">Level {pu.unlockLevel}</span>
                    }
                  </div>
                  <p className="text-xs text-white/40 mt-0.5">{isUnlocked ? pu.desc : `Unlocks after completing level ${pu.unlockLevel}`}</p>
                </div>
                <Button
                  onClick={() => isUnlocked && handlePurchase(pu.key)}
                  disabled={!affordable}
                  size="sm"
                  className={`rounded-lg font-bold min-w-[72px] ${
                    !isUnlocked
                      ? 'bg-white/5 text-white/20 cursor-not-allowed'
                      : affordable
                        ? 'bg-amber-500 hover:bg-amber-400 text-black'
                        : 'bg-white/10 text-white/30 cursor-not-allowed'
                  }`}
                >
                  {isUnlocked ? `🪙 ${pu.cost}` : '🔒'}
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
function LevelSelectScreen({ onBack, onSelectLevel, bestScores, testMode = false }: {
  onBack: () => void;
  onSelectLevel: (level: LevelConfig) => void;
  bestScores: Record<number, { score: number; stars: number }>;
  testMode?: boolean;
}) {
  return (
    <motion.div initial={{ opacity: 0, x: 50 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -50 }} className="min-h-screen px-4 py-8">
      <div className="max-w-lg mx-auto">
        <div className="flex items-center justify-between mb-8">
          <Button variant="ghost" onClick={onBack} className="text-white/60 hover:text-white">← Back</Button>
          <h2 className="text-xl font-bold text-white">Select Level</h2>
          <CoinDisplay size="sm" />
        </div>
        {/* World groupings */}
        {[
          { label: 'World 1', levels: LEVELS.slice(0, 10),  color: 'text-emerald-400' },
          { label: 'World 2', levels: LEVELS.slice(10, 20), color: 'text-sky-400' },
          { label: 'World 3', levels: LEVELS.slice(20, 35), color: 'text-violet-400' },
          { label: 'World 4', levels: LEVELS.slice(35, 50), color: 'text-amber-400' },
        ].map(world => (
          <div key={world.label} className="mb-6">
            <h3 className={`text-xs font-bold tracking-widest uppercase mb-3 ${world.color}`}>{world.label} — {world.levels[0].boardSize}×{world.levels[0].boardSize}</h3>
            <div className="grid grid-cols-5 gap-2">
              {world.levels.map((level) => {
                const best = bestScores[level.levelNumber];
                const prevBest = bestScores[level.levelNumber - 1];
                const isUnlocked = testMode || level.levelNumber === 1 || !!prevBest;
                const goalIcon =
                  level.goalType === 'scoreTimed'    ? '⏱' :
                  level.goalType === 'clearIceMoves' ? '❄' :
                  level.goalType === 'scoreMove'     ? '👣' :
                  level.goalType === 'scoreTimedIce' ? '⏱❄' : '👣❄';
                return (
                  <motion.button
                    key={level.levelNumber}
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: (level.levelNumber % 10) * 0.03 }}
                    onClick={() => isUnlocked && onSelectLevel(level)}
                    disabled={!isUnlocked}
                    className={`relative flex flex-col items-center p-2 rounded-xl border transition-all aspect-square justify-center ${
                      isUnlocked
                        ? 'border-emerald-200/10 bg-black/20 backdrop-blur-sm hover:bg-black/35 hover:border-emerald-400/35 hover:scale-105'
                        : 'border-white/5 bg-white/[0.02] opacity-40 cursor-not-allowed'
                    }`}
                  >
                    <div className="text-base font-bold text-white leading-none">{level.levelNumber}</div>
                    <div className="text-[8px] text-white/30 mt-0.5">{goalIcon}</div>
                    <div className="flex gap-0.5 mt-1">
                      {[1, 2, 3].map(s => (
                        <span key={s} className={`text-[8px] ${best && best.stars >= s ? 'text-amber-400' : 'text-white/15'}`}>★</span>
                      ))}
                    </div>
                    {!isUnlocked && (
                      <div className="absolute inset-0 flex items-center justify-center rounded-xl bg-black/30"><span className="text-lg">🔒</span></div>
                    )}
                  </motion.button>
                );
              })}
            </div>
          </div>
        ))}
      </div>
    </motion.div>
  );
}

// --- Game Screen ---
function GameScreen({ gameState, unlockedPowerups, onStateChange, onWordSubmitted, onQuit }: {
  gameState: GameState;
  unlockedPowerups: Set<PowerupName>;
  onStateChange: (state: GameState) => void;
  onWordSubmitted: (word: string, score: number, valid: boolean, reason?: string) => void;
  onQuit: () => void;
}) {
  const level = gameState.level;
  const g = level.goalType;
  const isTimedLevel = g === 'scoreTimed' || g === 'scoreTimedIce';
  const hasMoveLimit = g === 'clearIceMoves' || g === 'scoreMove' || g === 'scoreMoveIce';
  const hasIceGoal   = g === 'clearIceMoves' || g === 'scoreTimedIce' || g === 'scoreMoveIce';
  const hasScoreGoal = g === 'scoreTimed'    || g === 'scoreMove'     || g === 'scoreTimedIce' || g === 'scoreMoveIce';

  // Progress bar: for combo goals use average of sub-goal completions
  const scoreProgress = hasScoreGoal ? (gameState.score / (level.targetScore || 1)) * 100 : 100;
  const iceProgress   = hasIceGoal   ? (gameState.iceCleared / Math.max(gameState.totalIce, 1)) * 100 : 100;
  const progressPercent = (scoreProgress + iceProgress) / ((hasScoreGoal && hasIceGoal) ? 2 : 1);

  const formatTime = (s: number) => {
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return `${m}:${sec.toString().padStart(2, '0')}`;
  };

  const activatePowerUp = (name: string) => {
    if (name === 'shuffle') {
      SoundEngine.playPowerUp();
      useShuffle(gameState);
      onStateChange({ ...gameState });
      toast.info('Board shuffled!');
      return;
    }
    if (name === 'hint') {
      SoundEngine.playPowerUp();
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
      link: useLinkPowerUp,
    };
    const fn = placementFns[name];
    if (fn) {
      SoundEngine.playPowerUp();
      fn(gameState);
      onStateChange({ ...gameState });
      const labels: Record<string, string> = {
        bomb: '💣 Bomb placed on a random tile!',
        laser: '⚡ Laser placed on a random tile!',
        crossLaser: '✦ Cross Laser placed on a random tile!',
        mine: '💥 Mine placed on a random tile!',
        link: '🔗 Chain Link placed on a random tile!',
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
              {g === 'scoreTimed'    && `Score ${level.targetScore}`}
              {g === 'clearIceMoves' && `Clear ${level.iceTilesToClearTarget} ice`}
              {g === 'scoreMove'     && `Score ${level.targetScore} / ${level.moveLimit}mv`}
              {g === 'scoreTimedIce' && `Score ${level.targetScore} + ${level.iceTilesToClearTarget} ice`}
              {g === 'scoreMoveIce'  && `Score ${level.targetScore} + ${level.iceTilesToClearTarget} ice`}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <CoinDisplay size="sm" />
            <div className="flex flex-col items-end gap-0.5">
              {isTimedLevel && (
                <div className={`font-mono text-sm font-bold ${gameState.timeRemaining <= 10 && gameState.timerStarted ? 'text-red-400 animate-pulse' : 'text-white/70'}`}>
                  {formatTime(gameState.timeRemaining)}
                  {!gameState.timerStarted && <span className="text-[9px] text-white/30 block">starts on play</span>}
                </div>
              )}
              {hasMoveLimit && (
                <div className="font-mono text-sm text-white/70">
                  <span className={gameState.movesRemaining <= 3 ? 'text-red-400 font-bold' : ''}>{gameState.movesRemaining}</span>
                  <span className="text-white/40 text-xs"> mv</span>
                </div>
              )}
            </div>
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
            {gameState.chainMode.chainActive && (
              <motion.span initial={{ scale: 1.2 }} animate={{ scale: 1 }} className="text-xs text-cyan-300 font-bold">
                🔗 Chain {gameState.chainMode.chainWordCount}W • Base {gameState.chainMode.chainBasePoints}
              </motion.span>
            )}
            {hasIceGoal && (
              <span className="text-xs text-cyan-300">❄ {gameState.iceCleared}/{gameState.totalIce}</span>
            )}
          </div>
        </div>
      </div>

      {gameState.uiMessageTimer > 0 && <div className="text-center mb-1 text-xs text-cyan-300">{gameState.uiMessage}</div>}

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
          <PowerUpButton icon="💡" label="Hint"    count={gameState.powerUps.hint}       locked={!unlockedPowerups.has('hint')}       unlockLevel={POWERUP_UNLOCK_LEVELS.hint}       onClick={() => activatePowerUp('hint')} />
          <PowerUpButton icon="🔀" label="Shuffle" count={gameState.powerUps.shuffle}    locked={!unlockedPowerups.has('shuffle')}    unlockLevel={POWERUP_UNLOCK_LEVELS.shuffle}    onClick={() => activatePowerUp('shuffle')} />
          <PowerUpButton icon="💣" label="Bomb"    count={gameState.powerUps.bomb}       locked={!unlockedPowerups.has('bomb')}       unlockLevel={POWERUP_UNLOCK_LEVELS.bomb}       onClick={() => activatePowerUp('bomb')} />
          <PowerUpButton icon="⚡" label="Laser"   count={gameState.powerUps.laser}      locked={!unlockedPowerups.has('laser')}      unlockLevel={POWERUP_UNLOCK_LEVELS.laser}      onClick={() => activatePowerUp('laser')} />
          <PowerUpButton icon="✦" label="Cross"    count={gameState.powerUps.crossLaser} locked={!unlockedPowerups.has('crossLaser')} unlockLevel={POWERUP_UNLOCK_LEVELS.crossLaser} onClick={() => activatePowerUp('crossLaser')} />
          <PowerUpButton icon="💥" label="Mine"    count={gameState.powerUps.mine}       locked={!unlockedPowerups.has('mine')}       unlockLevel={POWERUP_UNLOCK_LEVELS.mine}       onClick={() => activatePowerUp('mine')} />
          <PowerUpButton icon="🔗" label="Link"    count={gameState.powerUps.link}       locked={!unlockedPowerups.has('link')}       unlockLevel={POWERUP_UNLOCK_LEVELS.link}       onClick={() => activatePowerUp('link')} />
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
function PowerUpButton({ icon, label, count, locked = false, unlockLevel, onClick }: {
  icon: string; label: string; count: number;
  locked?: boolean; unlockLevel?: number; onClick: () => void;
}) {
  const isDisabled = locked || count <= 0;
  return (
    <div className="relative group">
      <button
        onClick={locked ? undefined : onClick}
        disabled={isDisabled}
        className={`relative flex flex-col items-center gap-0.5 px-3 py-2 rounded-xl border transition-all ${
          locked
            ? 'border-white/5 bg-white/[0.02] opacity-40 cursor-not-allowed'
            : count > 0
              ? 'border-white/10 bg-white/5 hover:bg-white/10 hover:scale-105'
              : 'border-white/5 bg-white/[0.02] opacity-30 cursor-not-allowed'
        }`}
      >
        <span className="text-lg">{locked ? '🔒' : icon}</span>
        <span className="text-[9px] text-white/50">{label}</span>
        {!locked && (
          <span className="absolute -top-1 -right-1 bg-white/10 text-white/70 text-[10px] font-mono w-4 h-4 rounded-full flex items-center justify-center">
            {count}
          </span>
        )}
      </button>
      {/* Tooltip on hover for locked powerups */}
      {locked && unlockLevel && (
        <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 px-2 py-1 rounded-lg bg-black/90 border border-white/10 text-[9px] text-white/60 whitespace-nowrap pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity z-50">
          Unlocks at level {unlockLevel}
        </div>
      )}
    </div>
  );
}

// --- Powerup Unlock Modal ---
const POWERUP_DISPLAY: Record<PowerupName, { icon: string; label: string; desc: string }> = {
  hint:       { icon: '💡', label: 'Hint',       desc: 'Reveals a valid word path' },
  shuffle:    { icon: '🔀', label: 'Shuffle',    desc: 'Randomizes all tile letters' },
  bomb:       { icon: '💣', label: 'Bomb',       desc: 'Clears a 3×3 area' },
  laser:      { icon: '⚡', label: 'Laser',      desc: 'Clears a full row or column' },
  mine:       { icon: '💥', label: 'Mine',       desc: 'Triggers a 3×3 explosion' },
  crossLaser: { icon: '✦',  label: 'Cross Laser',desc: 'Clears a full row and column' },
  link:       { icon: '🔗', label: 'Chain Link', desc: 'Links words into a chain combo' },
};
function PowerupUnlockModal({ names, onDismiss }: { names: PowerupName[]; onDismiss: () => void }) {
  return (
    <motion.div
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm"
      onClick={onDismiss}
    >
      <motion.div
        initial={{ scale: 0.8, y: 30 }} animate={{ scale: 1, y: 0 }} exit={{ scale: 0.8, opacity: 0 }}
        onClick={e => e.stopPropagation()}
        className="bg-[#0d1f19] border border-emerald-400/20 rounded-2xl px-8 py-7 max-w-sm w-full mx-4 text-center shadow-2xl"
      >
        <div className="text-3xl mb-2">🎉</div>
        <h3 className="text-lg font-bold text-white mb-1">Power-Up Unlocked!</h3>
        <p className="text-sm text-white/50 mb-5">You've unlocked {names.length > 1 ? 'new powers' : 'a new power'}:</p>
        <div className="space-y-3 mb-6">
          {names.map(name => {
            const d = POWERUP_DISPLAY[name];
            return (
              <div key={name} className="flex items-center gap-3 bg-white/5 rounded-xl px-4 py-3">
                <span className="text-2xl">{d.icon}</span>
                <div className="text-left">
                  <div className="text-sm font-bold text-white">{d.label}</div>
                  <div className="text-xs text-white/40">{d.desc}</div>
                </div>
              </div>
            );
          })}
        </div>
        <Button onClick={onDismiss} className="w-full bg-emerald-500 hover:bg-emerald-400 text-black font-bold">
          Awesome!
        </Button>
      </motion.div>
    </motion.div>
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


// --- Stats Screen (matches iOS StatsScene) ---
function StatsScreen({ onBack }: { onBack: () => void }) {
  const stats = GameStatsManager.stats;
  const globalRows: [string, string][] = [
    ['Words Found', `${stats.totalWordsFound}`],
    ['Total Score', stats.totalScore >= 1000000 ? `${(stats.totalScore / 1000000).toFixed(1)}M` : stats.totalScore >= 1000 ? `${(stats.totalScore / 1000).toFixed(1)}K` : `${stats.totalScore}`],
    ['Levels Completed', `${stats.levelsCompleted}`],
    ['Best Streak', `${stats.bestStreak.toFixed(1)}x`],
    ['Best Cascade', stats.bestCascade > 0 ? `×${stats.bestCascade}` : '—'],
    ['Longest Word', stats.longestWord || '—'],
    ['Coins Earned', stats.totalCoinsEarned >= 1000 ? `${(stats.totalCoinsEarned / 1000).toFixed(1)}K` : `${stats.totalCoinsEarned}`],
    ['Sessions Played', `${stats.sessionsPlayed}`],
    ['Last Played', stats.lastPlayedDate || '—'],
  ];

  return (
    <motion.div initial={{ opacity: 0, x: 50 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -50 }} className="min-h-screen px-4 py-8">
      <div className="max-w-lg mx-auto">
        <div className="flex items-center justify-between mb-6">
          <Button variant="ghost" onClick={onBack} className="text-white/60 hover:text-white">← Back</Button>
          <h2 className="text-xl font-bold text-white">📊 Your Stats</h2>
          <CoinDisplay size="sm" />
        </div>

        {/* Global Stats */}
        <div className="mb-6">
          <h3 className="text-xs font-bold text-emerald-400 uppercase tracking-wider mb-3">Global Stats</h3>
          <div className="space-y-1">
            {globalRows.map(([label, value]) => (
              <div key={label} className="flex justify-between items-center px-4 py-2.5 rounded-lg bg-white/[0.03]">
                <span className="text-sm text-white/50">{label}</span>
                <span className="text-sm text-white font-mono font-bold">{value}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Level Performance Table */}
        <div>
          <h3 className="text-xs font-bold text-emerald-400 uppercase tracking-wider mb-3">Level Performance</h3>
          <div className="rounded-xl border border-white/5 overflow-hidden">
            {/* Table header */}
            <div className="grid grid-cols-3 px-4 py-2 bg-white/[0.03] text-[11px] text-white/35 font-bold uppercase tracking-wider">
              <span>Level</span>
              <span className="text-center">Stars</span>
              <span className="text-right">Best Score</span>
            </div>
            {/* Table rows */}
            {Array.from({ length: 10 }, (_, i) => i + 1).map(level => {
              const stars = stats.levelStars[level] ?? 0;
              const score = stats.levelBestScores[level] ?? 0;
              return (
                <div key={level} className={`grid grid-cols-3 px-4 py-2 ${stars > 0 ? 'bg-emerald-900/10' : 'bg-white/[0.01]'} border-t border-white/[0.03]`}>
                  <span className={`text-sm font-bold ${stars > 0 ? 'text-white' : 'text-white/25'}`}>Lvl {level}</span>
                  <span className="text-center text-sm">
                    {stars > 0
                      ? <span className="text-amber-400">{'★'.repeat(stars)}{'☆'.repeat(3 - stars)}</span>
                      : <span className="text-white/20">—</span>
                    }
                  </span>
                  <span className={`text-right text-sm font-mono ${score > 0 ? 'text-emerald-400 font-bold' : 'text-white/20'}`}>
                    {score > 0 ? (score >= 1000 ? `${(score / 1000).toFixed(1)}K` : score) : '—'}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </motion.div>
  );
}

// --- Settings Screen (matches iOS SettingsScene) ---
function SettingsScreen({ onBack }: { onBack: () => void }) {
  const [soundEnabled, setSoundEnabled] = useState(SoundEngine.enabled);
  const [showResetConfirm, setShowResetConfirm] = useState(false);

  const toggleSound = () => {
    const newVal = !soundEnabled;
    SoundEngine.enabled = newVal;
    setSoundEnabled(newVal);
    toast.info(newVal ? 'Sound enabled' : 'Sound disabled');
  };

  const resetProgress = () => {
    // Clear all localStorage keys
    localStorage.removeItem('worddash_progress');
    localStorage.removeItem('worddash_coins');
    localStorage.removeItem('worddash_first_launch');
    localStorage.removeItem('worddash_powerup_inventory');
    localStorage.removeItem('worddash_daily_login');
    localStorage.removeItem('worddash_tutorial_seen');
    GameStatsManager.reset();
    CoinManager.resetToStarting();
    setShowResetConfirm(false);
    toast.success('Progress reset! Reload to start fresh.');
    // Reload after a brief delay
    setTimeout(() => window.location.reload(), 1500);
  };

  return (
    <motion.div initial={{ opacity: 0, x: 50 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -50 }} className="min-h-screen px-4 py-8">
      <div className="max-w-lg mx-auto">
        <div className="flex items-center justify-between mb-8">
          <Button variant="ghost" onClick={onBack} className="text-white/60 hover:text-white">← Back</Button>
          <h2 className="text-xl font-bold text-white">⚙️ Settings</h2>
          <div className="w-16" />
        </div>

        {/* Sound Toggle */}
        <div className="flex items-center justify-between px-5 py-4 rounded-xl border border-white/5 bg-white/[0.03] mb-4">
          <div>
            <div className="text-white font-bold text-sm">Sound Effects</div>
            <div className="text-white/40 text-xs">Procedural audio for tile clicks, words, and explosions</div>
          </div>
          <button
            onClick={toggleSound}
            className={`relative w-14 h-7 rounded-full transition-colors ${soundEnabled ? 'bg-emerald-500' : 'bg-white/20'}`}
          >
            <motion.div
              animate={{ x: soundEnabled ? 24 : 2 }}
              transition={{ type: 'spring', stiffness: 300, damping: 25 }}
              className="absolute top-0.5 w-6 h-6 rounded-full bg-white shadow-md"
            />
          </button>
        </div>

        {/* Haptics note */}
        <div className="flex items-center justify-between px-5 py-4 rounded-xl border border-white/5 bg-white/[0.03] mb-8 opacity-50">
          <div>
            <div className="text-white font-bold text-sm">Haptic Feedback</div>
            <div className="text-white/40 text-xs">Available on iOS only</div>
          </div>
          <div className="text-white/30 text-xs">N/A</div>
        </div>

        {/* Reset Progress */}
        <div className="border-t border-white/5 pt-6">
          <h3 className="text-xs font-bold text-red-400/80 uppercase tracking-wider mb-3">Danger Zone</h3>
          {!showResetConfirm ? (
            <Button
              onClick={() => setShowResetConfirm(true)}
              className="w-full bg-red-500/15 hover:bg-red-500/25 text-red-400 font-bold rounded-xl border border-red-500/20"
            >
              Reset All Progress
            </Button>
          ) : (
            <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-3">
              <p className="text-red-400/80 text-sm text-center">This will erase all progress, coins, stats, and power-ups. Are you sure?</p>
              <div className="flex gap-3">
                <Button onClick={() => setShowResetConfirm(false)} variant="outline" className="flex-1 border-white/10 text-white/60">
                  Cancel
                </Button>
                <Button onClick={resetProgress} className="flex-1 bg-red-500 hover:bg-red-400 text-white font-bold">
                  Yes, Reset Everything
                </Button>
              </div>
            </motion.div>
          )}
        </div>

        {/* Show Tutorial Again */}
        <div className="mt-6">
          <Button
            onClick={() => { onBack(); setTimeout(() => { localStorage.removeItem('worddash_tutorial_seen'); window.dispatchEvent(new CustomEvent('show-tutorial')); }, 100); }}
            variant="outline"
            className="w-full border-white/10 text-white/50 hover:text-white hover:bg-white/10 rounded-xl"
          >
            📖 Show Tutorial Again
          </Button>
        </div>
      </div>
    </motion.div>
  );
}

// --- Tutorial Overlay (matches iOS TutorialScene — 6-step paginated) ---
function TutorialOverlay({ onDismiss }: { onDismiss: () => void }) {
  const steps = [
    { emoji: '👆', title: 'Drag to Spell', body: 'Touch and drag across adjacent tiles to spell words. Connect tiles in any of 8 directions including diagonals.' },
    { emoji: '💥', title: 'Words Clear the Board', body: 'Valid words explode the tiles and fill from the top. Tiles fall with gravity — chain reactions earn cascade bonuses!' },
    { emoji: '⚡', title: 'Earn Special Tiles', body: 'Spell long words to earn powerful tiles. 5-letter words spawn Bombs, 6-letter Lasers, 7-letter Cross Lasers, 8+ Wildcards.' },
    { emoji: '🔥', title: 'Build Streaks', body: 'Submit words quickly to build a streak multiplier up to 3×. More points per word the hotter your streak!' },
    { emoji: '🎯', title: 'Use Power-Ups', body: 'Tap a power-up icon then tap a tile to activate it. Hints highlight a word. Bombs, Lasers, and Mines clear large areas.' },
    { emoji: '🪙', title: 'Earn Coins', body: 'Complete levels to earn coins. Buy more power-ups in the Store. Daily login bonuses increase each consecutive day.' },
  ];

  const [currentStep, setCurrentStep] = useState(0);

  const advance = () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      onDismiss();
    }
  };

  const step = steps[currentStep];

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm px-4"
    >
      <motion.div
        key={currentStep}
        initial={{ opacity: 0, y: 20, scale: 0.95 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: -20 }}
        transition={{ type: 'spring', stiffness: 200, damping: 20 }}
        className="w-full max-w-sm p-8 rounded-2xl border border-emerald-500/15 bg-gradient-to-b from-[#0d1f1a] to-[#111a18] text-center shadow-2xl"
      >
        {/* Skip button */}
        <button onClick={onDismiss} className="absolute top-4 right-4 text-white/30 hover:text-white/60 text-xs transition-colors">
          Skip →
        </button>

        <div className="text-5xl mb-4">{step.emoji}</div>
        <h2 className="text-xl font-bold text-white mb-3">{step.title}</h2>
        <p className="text-white/60 text-sm leading-relaxed mb-6">{step.body}</p>

        {/* Step dots */}
        <div className="flex justify-center gap-2 mb-5">
          {steps.map((_, i) => (
            <button
              key={i}
              onClick={() => setCurrentStep(i)}
              className={`w-2.5 h-2.5 rounded-full transition-all ${
                i === currentStep ? 'bg-emerald-400 scale-125' : 'bg-white/20 hover:bg-white/30'
              }`}
            />
          ))}
        </div>

        <Button onClick={advance} className="w-full bg-emerald-500 hover:bg-emerald-400 text-black font-bold rounded-xl">
          {currentStep === steps.length - 1 ? "Let's Play!" : 'Next →'}
        </Button>
      </motion.div>
    </motion.div>
  );
}
