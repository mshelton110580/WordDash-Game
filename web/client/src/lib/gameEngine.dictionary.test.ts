import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  createGameState,
  createTile,
  findHintPath,
  isValidWord,
  loadWordList,
  type LevelConfig,
} from './gameEngine';

describe('Collins validation + Oxford hint dictionary', () => {
  const mockedFetch = vi.fn();

  beforeEach(() => {
    mockedFetch.mockReset();
    mockedFetch.mockImplementation(async (input: RequestInfo | URL) => {
      const url = String(input);

      if (url.includes('wordlist.txt')) {
        return {
          ok: true,
          text: async () => ['AAA', 'AAHED', 'HOUSE', 'CAT', 'TREE', 'DOG', 'CLOUD', 'ZZZ'].join('\n'),
        } as Response;
      }

      if (url.includes('oxford3000.txt')) {
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

    vi.stubGlobal('fetch', mockedFetch);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    mockedFetch.mockReset();
  });

  it('validates gameplay words against Collins dictionary', async () => {
    await loadWordList();

    expect(isValidWord('house')).toBe(true);
    expect(isValidWord('cat')).toBe(true);
    // present in mocked Collins list
    expect(isValidWord('aaa')).toBe(true);
    expect(isValidWord('aahed')).toBe(true);
    // absent from mocked Collins list
    expect(isValidWord('qwerty')).toBe(false);
  });

  it('uses bundled Collins fallback when dictionary fetch fails', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => undefined);

    mockedFetch
      .mockImplementationOnce(async () => { throw new Error('network unavailable'); })
      .mockImplementationOnce(async () => { throw new Error('network unavailable'); });

    await loadWordList();

    // Present in bundled Collins fallback additions
    expect(isValidWord('aahed')).toBe(true);
    expect(isValidWord('aardvark')).toBe(true);
    // Still blocked by profanity filter
    expect(isValidWord('fuck')).toBe(false);

    consoleErrorSpy.mockRestore();
  });

  it('does not request legacy common_words hint file', async () => {
    await loadWordList();

    const calls = mockedFetch.mock.calls.map(([input]) => String(input));
    expect(calls.some(url => url.includes('common_words.txt'))).toBe(false);
  });

  it('hint search uses Oxford hint list', async () => {
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
    // ZZZ is in mocked Collins dictionary but not Oxford list,
    // so hint should prefer CAT (Oxford-listed).
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
