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
}
