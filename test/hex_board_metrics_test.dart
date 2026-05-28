import 'package:flutter_test/flutter_test.dart';
import 'package:free_2048/game/hex_logic.dart';
import 'package:free_2048/widgets/hex_board_metrics.dart';

void main() {
  group('HexBoardMetrics axial→pixel', () {
    test('cell (0, 0) sits at the board centre', () {
      final m = HexBoardMetrics(300);
      final c = m.centerOf(0.0, 0.0);
      expect(c.dx, closeTo(150, 0.01));
      expect(c.dy, closeTo(150, 0.01));
    });

    test('every cell on the side-3 hexagon stays within the board', () {
      final m = HexBoardMetrics(300);
      for (var i = 0; i < kHexCellCount; i++) {
        final c = indexToAxial(i);
        final p = m.centerOf(c.q.toDouble(), c.r.toDouble());
        // Each cell centre, plus the cell's circumradius, must be within the
        // 0..300 board square.
        expect(p.dx - m.cellSize >= -0.5 && p.dx + m.cellSize <= 300.5, isTrue,
            reason: 'cell ${c.q},${c.r} x=${p.dx} off-board');
        expect(p.dy - m.cellSize >= -0.5 && p.dy + m.cellSize <= 300.5, isTrue,
            reason: 'cell ${c.q},${c.r} y=${p.dy} off-board');
      }
    });
  });

  group('directionFromSwipe', () {
    test('pure-right swipe is east', () {
      expect(directionFromSwipe(const Offset(50, 0)), HexDirection.east);
    });

    test('pure-left swipe is west', () {
      expect(directionFromSwipe(const Offset(-50, 0)), HexDirection.west);
    });

    test('up-right swipe is northeast', () {
      // Screen coords: dx > 0, dy < 0.
      expect(directionFromSwipe(const Offset(50, -86.6)),
          HexDirection.northeast);
    });

    test('up-left swipe is northwest', () {
      expect(directionFromSwipe(const Offset(-50, -86.6)),
          HexDirection.northwest);
    });

    test('down-right swipe is southeast', () {
      expect(directionFromSwipe(const Offset(50, 86.6)),
          HexDirection.southeast);
    });

    test('down-left swipe is southwest', () {
      expect(directionFromSwipe(const Offset(-50, 86.6)),
          HexDirection.southwest);
    });

    test('zero-distance swipe returns null', () {
      expect(directionFromSwipe(Offset.zero), isNull);
      expect(directionFromSwipe(const Offset(2, 1)), isNull); // below threshold
    });
  });
}
