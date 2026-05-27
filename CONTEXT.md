# Glossary

Domain language for Neon 2048. Implementation lives in `lib/`; this file is vocabulary only.

## Game modes

- **Mode** — gameplay variant. Two exist:
  - **2048 mode** — original. Square 4×4 grid. Tiles start at 2 (90%) or 4 (10%). Win at 2048.
  - **2187 mode** — new. Hexagonal grid, side-3 (19 cells). Tiles start at 3. Win at 2187 (3⁷).

## Merge mechanics

- **Pair-merge** — two tiles of equal value collide during a swipe and combine into one tile whose value is `value × multiplier`.
  - **2048 multiplier** — 2. `2 + 2 → 4`, `4 + 4 → 8`, ...
  - **2187 multiplier** — 3. `3 + 3 → 9`, `9 + 9 → 27`, ...
- **Merge chain** — a single swipe may produce multiple independent merges, but a freshly-merged tile cannot merge again in the same swipe (rule shared by both modes).

## Tiles

- **Tile value** — the integer printed on a tile. Always a power of the mode's multiplier times the spawn base.
- **Spawn** — placement of a new tile into a random empty cell after each move.
  - **2048 spawn** — value 2 (90%) or 4 (10%).
  - **2187 spawn** — value 3 (90%) or 9 (10%).

## Hex geometry (2187 mode)

- **Pointy-top hexagon** — vertex points up; the six swipe directions are E, W, NE, NW, SE, SW.
- **Axial coordinates** — `(q, r)` integer pair. The 19 cells of the side-3 hexagon are the points where `max(|q|, |r|, |q+r|) ≤ 2`.
- **Cell index** — flat-list index `0..18` used by `MoveResult`/`TileMove` and view code; the logic file owns the `axial ↔ index` mapping.
- **Travel line** — sequence of cell indices along one of the three hex axes, ordered so the cell a tile reaches first comes first (mirrors `_travelLines` in 2048 mode).
- **Swipe wedge** — 60° angular slice of swipe-vector space mapping a touch gesture to one of the six hex directions.

## Theming

- **Mode palette** — per-mode tile color ramp:
  - **2048 palette** — cyan ramp (existing).
  - **2187 palette** — red ramp (crimson → hot pink), distinct from the `danger` accent reserved for game-over states.
- **Tile shape** — rendering shape of a played tile: rounded square in 2048 mode, hexagon in 2187 mode (matching the cell shape).
