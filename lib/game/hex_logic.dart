// Pure hex-board logic for 2187 mode — no Flutter. Everything here is
// unit-tested.

import 'dart:math';

/// Side length of the hexagonal board, in cells from centre to a vertex.
const int kHexSide = 3;

/// Total number of cells in the side-3 hexagonal board. Derived from the
/// formula 3·n·(n-1) + 1 for a hexagon of side n.
const int kHexCellCount = 3 * kHexSide * (kHexSide - 1) + 1; // 19

/// Reaching a tile of this value wins the game.
const int kHex2187WinValue = 2187;

/// Multiplier applied on each pair-merge in 2187 mode.
const int kHex2187Multiplier = 3;

/// An axial hex coordinate. Equivalent to cube coords (q, r, s) with s = -q-r.
class Axial {
  final int q;
  final int r;
  const Axial(this.q, this.r);

  @override
  bool operator ==(Object other) =>
      other is Axial && other.q == q && other.r == r;

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => 'Axial($q, $r)';
}

/// Enumeration of the 19 valid cells in row-major order:
/// scan r from -2 to +2; within each row scan q from `max(-2, -2-r)` to
/// `min(2, 2-r)`. The resulting index 0..18 is what `MoveResult` uses.
List<Axial> _enumerateCells() {
  const int side = kHexSide - 1; // 2
  final cells = <Axial>[];
  for (var r = -side; r <= side; r++) {
    final qMin = max(-side, -side - r);
    final qMax = min(side, side - r);
    for (var q = qMin; q <= qMax; q++) {
      cells.add(Axial(q, r));
    }
  }
  return cells;
}

final List<Axial> _cells = List<Axial>.unmodifiable(_enumerateCells());

final Map<Axial, int> _indexOf = {
  for (var i = 0; i < _cells.length; i++) _cells[i]: i,
};

/// Returns the cell index for axial coord `(q, r)` or null if `(q, r)` is
/// outside the side-3 hexagon.
int? axialToIndex(int q, int r) => _indexOf[Axial(q, r)];

/// Returns the axial coord at flat-list index [i]. [i] must be in 0..18.
Axial indexToAxial(int i) => _cells[i];

/// A fresh, empty hex grid (19 zeros).
List<int> emptyHexGrid() => List<int>.filled(kHexCellCount, 0);

/// Indices of every empty cell in [grid].
List<int> emptyHexCells(List<int> grid) {
  final cells = <int>[];
  for (var i = 0; i < kHexCellCount; i++) {
    if (grid[i] == 0) cells.add(i);
  }
  return cells;
}
