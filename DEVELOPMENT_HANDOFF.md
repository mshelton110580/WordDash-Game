# WordDash Development Handoff (Web + iOS)

This document summarizes the current architecture of both versions so new feature work can move faster and stay cross-platform.

## 1) High-level architecture

- **iOS app**: Swift + SpriteKit, scene-based navigation (`MainMenuScene` → `LevelMapScene` → `GameScene`, plus store/settings/stats/tutorial scenes).
- **Web app**: React + TypeScript + Canvas-style board rendering in `GameBoard`, with a large state-driven screen flow inside `Home.tsx`.
- **Shared gameplay model**: Both versions use a 7×7 letter grid, drag-to-spell adjacency, dictionary validation, long-word special tiles, power-ups, level goals (`scoreTimed` and `clearIceMoves`), streak/cascade scoring, and local persistence.

## 2) Web version map

### Core files

- `web/client/src/pages/Home.tsx`
  - Main app shell and screen router (`menu`, `levels`, `game`, `result`, `store`, `continue`).
  - Handles wordlist loading, level start/reset, timer loop, daily reward, continue logic, coin reward flow, and power-up inventory persistence.
- `web/client/src/components/GameBoard.tsx`
  - Input + render integration for the live board, selected path, HUD interactions, and power-up usage.
- `web/client/src/lib/gameEngine.ts`
  - Main engine/state module: tile model, board creation, adjacency rules, score math, level data, dictionary/profanity filtering, special tile behavior, and game-state mutation helpers.
- `web/client/src/lib/economy.ts`
  - Coin manager, reward breakdown calculator, continue costs, store purchase rules, and daily login reward model.

### Web gameplay notes

- Word list loading is async and has fallback behavior if local/CDN loading fails.
- Extra web polish/features include UI toasts, animated coin display, and a modern multi-screen flow that doubles as a rapid testbed.
- Current checklist still marks a few web menu pages as partial/stub even though the main game loop is feature rich.

## 3) iOS version map

### Core files

- `WordDash/Sources/Scenes/GameScene.swift`
  - Main gameplay scene: board setup/rendering, touch drag pathing, HUD, effects, and gameplay resolution.
- `WordDash/Sources/Engine/BoardModel.swift`
  - Grid data and core board operations (adjacency checks, clears, gravity/refill, special clear patterns).
- `WordDash/Sources/Engine/ScoringEngine.swift`
  - Word scoring rules (letter values, multipliers, streak, cascades, repeat-diminishing).
- `WordDash/Sources/Engine/WordValidator.swift`
  - Dictionary and profanity loading/validation.
- `WordDash/Sources/Economy/*.swift`
  - Economy config, coin manager, daily login manager, continue manager, and level coin calculator.
- `WordDash/Sources/Scenes/MainMenuScene.swift`, `StoreScene.swift`, `SettingsScene.swift`, `StatsScene.swift`, `TutorialScene.swift`
  - iOS has fuller scene coverage for meta-systems (store/settings/stats/tutorial).

### iOS gameplay notes

- SpriteKit scene setup is explicit and code-first (no storyboard dependence).
- Tile rendering uses asset-backed sprites with overlays/badges for ice, specials, and multipliers.
- iOS appears to be the most complete reference implementation for “full game shell” behavior.

## 4) Cross-platform parity snapshot

Good parity right now:

- Core board mechanics (7×7 board, drag adjacency with backtracking).
- Dictionary + profanity checks.
- Score system with streak/cascade/repeat modifiers.
- Long-word special tile spawning and power-up ecosystem.
- Coin economy + daily reward + continue system.

Likely drift areas to watch:

- Scene/screen completeness (store/settings/stats/tutorial UX is more mature on iOS).
- HUD details, VFX timing, and animation consistency.
- Persistence key/version drift between platforms when adding new player state fields.

## 5) Recommended development strategy (next)

1. **Pick one source of truth per subsystem**
   - Treat iOS engine rules as canonical for mechanics.
   - Treat web `Home.tsx` flow as rapid iteration ground for UI/economy experiments.

2. **Add a parity checklist for every new feature PR**
   - “Web implemented?”
   - “iOS implemented?”
   - “Scoring/economy constants matched?”
   - “Persistence migration handled?”

3. **Extract shared design constants to a single spec doc**
   - Letter values, multipliers, special tile thresholds, economy numbers.
   - Update both `gameEngine.ts` and Swift constants in the same PR when numbers change.

4. **Tackle highest-value unfinished items**
   - Persist web power-up inventory and remaining meta progression gaps.
   - Align settings/store/stats behavior and copy between platforms.

## 6) Suggested first implementation tasks I can help with

- Add a **cross-platform balancing config table** and wire both engines to it.
- Implement **web settings page parity** (sound/haptics/preferences + persistence).
- Build a **shared test matrix** for scoring/economy edge cases and keep both versions in lockstep.
- Add **save-data versioning/migration helpers** to prevent future persistence breakage.

---

If you want, next I can start with one concrete feature and implement it in both web + iOS in the same pass.
