import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  createGameState,
  createTile,
  findHintPath,
  isValidWord,
  loadWordList,
  type LevelConfig,
} from './gameEngine';

describe('dictionary quality + hint quality', () => {
  const mockedFetch = vi.fn(async (input: RequestInfo | URL) => {
    const url = String(input);
    if (url.includes('wordlist.txt')) {
      return {
        ok: true,
        text: async () => ['AAA', 'AAHED', 'HOUSE', 'CAT', 'TREE', 'DOG', 'CLOUD'].join('\n'),
      } as Response;
    }

    if (url.includes('common_words.txt')) {
      return {
        ok: true,
        text: async () => ['HOUSE', 'CAT', 'TREE', 'DOG', 'CLOUD'].join('\n'),
      } as Response;
    }

    return {
      ok: false,
      text: async () => '',
    } as Response;
  });

  beforeEach(() => {
    vi.stubGlobal('fetch', mockedFetch);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    mockedFetch.mockClear();
  });

  it('filters nonsense/obscure entries while keeping common words', async () => {
    await loadWordList();

    expect(isValidWord('house')).toBe(true);
    expect(isValidWord('cat')).toBe(true);

    // nonsense / obscure shapes should be rejected
    expect(isValidWord('aaa')).toBe(false);
    expect(isValidWord('aahed')).toBe(false);
  });

  it('hint search favors common words', async () => {
    await loadWordList();

    const level: LevelConfig = {
      levelNumber: 1,
      goalType: 'scoreTimed',
      boardSize: 7,
      targetScore: 100,
      timeLimitSeconds: 120,
      starThresholds: { oneStar: 100, twoStar: 200, threeStar: 300 },
    };

    const state = createGameState(level);

    // Fill deterministic board with Z, then place CAT path.
    for (let r = 0; r < state.boardSize; r++) {
      for (let c = 0; c < state.boardSize; c++) {
        state.board[r][c] = createTile('Z', r, c);
      }
    }
    state.board[0][0] = createTile('C', 0, 0);
    state.board[0][1] = createTile('A', 0, 1);
    state.board[0][2] = createTile('T', 0, 2);

    const hintPath = findHintPath(state);
    const hintedWord = hintPath.map(t => t.letter).join('');

    expect(hintedWord).toBe('CAT');
  });
});
