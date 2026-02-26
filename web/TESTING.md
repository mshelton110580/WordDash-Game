# Web Testing Environment

This project now includes a repeatable web test workflow for gameplay logic (dictionary quality, hint quality, chain multiplier rules).

## Commands

From repo root:

- `pnpm -C web run check` — TypeScript type-check.
- `pnpm -C web run test` — Run Vitest suite.
- `pnpm -C web run test:web` — Run both check + tests.
- `pnpm -C web run dev` — Local manual playtesting environment.

## What is covered

Current automated tests include:

- Link/chain multiplier schedule and explosive drop-one behavior.
- Dictionary filtering rejects nonsense/obscure entries while keeping common words.
- Hint path selection prioritizes common English words.

## Adding more gameplay tests

Place new tests next to engine code:

- `web/client/src/lib/*.test.ts`

Use mocked `fetch` when testing dictionary behavior so tests stay deterministic and do not depend on network/CDN availability.
