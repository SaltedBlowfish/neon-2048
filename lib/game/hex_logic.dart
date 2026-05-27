// Pure hex-board logic for 2187 mode — no Flutter, no side effects (except
// `spawnHexTile`, which is documented as mutating). Everything here is
// unit-tested.

import 'dart:math';

import 'move_result.dart';

/// Side length of the hexagonal board, in cells from centre to a vertex.
const int kHexSide = 3;

/// Total number of cells in the side-3 hexagonal board. Derived from the
/// formula 3·n·(n-1) + 1 for a hexagon of side n.
const int kHexCellCount = 3 * kHexSide * (kHexSide - 1) + 1; // 19

/// Reaching a tile of this value wins the game.
const int kHex2187WinValue = 2187;

/// Multiplier applied on each pair-merge in 2187 mode.
const int kHex2187Multiplier = 3;

/// Values that can appear when a new tile spawns in 2187 mode.
const List<int> kHex2187SpawnValues = [3, 9];

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

/// A swipe direction in 2187 mode. Six axial unit vectors arranged around the
/// hexagon. Names assume pointy-top orientation, with east/west horizontal.
enum HexDirection {
  east(dq: 1, dr: 0),
  west(dq: -1, dr: 0),
  northeast(dq: 1, dr: -1),
  southwest(dq: -1, dr: 1),
  northwest(dq: 0, dr: -1),
  southeast(dq: 0, dr: 1);

  const HexDirection({required this.dq, required this.dr});

  /// Step in axial q per cell of travel along this direction.
  final int dq;

  /// Step in axial r per cell of travel along this direction.
  final int dr;
}

/// All five travel lines for [dir], each ordered so the cell a tile reaches
/// first comes first. A "travel line" is a maximal sequence of valid cells
/// stepping by `(dq, dr)`; the head of each line is the cell that lies
/// furthest along the swipe direction.
///
/// The result is cached per direction because the lines depend only on the
/// board shape, not on tile state.
List<List<int>> hexTravelLines(HexDirection dir) =>
    _travelLineCache.putIfAbsent(dir, () => _buildTravelLines(dir));

final Map<HexDirection, List<List<int>>> _travelLineCache = {};

/// Applies a swipe to [grid] and returns the result. [grid] is never mutated.
/// Pair-merge mechanic with a ×3 multiplier (3+3 → 9, 9+9 → 27, …).
MoveResult applyHexMove(List<int> grid, HexDirection dir) {
  final result = emptyHexGrid();
  final moves = <TileMove>[];
  final mergedCells = <int>[];
  var gained = 0;

  for (final line in hexTravelLines(dir)) {
    final occupied = [for (final idx in line) if (grid[idx] != 0) idx];

    var slot = 0;
    var i = 0;
    while (i < occupied.length) {
      final src = occupied[i];
      final value = grid[src];
      final dest = line[slot];
      final mergeNext =
          i + 1 < occupied.length && grid[occupied[i + 1]] == value;
      if (mergeNext) {
        moves.add(TileMove(from: src, to: dest, value: value, merging: true));
        moves.add(TileMove(
            from: occupied[i + 1], to: dest, value: value, merging: true));
        result[dest] = value * kHex2187Multiplier;
        mergedCells.add(dest);
        gained += value * kHex2187Multiplier;
        i += 2;
      } else {
        moves.add(TileMove(from: src, to: dest, value: value, merging: false));
        result[dest] = value;
        i += 1;
      }
      slot++;
    }
  }

  return MoveResult(
    grid: result,
    moves: moves,
    mergedCells: mergedCells,
    gained: gained,
  );
}

List<List<int>> _buildTravelLines(HexDirection dir) {
  // The "head" of each line — the cell furthest in the swipe direction with
  // no neighbour beyond it — is any cell whose step (q + dq, r + dr) leaves
  // the hexagon.
  final lines = <List<int>>[];
  final visited = <int>{};

  for (var i = 0; i < kHexCellCount; i++) {
    if (visited.contains(i)) continue;
    final start = indexToAxial(i);
    // Walk backwards from `start` against the direction to find the head.
    var headQ = start.q;
    var headR = start.r;
    while (axialToIndex(headQ + dir.dq, headR + dir.dr) != null) {
      headQ += dir.dq;
      headR += dir.dr;
    }
    // Now walk forward from the head, collecting cells.
    final line = <int>[];
    var q = headQ;
    var r = headR;
    int? idx = axialToIndex(q, r);
    while (idx != null) {
      line.add(idx);
      visited.add(idx);
      q -= dir.dq;
      r -= dir.dr;
      idx = axialToIndex(q, r);
    }
    lines.add(line);
  }
  return List<List<int>>.unmodifiable(
      lines.map((l) => List<int>.unmodifiable(l)));
}

/// Places a new tile in a random empty cell of [grid] (mutating it) and
/// returns that cell's index, or null if the grid is full. New tiles are a 3
/// 90% of the time and a 9 the other 10%.
int? spawnHexTile(List<int> grid, Random random) {
  final empties = emptyHexCells(grid);
  if (empties.isEmpty) return null;
  final index = empties[random.nextInt(empties.length)];
  grid[index] = random.nextInt(10) == 0 ? 9 : 3;
  return index;
}

/// True while at least one legal move remains.
bool canHexMove(List<int> grid) {
  if (grid.contains(0)) return true;
  // Check every cell's six axial neighbours for an equal value. Each unordered
  // pair is visited twice but that's cheap on a 19-cell board.
  const offsets = [
    [1, 0],
    [-1, 0],
    [1, -1],
    [-1, 1],
    [0, 1],
    [0, -1],
  ];
  for (var i = 0; i < kHexCellCount; i++) {
    final c = indexToAxial(i);
    final v = grid[i];
    for (final off in offsets) {
      final n = axialToIndex(c.q + off[0], c.r + off[1]);
      if (n != null && grid[n] == v) return true;
    }
  }
  return false;
}

/// The largest tile value currently on the board.
int highestHexTile(List<int> grid) =>
    grid.fold(0, (best, v) => v > best ? v : best);
