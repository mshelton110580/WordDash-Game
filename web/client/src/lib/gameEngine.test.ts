import { describe, it, expect } from 'vitest';
import { getChainMultiplier } from './gameEngine';

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
