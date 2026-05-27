# 0002. Pair-merge ×3 for 2187 mode (not triple-merge)

Date: 2026-05-27

## Status

Accepted

## Context

The new 2187 mode targets a win value of **2187 = 3⁷** with starting tiles of value 3. Three rule sets can reach 2187 from 3:

1. **Pair-merge ×3** — two equal tiles collide and produce `value × 3`. Ladder: `3 → 9 → 27 → 81 → 243 → 729 → 2187`. Seven merges, two tiles per merge.
2. **Triple-merge ×1** — three equal tiles collide and produce `value × 3`. Same ladder, but three tiles per merge.
3. **Pair-merge ×2** — relabel 2048 with 3s, doubling on each merge. Reaches 3072, never 2187. Win value would not match the mode name.

Rule 3 is excluded because the mode name's whole point is hitting 2187. The real choice is between rules 1 and 2.

The existing 2048 implementation is built around pair-merge: `applyMove` walks each travel line and asks "does the next occupied cell match this one?". Triple-merge would have to ask "do the next *two* occupied cells match?" — a different state machine, and one with awkward edge cases (e.g. four-in-a-row produces one merge of three plus an orphan; the order in which the three-tile group is selected matters).

## Decision

Use **pair-merge ×3** for 2187 mode. Two equal tiles collide; the resulting tile takes value `oldValue × 3`.

## Alternatives considered

**Triple-merge ×1.** Authentic to the name's number-theoretic structure (three threes make a nine, etc.). Rejected because:
- The slide-merge loop is structurally different from 2048's, so the [[two parallel logic files]] decision (ADR-0001) buys less — `applyMove` wouldn't even share its shape.
- Four-in-a-line ambiguity (`3 3 3 3` swiped: do you make one 9 + leftover 3, or fail to merge?) introduces a design decision that has no obvious right answer.
- Game-feel research on triple-merge variants (Threes!, lookalikes) shows they play very differently from 2048 — pacing is slower, planning horizons longer. The user explicitly asked for a 2048-mode variant, not a different game.

## Consequences

- 2187 ladder has seven distinct values (vs. 2048's eleven). The tile-palette ramp is shorter; visually still legible.
- Per-mode high scores ([[per-mode-leaderboards]]) are necessary because scoring distributions differ.
- The hex-board side-3 (19 cells) sizing decision interacts with this rule: pair-merge ×3 wins in roughly 64 base-3 tiles vs. 2048's ~1024 base-2 tiles, so games are shorter — the smaller cell-count differential matters less.
