# 0001. Two parallel game-logic files, not a polymorphic interface

Date: 2026-05-27

## Status

Accepted

## Context

Neon 2048 is gaining a second game mode, **2187 mode**, that uses a hexagonal board and base-3 merge arithmetic. The existing `lib/game/game_logic.dart` was written for a single 4×4 square board with four swipe directions, base-2 merge arithmetic, and integer (row, col) coordinates.

The two modes share the high-level "swipe → slide-and-merge → spawn → check end-state" loop but disagree on almost every primitive:

- **Direction set** — 4 cardinal vs 6 hex axes
- **Coordinate system** — (row, col) on a 4×4 grid vs axial (q, r) on a hexagon
- **Travel lines** — `_travelLines()` is square-specific; hex needs a different generator that walks from each edge along an axis
- **Merge multiplier** — 2 vs 3
- **Spawn values** — {2, 4} vs {3, 9}
- **Win value** — 2048 vs 2187
- **Cell count** — 16 vs 19

`MoveResult` and `TileMove` are already coord-agnostic (they use opaque `int` cell indices) and can stay shared.

## Decision

Keep `game_logic.dart` as the 2048-mode implementation. Add a new `hex_logic.dart` for 2187 mode. `GameScreen` branches on the active mode and calls into the appropriate file.

`MoveResult` and `TileMove` are extracted as the only shared types.

## Alternatives considered

**Polymorphic `GameLogic` interface.** Define `abstract class GameLogic { MoveResult applyMove(Direction d); int? spawnTile(); bool canMove(); }`. Square and hex implement it. Rejected because the `Direction` types disagree (4 vs 6 values) — the abstraction either becomes a lowest-common-denominator (string or int) and loses type safety, or becomes generic (`GameLogic<D extends Direction>`) and pushes the type parameter through every caller. Not worth the cost for two implementations.

**Generalize in place.** Parameterize `_travelLines` by a `List<List<int>>` of pre-computed lines, replace `cellRow/cellCol` with a `Neighbors` abstraction. Rejected because square-grid coord helpers leak into widget code (`cellRow(index)` for animation positions); abstracting them all forces a larger surface refactor before the second mode is even prototyped.

## Consequences

- The slide-merge loop in `applyMove` will appear twice in slightly different forms. Acceptable: the loops differ in their travel-line generation and merge-multiplier constants, so the apparent duplication is shallower than it looks.
- If a third mode is ever added, the duplication cost will start to outweigh the abstraction cost — revisit this ADR.
- `GameScreen` carries mode-aware branching. Encapsulate that branching behind a single mode-router rather than scattering `if (mode == X)` throughout the widget tree.
