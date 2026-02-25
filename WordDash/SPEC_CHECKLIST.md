# WordDash — Specification Checklist

> **How to use this file:**
> This file tracks every requirement from the original WordDash specification. Each item is marked with a checkbox:
> - `[x]` = Implemented and working
> - `[ ]` = Not yet implemented
>
> **Ongoing tracking instructions:**
> When a new feature is requested, add it to the appropriate section below (or to the "Additional Features" section at the bottom) with an unchecked box `[ ]`. Once the feature is implemented and verified, mark it `[x]`.

---

## Game Overview

- [x] Candy-crush-like tile board game using letter tiles
- [x] Players drag across adjacent tiles (including diagonals) to form words
- [x] Valid words clear (explode), tiles fall down, new tiles spawn from top
- [x] Scrabble-like letter values
- [x] Combo/streak scoring
- [x] Earned special tiles (created by long words)
- [x] Consumable power-ups with inventory counts
- [x] Power-up inventory persisted locally

---

## Core Gameplay

- [x] Board: 7x7 grid with uppercase letter tiles
- [x] Input: drag to connect tiles in 8 directions (including diagonals)
- [x] A tile cannot be used twice in the same path
- [x] Backtracking: dragging back to previous tile removes last tile from path
- [x] Minimum word length: 3
- [x] On touch end: build word string and validate using local English dictionary
- [x] Word list file included (358,612 words)
- [x] Invalid word: shake selection and reset, do not clear tiles
- [x] Valid word: score using ScoringEngine rules
- [x] Valid word: clear selected tiles (explosion animation / particles)
- [x] Valid word: trigger special-tile effects after acceptance
- [x] Gravity/fill: tiles fall straight down; new tiles spawn from top
- [x] Track cascades and award cascade bonuses

---

## Dictionary + Filtering

- [x] WordValidator: load bundled word list (text file, one word per line)
- [x] Validate case-insensitive, store words uppercased for lookup
- [x] Profanity block list (stub implemented, rejects blocked words)

---

## Scoring

- [x] Letter values configurable map: A,E,I,O,N,R,T,L,S,U=1; D,G=2; B,C,M,P=3; F,H,V,W,Y=4; K=5; J,X=8; Q,Z=10
- [x] WordScore = (sum of letter values) × lengthMultiplier × streakMultiplier
- [x] Length multipliers: 3→1.0, 4→1.2, 5→1.5, 6→1.9, 7→2.4, 8+→3.0
- [x] Streak: valid word within 4 seconds increases streak multiplier by +0.2 per step
- [x] Streak multiplier capped at 3.0
- [x] Streak resets if time window missed
- [x] Cascade bonus: step 1→+10, step 2→+25, step 3→+50, step 4+→+100 each
- [x] Cascade step defined as additional clear events after initial word resolution
- [x] Diminishing repeats: 2nd use of same word → 50% points
- [x] Diminishing repeats: 3rd+ use → 10% points

---

## Earned Special Tiles (Created by Long Words)

- [x] Spawn special tile at last tile position after valid word, based on word length
- [x] Length 5 → Bomb tile
- [x] Length 6 → Laser tile
- [x] Length 7 → Cross Laser tile
- [x] Length 8+ → Wildcard tile (acts as any letter; scores 2 base points)
- [x] Special tiles behave like normal tiles (can be included in word paths)
- [x] When included in a valid word, trigger effect then remove

---

## Special Tile Effects

- [x] Bomb: clears 3x3 area centered on bomb tile
- [x] Laser: clears full row or column (infer direction from drag movement into laser tile; fallback to row)
- [x] Cross Laser: clears both full row and full column intersecting the tile
- [x] Mine: clears surrounding 3x3 when triggered (for consumable placement)
- [x] Wildcard: treated as any letter for forming a word; contributes fixed 2 points base

---

## Consumable Power-Ups

