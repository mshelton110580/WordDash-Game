import { describe, it, expect } from 'vitest';
import { createGameState, forceResolveChainOnTimer, getChainMultiplier, type LevelConfig } from './gameEngine';

describe('Link chain multiplier schedule', () => {
  it('matches the configured schedule', () => {
    expect(getChainMultiplier(1)).toBe(1);
    expect(getChainMultiplier(2)).toBe(2);
    expect(getChainMultiplier(3)).toBe(3);
    expect(getChainMultiplier(4)).toBe(4);
    expect(getChainMultiplier(5)).toBe(6);
    expect(getChainMultiplier(6)).toBe(8);
    expect(getChainMultiplier(7)).toBe(10);
    expect(getChainMultiplier(11)).toBe(10);
  });

  it('drops one level when chain ends due to explosive', () => {
    expect(getChainMultiplier(1, true)).toBe(1);
    expect(getChainMultiplier(2, true)).toBe(1);
    expect(getChainMultiplier(3, true)).toBe(2);
    expect(getChainMultiplier(6, true)).toBe(6);
    expect(getChainMultiplier(8, true)).toBe(10);
  });
});


describe('Timer chain resolution win handling', () => {
  it('marks timed level as won if chain resolution reaches target score at timer end', () => {
    const level: LevelConfig = {
      levelNumber: 99,
      goalType: 'scoreTimed',
      boardSize: 7,
      targetScore: 100,
      timeLimitSeconds: 1,
      starThresholds: { oneStar: 100, twoStar: 150, threeStar: 200 },
    };

    const state = createGameState(level);
    state.score = 50;
    state.chainMode.chainActive = true;
    state.chainMode.chainWordCount = 2; // multiplier 2
    state.chainMode.chainBasePoints = 30; // +60 => 110 total
    state.chainMode.linkedTiles.add('0,0');

    forceResolveChainOnTimer(state);

    expect(state.score).toBe(110);
    expect(state.isWon).toBe(true);
    expect(state.isGameOver).toBe(true);
  });
});
