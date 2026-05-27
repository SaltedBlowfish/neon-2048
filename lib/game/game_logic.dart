// Pure 2048 board logic — no Flutter, no side effects (except spawnTile,
// which is documented as mutating). Everything here is unit-tested.
import 'dart:math';

import 'move_result.dart';

export 'move_result.dart' show MoveResult, TileMove;

/// The board is a 4x4 grid.
const int kGridSide = 4;
const int kCellCount = kGridSide * kGridSide;

/// Reaching a tile of this value wins the game.
const int kWinValue = 2048;

/// A swipe direction.
enum Direction { up, down, left, right }

int cellRow(int index) => index ~/ kGridSide;
int cellCol(int index) => index % kGridSide;
int cellIndex(int row, int col) => row * kGridSide + col;

/// A fresh, empty grid.
List<int> emptyGrid() => List<int>.filled(kCellCount, 0);

/// Indices of every empty cell in [grid].
List<int> emptyCells(List<int> grid) {
  final cells = <int>[];
  for (var i = 0; i < kCellCount; i++) {
    if (grid[i] == 0) cells.add(i);
  }
  return cells;
}

/// The four lines of cell indices a move travels along, each ordered so the
/// cell a tile reaches first comes first.
List<List<int>> _travelLines(Direction dir) {
  final lines = <List<int>>[];
  for (var i = 0; i < kGridSide; i++) {
    final line = <int>[];
    for (var j = 0; j < kGridSide; j++) {
      line.add(switch (dir) {
        Direction.left => cellIndex(i, j),
        Direction.right => cellIndex(i, kGridSide - 1 - j),
        Direction.up => cellIndex(j, i),
        Direction.down => cellIndex(kGridSide - 1 - j, i),
      });
    }
    lines.add(line);
  }
  return lines;
}

/// Applies a swipe to [grid] and returns the result. [grid] is never mutated.
MoveResult applyMove(List<int> grid, Direction dir) {
  final result = emptyGrid();
  final moves = <TileMove>[];
  final mergedCells = <int>[];
  var gained = 0;

  for (final line in _travelLines(dir)) {
    // Source cell indices that hold a tile, in travel order.
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
        result[dest] = value * 2;
        mergedCells.add(dest);
        gained += value * 2;
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

/// Places a new tile in a random empty cell of [grid] (mutating it) and
/// returns that cell's index, or null if the grid is full. New tiles are a 2
/// 90% of the time and a 4 the other 10%.
int? spawnTile(List<int> grid, Random random) {
  final empties = emptyCells(grid);
  if (empties.isEmpty) return null;
  final index = empties[random.nextInt(empties.length)];
  grid[index] = random.nextInt(10) == 0 ? 4 : 2;
  return index;
}

/// True while at least one legal move remains.
bool canMove(List<int> grid) {
  if (grid.contains(0)) return true;
  for (var r = 0; r < kGridSide; r++) {
    for (var c = 0; c < kGridSide; c++) {
      final v = grid[cellIndex(r, c)];
      if (c + 1 < kGridSide && grid[cellIndex(r, c + 1)] == v) return true;
      if (r + 1 < kGridSide && grid[cellIndex(r + 1, c)] == v) return true;
    }
  }
  return false;
}

/// The largest tile value currently on the board.
int highestTile(List<int> grid) =>
    grid.fold(0, (best, v) => v > best ? v : best);
