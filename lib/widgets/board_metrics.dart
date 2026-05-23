import 'dart:ui';

import '../game/game_logic.dart';

/// Pixel geometry for the board square: where each cell sits and how big it is.
class BoardMetrics {
  /// Side length of the whole board square, in pixels.
  final double size;

  /// Padding between the board edge and the first cell.
  final double pad;

  /// Gap between adjacent cells.
  final double gap;

  /// Side length of a single cell.
  final double cell;

  BoardMetrics(this.size)
      : pad = size * 0.05,
        gap = size * 0.028,
        cell = (size - 2 * (size * 0.05) - (kGridSide - 1) * (size * 0.028)) /
            kGridSide;

  double get stride => cell + gap;

  /// Top-left pixel offset of a (possibly fractional) cell coordinate.
  Offset topLeftOf(double row, double col) =>
      Offset(pad + col * stride, pad + row * stride);
}