- [x] Implemented as consumable items with counts shown in HUD
- [x] Counts persisted locally
- [x] In-game toolbar with all power-ups
- [x] 1) Hint: highlight one valid word path on the board for 3 seconds (does not auto-play)
- [x] 2) Bomb: user taps a tile; clear 3x3 area centered on it
- [x] 3) Laser: user taps a tile; clear row/column (default row)
- [x] 4) Cross Laser: user taps a tile; clear row and column
- [x] 5) Mine: user taps a tile to place mine overlay; triggers when tile is cleared, then clears surrounding 3x3
- [x] 6) Shuffle: randomize all non-special tile letters (bonus power-up not in original spec)

---

## Level System (Data-Driven)

- [x] Levels 1–10 defined as config data (JSON-equivalent in code)
- [x] Support goal type A: scoreTimed (TargetScore, TimeLimitSeconds)
- [x] Support goal type B: clearIceMoves (IceTilesToClearTarget, MoveLimit, IcePositions)
- [x] Ice blocker (2-hit): first clearing event → crack; second → clear
- [x] Ice tiles can be used in word paths
- [x] Mix of scoreTimed and clearIceMoves across levels 1–10

---

## Time Handling (for scoreTimed)

- [x] Countdown timer shown in HUD for scoreTimed levels
- [x] Timer starts on first user interaction (first touch / first valid word)
- [x] "Starts on play" indicator shown before timer begins
- [x] When timer reaches 0, level ends immediately and shows results
- [x] If targetScore reached before time ends, level completes early

---

## Progression + Results

- [x] Level completion screen: show score, stars (1–3 thresholds per level config)
- [x] "Next Level" button on completion screen
- [x] Level map screen: level list with lock/unlock
- [x] Unlock next level on completion
- [x] Main menu with Play button
- [x] Store screen (functional: purchases, inventory, coin display)
- [x] Settings screen (sound/haptics toggles, tutorial reset, progress reset)
- [x] Correct failure message: "Time's Up!" for timed levels, "Out of Moves!" for ice levels

---

## UI / HUD

- [x] Score display
- [x] Timer (for scoreTimed) or moves remaining (for clearIceMoves)
- [x] Goal progress indicator (progress bar)
- [x] Streak indicator (with fire emoji and multiplier display)
- [x] Power-up toolbar with counts
- [x] Active power-up indicator with cancel option
- [x] Selection glow animation (emerald glow on selected tiles)
- [x] Invalid word shake animation (board shakes on invalid submission)
- [x] Explosion particles on valid word clear
- [x] Tile fall easing animation (bounce easing)
- [x] Laser line visual effects (animated gradient beams)
- [x] Ice overlay rendering (intact + cracked with crack lines)
- [x] Mine overlay rendering (dashed orange border)
- [x] Hint path highlighting (pulsing yellow dashed glow)
- [x] Word preview above board during drag (green if valid, red if invalid)
- [x] Words found history display

---

## Persistence (Local MVP)

- [x] Save unlocked level progress using localStorage
- [x] Per-level stars saved
- [x] Best score per level saved
- [x] Power-up inventory counts initialized per game (not yet persisted across sessions)

---

## Architecture (Web Test Environment)

- [x] GameBoard component (canvas render + input handling)
- [x] Game engine module (grid state, adjacency, gravity, refill)
- [x] WordValidator (dictionary lookup with fallback)
- [x] ScoringEngine (all multipliers, streaks, cascades, diminishing)
- [x] PowerUpSystem (all 6 power-ups)
- [x] Level configs (10 levels with mixed goal types)

---

## Architecture (iOS Project — Xcode)

- [x] GameScene (render/input via SpriteKit)
- [x] BoardModel (grid state, adjacency, gravity refill)
- [x] WordValidator (dictionary lookup)
- [x] ScoringEngine
- [x] PowerUpSystem
- [x] LevelManager (loads JSON configs)
- [x] Unit tests: adjacency rules (including diagonals + no reuse)
- [x] Unit tests: backtracking behavior
- [x] Unit tests: scoring multipliers and repeat diminishing

---

## Assets (iOS Project)

