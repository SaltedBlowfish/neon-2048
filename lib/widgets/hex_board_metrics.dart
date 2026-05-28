import 'dart:math';
import 'dart:ui';

import '../game/hex_logic.dart';

/// Pixel geometry for the hex board: where each cell sits and how big it is.
///
/// Uses the pointy-top axial→pixel formulas:
///   x = size · √3 · (q + r/2)
///   y = size · 3/2 · r
/// where `size` is the cell's circumradius (centre → vertex). The whole layout
/// is then translated so cell (0, 0) sits at the centre of a `size × size`
/// square board.
class HexBoardMetrics {
  static const double _padFraction = 0.06;

  /// Side length of the board square in pixels.
  final double size;

  /// Cell circumradius (centre to vertex). The two pointy vertices of a cell
  /// are `cellSize` pixels above and below the cell centre.
  final double cellSize;

  HexBoardMetrics(this.size) : cellSize = _cellSizeFor(size);

  /// Side-3 hexagon fits inside a square of side `(2·kHexSide - 1)·√3·cellSize`
  /// wide and `(3·kHexSide - 1)·cellSize` tall (for `kHexSide = 3`: ≈8.66·cell
  /// wide, 8·cell tall). Pick the cell size that makes the wider dimension fit
  /// within `size - 2·pad`.
  static double _cellSizeFor(double boardSize) {
    final usable = boardSize - 2 * (boardSize * _padFraction);
    final maxByHeight = usable / 8.0;
    final maxByWidth = usable / (5 * sqrt(3));
    return maxByHeight < maxByWidth ? maxByHeight : maxByWidth;
  }

  /// Centre pixel offset of a (possibly fractional) axial coordinate.
  Offset centerOf(double q, double r) {
    final x = cellSize * sqrt(3) * (q + r / 2);
    final y = cellSize * 1.5 * r;
    return Offset(size / 2 + x, size / 2 + y);
  }
}

/// Maps a swipe delta to the closest hex direction, or null if the swipe is
/// shorter than [_minSwipeDistance] pixels.
///
/// The six hex directions are 60° apart. Compute the swipe's angle (with the
/// y axis flipped so up is positive, matching math convention), then pick the
/// direction whose canonical angle is within 30° of the swipe.
HexDirection? directionFromSwipe(Offset delta) {
  if (delta.distance < minSwipeDistance) return null;
  // Flip y so positive is up (math convention).
  final angle = atan2(-delta.dy, delta.dx);
  // Nudge into [0, 2π).
  final twoPi = 2 * pi;
  final a = (angle % twoPi + twoPi) % twoPi;
  // Direction whose canonical angle is closest. 30° wedge = π/6 radians.
  // Canonical angles (math convention):
  //   east        = 0
  //   northeast   = π/3
  //   northwest   = 2π/3
  //   west        = π
  //   southwest   = 4π/3
  //   southeast   = 5π/3
  const directions = <HexDirection>[
    HexDirection.east,       // 0
    HexDirection.northeast,  // π/3
    HexDirection.northwest,  // 2π/3
    HexDirection.west,       // π
    HexDirection.southwest,  // 4π/3
    HexDirection.southeast,  // 5π/3
  ];
  // Shift by +π/6 so each 60° wedge maps to one direction via floor division.
  final shifted = (a + pi / 6) % twoPi;
  final index = (shifted / (pi / 3)).floor() % 6;
  return directions[index];
}

const double minSwipeDistance = 18;
