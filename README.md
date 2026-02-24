# WordDash

A candy-crush-like tile board game using letter tiles, built with Swift and SpriteKit for iOS 17+.

## Overview

WordDash is a word puzzle game where players drag across adjacent tiles (including diagonals) to form words. Valid words clear with explosion animations, tiles fall down, and new tiles spawn from the top. The game features Scrabble-like letter scoring, combo/streak mechanics, special tiles earned by forming long words, and consumable power-ups.

## Features

- **7×7 Letter Grid** with drag-to-connect word formation (8 directions including diagonals)
- **Backtracking** support during drag (drag back to previous tile to undo)
- **Dictionary Validation** using a bundled 358K+ English word list with profanity filter
- **Scrabble-like Scoring** with letter values, length multipliers, streak bonuses, cascade bonuses, and diminishing returns for repeated words
- **Special Tiles** earned by forming long words:
  - 5-letter word → **Bomb** (clears 3×3 area)
  - 6-letter word → **Laser** (clears row or column based on drag direction)
  - 7-letter word → **Cross Laser** (clears both row and column)
  - 8+ letter word → **Wildcard** (acts as any letter, 2 base points)
- **Consumable Power-Ups**: Hint, Bomb, Laser, Cross Laser, Mine
- **Two Goal Types**:
  - `scoreTimed`: Reach target score within time limit
  - `clearIceMoves`: Clear ice-covered tiles within move limit
- **Ice Mechanic**: 2-hit ice tiles that crack on first hit, clear on second
- **10 Levels** with progressive difficulty (JSON-configured, data-driven)
- **Star Rating** (1-3 stars per level)
- **Persistence**: Progress, best scores, stars, and power-up inventory saved locally
- **Animations**: Selection glow, invalid shake, explosion particles, tile fall easing, laser/bomb visual effects

## Requirements

- **Xcode 15.0+**
- **iOS 17.0+**
- **Swift 5.9+**
- No external dependencies required

## Build Steps

1. **Clone or download** this repository
2. **Open** `WordDash.xcodeproj` in Xcode
3. **Select** a target device or simulator (iPhone recommended)
4. **Build and Run** (⌘R)

> **Note**: The project uses SpriteKit with programmatic rendering (no storyboards). All UI is built in code.

## Project Structure

```
WordDash/
├── WordDash.xcodeproj/
├── WordDash/
│   ├── Sources/
│   │   ├── AppDelegate.swift          # App lifecycle
│   │   ├── SceneDelegate.swift        # Window scene management
│   │   ├── Models/
│   │   │   ├── TileModel.swift        # Tile data (letter, special type, ice state)
│   │   │   ├── LevelConfig.swift      # Level configuration (Codable)
│   │   │   ├── GameState.swift        # In-game state tracking
│   │   │   └── PlayerProgress.swift   # Persistent progress model
│   │   ├── Engine/
│   │   │   ├── BoardModel.swift       # Grid state, adjacency, gravity, refill
│   │   │   ├── WordValidator.swift    # Dictionary lookup, profanity filter, hints
│   │   │   ├── ScoringEngine.swift    # Score calculation with all multipliers
│   │   │   └── PowerUpSystem.swift    # Power-up inventory and execution
│   │   ├── Scenes/
│   │   │   ├── GameViewController.swift  # UIKit view controller hosting SKView
│   │   │   ├── GameScene.swift        # Main gameplay scene (rendering, input, HUD)
│   │   │   ├── MainMenuScene.swift    # Main menu (Play, Store, Settings)
│   │   │   ├── LevelMapScene.swift    # Level selection grid
│   │   │   └── SettingsScene.swift    # Sound/haptics toggles, reset progress
│   │   ├── Managers/
│   │   │   ├── LevelManager.swift     # JSON level config loader
│   │   │   └── PersistenceManager.swift # UserDefaults-based save/load
│   │   └── Utils/
│   │       ├── Constants.swift        # Game constants, letter values, multipliers
│   │       └── LetterGenerator.swift  # Weighted random letter generation
│   ├── Resources/
│   │   ├── Levels/
│   │   │   ├── level_1.json ... level_10.json
│   │   └── Dictionary/
│   │       ├── wordlist.txt           # 358K+ English words
│   │       └── profanity.txt          # Profanity block list
│   ├── Assets.xcassets/               # All image assets
│   └── Info.plist
├── WordDashTests/
│   └── WordDashTests.swift            # Unit tests
└── README.md
```