- [x] Placeholder tile PNGs (normal, selected, ice intact, ice cracked)
- [x] Placeholder special tile PNGs (bomb, laser, cross, mine, wildcard)
- [x] Placeholder icon PNGs (hint, bomb, laser, cross, mine, shuffle)
- [x] Placeholder background PNGs (menu, game)
- [x] Structured for easy replacement

---

## Deliverables

- [x] Compiling Xcode project with working gameplay for levels 1–10
- [x] Levels 1–10 JSON included in bundle (mix of scoreTimed and clearIceMoves)
- [x] README with build steps and asset replacement instructions
- [x] No external services required
- [x] GitHub repository: https://github.com/mshelton110580/WordDash-iOS
- [x] Web-based test environment for browser playtesting

---

## Additional Features

> Add new feature requests below. Mark `[x]` when implemented.

- [x] Web Audio sound effects (tile clicks, word chimes, explosions, level complete fanfare, coin earned)
- [x] Interactive tutorial overlay for first-time users (6-step paginated, shown on first launch)
- [x] Stats/leaderboard page (lifetime words, best streaks, per-level scores and stars)
- [x] Store screen stub (fully functional: inventory display, purchase flow, affordability check)
- [x] Settings screen (sound toggle, haptics toggle, tutorial reset, danger-zone progress reset)
- [x] Power-up inventory persistence across game sessions (localStorage, loaded on game start)
- [x] Laser power-up direction choice (Row ↔ / Column ↕ picker appears after laser is placed)
- [x] Bombs, mines, and lasers appear as earned game tiles on the board (spawned by long words, visually distinct with colored backgrounds, glow borders, icons, and labels)
- [x] Smooth diagonal drag: asymmetric hit zones (orthogonal 0.48r vs diagonal 0.32r) with drag-angle intent check (dot > 0.75) to strongly prefer orthogonal tiles and only allow diagonals with clear diagonal intent
- [x] Power-up bombs, lasers, cross lasers, and mines place special tiles randomly on the board (keeping the tile's letter), triggering when included in a valid word
- [x] Hints stay highlighted with a pulsing glow until the next word is successfully submitted (no longer fade after 3 seconds)
- [x] Double letter (2x) and triple letter (3x) score tiles appear randomly when new tiles drop (not every word — spawns every 3rd word, ~12% chance for 2x, ~6% for 3x)
- [x] Dual-bomb board explosion: if a word path contains 2+ bomb tiles, the entire board explodes with a big bonus
- [x] All tiles destroyed by explosions (bombs, lasers, cross lasers, mines) award base letter points
- [x] Letter multipliers (2x/3x) only apply when spelling words, not when tiles are destroyed by power-up explosions
- [x] Multiple letter multipliers in the same word multiply together (e.g., 2x + 3x = 6x combined word multiplier applied to the entire word's raw letter score)

---

## Coin Economy (Section 1–2)

- [x] Players start with 500 coins on first launch
- [x] Coin balance persisted locally (survives app restart)
- [x] CoinManager: addCoins, spendCoins, canAfford
- [x] CoinReason enum: levelBase, starBonus, streakBonus, cascadeBonus, efficiencyBonus, dailyLogin, dailyChallenge, adReward
- [x] Notifications/callbacks when balance changes for UI updates
- [x] GameEconomyConfig struct (no hardcoded economy values)

---

## Coins Earned from Level Success (Section 3)

- [x] Base coins = LevelNumber × 5
- [x] Star bonus: 1★=+10, 2★=+20, 3★=+40
- [x] 6+ letter word: +2 coins per occurrence
- [x] 7+ letter word: +4 coins per occurrence
- [x] 8+ letter word: +6 coins per occurrence
- [x] Streak 2.0x: +5 coins
- [x] Streak 2.5x: +10 coins
- [x] Streak 3.0x: +20 coins
- [x] Cascade 2+: +5 coins
- [x] Cascade 3+: +10 coins
- [x] Timed levels: +10 coins if finish with 20% time remaining
- [x] Move-based levels: +10 coins if 3+ moves remaining
- [x] Anti-farming: replay → 50% base, no star bonus, performance capped at 50
- [x] Total coins per level capped at 500
- [x] Detailed breakdown display at level completion (Base, Stars, Bonuses, Total)

---

## Powerup Store (Section 4)

- [x] StoreScreen with coin balance, powerup grid, owned count, cost, purchase button
- [x] Hint: 50 coins
- [x] Bomb: 75 coins
- [x] Laser: 100 coins
- [x] Cross Laser: 150 coins
- [x] Mine: 125 coins
- [x] Purchase flow: check canAfford → deduct → increase inventory → animate → confirm
- [x] Inventory persisted locally

---

## Continue System (Section 5)

- [x] On level failure: modal with Retry (free), Continue with Coins, Continue with Ad
- [x] Continue cost: +5 moves or +60 seconds (1 minute) = 200 coins
- [x] Second continue same session = 300 coins
- [x] Third continue = 400 coins
- [x] Maximum 3 continues per level session
- [x] After 3 continues: only Retry allowed
- [x] If insufficient coins: show "Not enough coins" + option to open store
- [x] Ad continue: same benefit, no coin cost, once per session (stub)

---

## Daily Login Coins (Section 6)

- [x] DailyLoginManager
- [x] Day 1: 25, Day 2: 35, Day 3: 50, Day 4: 75, Day 5: 100, Day 6: 125, Day 7: 150
- [x] Resets if a day is missed

---

## Economy UI (Section 7)

- [x] Coin display in main menu
- [x] Coin display in store
- [x] Coin display in in-game HUD
- [x] Animated coin gain effect (flash + scale animation on balance change)
- [x] Smooth deduction animation
- [x] Clear breakdown summary screen at level completion
- [x] Real-time coin counter during gameplay (coins earned update live as words are spelled)
- [x] Animated coin-fly effect from board to coin counter when coins are earned (bezier curve animation with gold coin sprite)
- [x] Continue system grants +60 seconds (1 minute, up from +15s) or +5 moves
- [x] Redesigned continue screen: Watch Ad (free, 1/level), Continue with Coins (escalating cost), and Forfeit option
- [x] Forfeit option shows how many coins would be lost if level is abandoned (with red warning text)

---

## Premium Graphics Overhaul (Section 8)

- [x] Wood-grain Scrabble-style tile assets: CDN-hosted PNG images for normal, selected, bomb, laser, cross laser, mine, wildcard, ice intact, ice cracked tiles
- [x] Image-based tile rendering: tiles drawn using high-quality wood texture images instead of programmatic gradients
- [x] Dark text on light wood tiles for proper contrast (white text on special tiles with dark backgrounds)
- [x] Warm wood tray board background with inner shadow for depth
- [x] Layered explosions: squash+pop tile animation (3 phases: squash, pop with white flash, fade)
- [x] Multi-emitter particle system: wood chips (rectangles with gravity + rotation), dust puffs (soft circles, quick fade), sparkles (additive blend, upward drift)
- [x] Shockwave ring effects: expanding circle with inner glow for special tile detonations (250ms duration, 1.6x max scale)
- [x] Tile squash+pop animation before removal: tiles compress vertically then scale up and fade
- [x] Staggered timing: ripple effect along word path (25ms per tile delay for particles, 1.5 frames per tile for squash+pop)
- [x] Screen shake: 6px for bombs, 4px for lasers, 2px for long words (5+ letters), 4px for invalid word rejection
- [x] Theme-matched particle colors: warm dust (#D4A574) for normal, cool blue (#4DA6FF) for laser, orange (#FF6B35) for bomb, red (#FF4444) for mine, purple (#B266FF) for cross laser, gold (#FFD700) for wildcard
- [x] Explosion-cleared tile effects: particles also spawn for tiles cleared by bomb radius, laser lines, mine blasts (not just word path tiles)
- [x] Performance optimization: particle counts capped per intensity level (normal: 9 particles, big: 16, mega: 24), gravity/drag varies by particle role
- [x] Particle pooling via role-based lifecycle: chips have heavy gravity and short life, dust has light drag, sparkles drift upward
