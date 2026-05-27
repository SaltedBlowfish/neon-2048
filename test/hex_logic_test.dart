import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:free_2048/game/hex_logic.dart';

void main() {
  group('hex coords', () {
    test('the side-3 hexagon has 19 cells', () {
      expect(kHexCellCount, 19);
      expect(emptyHexGrid(), List<int>.filled(19, 0));
    });

    test('axialToIndex and indexToAxial round-trip for every cell', () {
      for (var i = 0; i < kHexCellCount; i++) {
        final coord = indexToAxial(i);
        expect(axialToIndex(coord.q, coord.r), i,
            reason: 'round-trip failed at index $i ($coord)');
      }
    });

    test('returns null for axial coords outside the hexagon', () {
      // (3, 0) has |q| = 3 > 2 — outside the side-3 hexagon.
      expect(axialToIndex(3, 0), isNull);
      // (-2, -1) — q+r = -3, |q+r| > 2 — outside.
      expect(axialToIndex(-2, -1), isNull);
    });

    test('all 19 enumerated cells satisfy max(|q|, |r|, |q+r|) <= 2', () {
      for (var i = 0; i < kHexCellCount; i++) {
        final c = indexToAxial(i);
        final s = -c.q - c.r; // cube z
        expect(c.q.abs() <= 2 && c.r.abs() <= 2 && s.abs() <= 2, isTrue,
            reason: 'cell $i ($c) is outside the side-3 hexagon');
      }
    });
  });

  group('hex directions and travel lines', () {
    test('each of the six directions has 5 travel lines totalling 19 cells',
        () {
      for (final dir in HexDirection.values) {
        final lines = hexTravelLines(dir);
        expect(lines.length, 5, reason: 'wrong line count for $dir');
        final total = lines.fold<int>(0, (sum, l) => sum + l.length);
        expect(total, kHexCellCount,
            reason: 'lines for $dir do not cover all cells');
        // Lines for a side-3 hexagon should have lengths {3,4,5,4,3} in some
        // order.
        final lengths = lines.map((l) => l.length).toList()..sort();
        expect(lengths, [3, 3, 4, 4, 5]);
      }
    });

    test('every cell appears in exactly one line per direction', () {
      for (final dir in HexDirection.values) {
        final lines = hexTravelLines(dir);
        final seen = <int>{};
        for (final line in lines) {
          for (final idx in line) {
            expect(seen.add(idx), isTrue,
                reason: 'cell $idx duplicated in $dir');
          }
        }
        expect(seen.length, kHexCellCount);
      }
    });

    test('the first cell in each line is the one a tile reaches first', () {
      // For HexDirection.east, the leftmost cell on each row is the head of
      // its line — but the head should be the rightmost (since tiles travel
      // east). Check the canonical case: the line containing the centre cell
      // (0, 0) for east must start at the eastmost cell (q=2, r=0).
      final eastLines = hexTravelLines(HexDirection.east);
      final centreLine = eastLines.firstWhere(
        (l) => l.contains(axialToIndex(0, 0)!),
      );
      expect(centreLine.first, axialToIndex(2, 0));
      expect(centreLine.last, axialToIndex(-2, 0));
    });
  });

  group('applyHexMove', () {
    // Build a fresh grid with explicit values at given axial coords, zeros
    // elsewhere. Helper keeps test bodies legible.
    List<int> hexGridFrom(Map<Axial, int> values) {
      final grid = emptyHexGrid();
      values.forEach((coord, value) {
        final idx = axialToIndex(coord.q, coord.r);
        if (idx == null) throw ArgumentError('$coord is outside the board');
        grid[idx] = value;
      });
      return grid;
    }

    test('an empty board is unchanged in every direction', () {
      for (final dir in HexDirection.values) {
        final result = applyHexMove(emptyHexGrid(), dir);
        expect(result.changed, isFalse);
      }
    });

    test('a lone tile slides to the eastmost cell on its row', () {
      final grid = hexGridFrom({const Axial(-2, 0): 3});
      final result = applyHexMove(grid, HexDirection.east);
      expect(result.changed, isTrue);
      expect(result.gained, 0);
      // Expect: only (2, 0) holds the 3.
      expect(result.grid[axialToIndex(2, 0)!], 3);
      expect(result.grid[axialToIndex(-2, 0)!], 0);
    });

    test('two equal 3s on the same row merge into a 9 with gained == 9', () {
      final grid = hexGridFrom({
        const Axial(-2, 0): 3,
        const Axial(-1, 0): 3,
      });
      final result = applyHexMove(grid, HexDirection.east);
      expect(result.changed, isTrue);
      expect(result.gained, 9);
      expect(result.grid[axialToIndex(2, 0)!], 9);
      // Every other cell zero.
      for (var i = 0; i < kHexCellCount; i++) {
        if (i == axialToIndex(2, 0)) continue;
        expect(result.grid[i], 0);
      }
    });

    test('three 3s in a row: first two merge, third is stranded one cell back',
        () {
      final grid = hexGridFrom({
        const Axial(-2, 0): 3,
        const Axial(-1, 0): 3,
        const Axial(0, 0): 3,
      });
      final result = applyHexMove(grid, HexDirection.east);
      expect(result.gained, 9);
      expect(result.grid[axialToIndex(2, 0)!], 9);
      expect(result.grid[axialToIndex(1, 0)!], 3);
    });

    test('a freshly-merged tile cannot merge again in the same swipe', () {
      // 3,3,9,0 swiped east: the two 3s merge into a 9, but that new 9 must
      // not then merge with the existing 9.
      final grid = hexGridFrom({
        const Axial(-2, 0): 3,
        const Axial(-1, 0): 3,
        const Axial(0, 0): 9,
      });
      final result = applyHexMove(grid, HexDirection.east);
      expect(result.grid[axialToIndex(2, 0)!], 9);
      expect(result.grid[axialToIndex(1, 0)!], 9);
      expect(result.gained, 9); // only the 3+3 merge contributed
    });

    test('two pairs on the same line both merge in one swipe', () {
      // 3,3,9,9 east -> 9,27 (two independent merges).
      final grid = hexGridFrom({
        const Axial(-2, 0): 3,
        const Axial(-1, 0): 3,
        const Axial(0, 0): 9,
        const Axial(1, 0): 9,
      });
      final result = applyHexMove(grid, HexDirection.east);
      expect(result.grid[axialToIndex(2, 0)!], 27);
      expect(result.grid[axialToIndex(1, 0)!], 9);
      expect(result.gained, 9 + 27);
    });

    test('produces TileMoves describing every sliding tile', () {
      final grid = hexGridFrom({
        const Axial(-2, 0): 3,
        const Axial(-1, 0): 3,
      });
      final result = applyHexMove(grid, HexDirection.east);
      expect(result.moves.length, 2);
      expect(result.moves.every((m) => m.merging), isTrue);
      expect(result.moves.every((m) => m.to == axialToIndex(2, 0)), isTrue);
    });

    test('processes multiple travel lines independently in one swipe', () {
      // Two pairs on two different rows must both merge in a single east
      // swipe. This catches any bug where `slot` is not reset per line.
      final grid = hexGridFrom({
        const Axial(-2, 0): 3,
        const Axial(-1, 0): 3,
        const Axial(-2, 1): 9,
        const Axial(-1, 1): 9,
      });
      final result = applyHexMove(grid, HexDirection.east);
      expect(result.grid[axialToIndex(2, 0)!], 9);
      expect(result.grid[axialToIndex(1, 1)!], 27);
      expect(result.gained, 9 + 27);
    });
  });

  group('spawnHexTile', () {
    test('returns null on a full board', () {
      final grid = List<int>.filled(kHexCellCount, 3);
      expect(spawnHexTile(grid, Random(0)), isNull);
    });

    test('places exactly one tile of value 3 or 9 in an empty cell', () {
      final grid = emptyHexGrid();
      final idx = spawnHexTile(grid, Random(0));
      expect(idx, isNotNull);
      expect(grid[idx!] == 3 || grid[idx] == 9, isTrue);
      // No other cell touched.
      expect(grid.where((v) => v != 0).length, 1);
    });

    test('spawns value 9 roughly 10% of the time over many trials', () {
      final random = Random(42);
      var nines = 0;
      const trials = 5000;
      for (var t = 0; t < trials; t++) {
        final grid = emptyHexGrid();
        final idx = spawnHexTile(grid, random)!;
        if (grid[idx] == 9) nines++;
      }
      // 10% ± 2% wide band — generous to avoid flakiness.
      expect(nines / trials, closeTo(0.10, 0.02));
    });
  });

  group('canHexMove', () {
    test('true when any cell is empty', () {
      expect(canHexMove(emptyHexGrid()), isTrue);
    });

    test('true on a full board with at least one adjacent equal pair', () {
      // Fill every cell with 3 — adjacent pairs everywhere.
      final grid = List<int>.filled(kHexCellCount, 3);
      expect(canHexMove(grid), isTrue);
    });

    test('false on a full board with no adjacent equal pairs', () {
      // Hand-crafted: fill cells with alternating values whose neighbours never
      // match. Easiest construction: use 3, 9, 27 in a pattern keyed on
      // (q + 2r) mod 3.
      final grid = emptyHexGrid();
      const palette = [3, 9, 27];
      for (var i = 0; i < kHexCellCount; i++) {
        final c = indexToAxial(i);
        grid[i] = palette[((c.q + 2 * c.r) % 3 + 3) % 3];
      }
      // Sanity check: this construction really is full.
      expect(grid.contains(0), isFalse);
      expect(canHexMove(grid), isFalse);
    });
  });

  group('highestHexTile', () {
    test('returns 0 for an empty board', () {
      expect(highestHexTile(emptyHexGrid()), 0);
    });

    test('returns the largest value on the board', () {
      final grid = emptyHexGrid();
      grid[axialToIndex(0, 0)!] = 81;
      grid[axialToIndex(1, 0)!] = 9;
      expect(highestHexTile(grid), 81);
    });
  });
}