## Level Configuration

Levels are defined as JSON files in `Resources/Levels/`. Each level supports two goal types:

### scoreTimed
```json
{
    "levelNumber": 1,
    "goalType": "scoreTimed",
    "boardSize": 7,
    "targetScore": 100,
    "timeLimitSeconds": 120,
    "addTimeOnClearSeconds": 0,
    "starThresholds": {
        "oneStar": 100,
        "twoStar": 200,
        "threeStar": 350
    }
}
```

### clearIceMoves
```json
{
    "levelNumber": 3,
    "goalType": "clearIceMoves",
    "boardSize": 7,
    "iceTilesToClearTarget": 5,
    "moveLimit": 15,
    "icePositions": [
        {"row": 2, "col": 2},
        {"row": 3, "col": 3}
    ],
    "starThresholds": {
        "oneStar": 50,
        "twoStar": 100,
        "threeStar": 200
    }
}
```

To add more levels, create additional `level_N.json` files and update `LevelManager` to load them.

## Scoring System

| Component | Formula |
|-----------|---------|
| Letter Values | A,E,I,O,N,R,T,L,S,U=1; D,G=2; B,C,M,P=3; F,H,V,W,Y=4; K=5; J,X=8; Q,Z=10 |
| Word Score | `(sum of letter values) × lengthMultiplier × streakMultiplier × diminishingMultiplier` |
| Length Multiplier | 3→1.0, 4→1.2, 5→1.5, 6→1.9, 7→2.4, 8+→3.0 |
| Streak | +0.2 per consecutive word within 4s (max 3.0×) |
| Diminishing | 1st use: 100%, 2nd: 50%, 3rd+: 10% |
| Cascade Bonus | Step 1: +10, Step 2: +25, Step 3: +50, Step 4+: +100 |

## Asset Replacement

All assets use placeholder images. To replace with production art:

1. Navigate to `WordDash/Assets.xcassets/`
2. Replace the PNG files in each `.imageset` folder:

| Asset | Size | Purpose |
|-------|------|---------|
| `tile_normal.png` | 128×128 | Default letter tile background |
| `tile_selected.png` | 128×128 | Selected/highlighted tile |
| `tile_ice_2.png` | 128×128 | Intact ice overlay |
| `tile_ice_1.png` | 128×128 | Cracked ice overlay |
| `tile_special_bomb.png` | 128×128 | Bomb special tile |
| `tile_special_laser.png` | 128×128 | Laser special tile |
| `tile_special_cross.png` | 128×128 | Cross laser special tile |
| `tile_special_mine.png` | 128×128 | Mine special tile |
| `tile_special_wildcard.png` | 128×128 | Wildcard special tile |
| `icon_hint.png` | 64×64 | Hint power-up icon |
| `icon_bomb.png` | 64×64 | Bomb power-up icon |
| `icon_laser.png` | 64×64 | Laser power-up icon |
| `icon_cross.png` | 64×64 | Cross laser power-up icon |
| `icon_mine.png` | 64×64 | Mine power-up icon |
| `icon_shuffle.png` | 64×64 | Shuffle icon |
| `bg_menu.png` | 390×844 | Menu background |
| `bg_game.png` | 390×844 | Game background |

For @2x and @3x support, add `tile_normal@2x.png` (256×256) and `tile_normal@3x.png` (384×384) variants and update the `Contents.json` in each imageset.

> **Note**: The current MVP uses programmatic SpriteKit shapes for tile rendering rather than image assets. The asset catalog images are structured for easy migration to sprite-based rendering.

## Unit Tests

Run tests via Xcode (⌘U) or `xcodebuild test`. Tests cover:

- **Adjacency**: All 8 directions, non-adjacent rejection, same-position rejection
- **Path Validation**: No tile reuse, adjacency chain validation
- **Backtracking**: Correct removal of last tile when dragging back
- **Scoring**: Letter values, base scores, length multipliers, cascade bonuses
- **Diminishing Repeats**: 1st use (100%), 2nd use (50%), 3rd+ use (10%)
- **Streaks**: Increase within window, reset outside window, cap at 3.0×
- **Special Tile Spawns**: Correct type for each word length
- **Ice Mechanics**: Two-hit clearing behavior
- **Board Model**: Fill, bomb/laser/cross-laser affected tiles, bounds checking

## License

This project is provided as-is for educational and development purposes.
