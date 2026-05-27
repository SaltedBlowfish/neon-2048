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
}
