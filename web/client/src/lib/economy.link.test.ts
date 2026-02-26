import { beforeEach, describe, expect, it, vi } from 'vitest';

function mockStorage() {
  const store = new Map<string, string>();
  return {
    getItem: (k: string) => (store.has(k) ? store.get(k)! : null),
    setItem: (k: string, v: string) => { store.set(k, v); },
    removeItem: (k: string) => { store.delete(k); },
    clear: () => { store.clear(); },
  };
}

describe('chain link store wiring', () => {
  beforeEach(() => {
    vi.resetModules();
    vi.stubGlobal('localStorage', mockStorage());
  });

  it('exposes a configured chain link price', async () => {
    const { GameEconomyConfig } = await import('./economy');
    expect(GameEconomyConfig.storePrices.link).toBe(400);
  });

  it('can purchase chain link and increments inventory', async () => {
    const { CoinManager, loadInventory, purchasePowerup } = await import('./economy');
    CoinManager.resetToStarting();

    const before = loadInventory().link;
    const purchased = purchasePowerup('link');
    expect(purchased).toBe(true);
    const after = loadInventory().link;
    expect(after).toBe(before + 1);
  });
});
