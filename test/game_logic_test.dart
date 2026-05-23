import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:free_2048/game/game_logic.dart';

/// Flattens a 4x4 grid of rows into the engine's 16-cell representation.
List<int> gridFrom(List<List<int>> rows) =>
    [for (final row in rows) ...row];

void main() {
  group('applyMove — sliding', () {
    test('slides tiles to the left without merging', () {
      final result = applyMove(
        gridFrom([
          [0, 0, 2, 0],
          [0, 4, 0, 0],
          [0, 0, 0, 8],
          [0, 0, 0, 0],
        ]),
        Direction.left,
      );
      expect(
        result.grid,
        gridFrom([
          [2, 0, 0, 0],
          [4, 0, 0, 0],
          [8, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
      );
      expect(result.changed, isTrue);
      expect(result.gained, 0);
    });

    test('slides right, up, and down', () {
      final row = gridFrom([
        [2, 0, 0, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(applyMove(row, Direction.right).grid[3], 4);

      final col = gridFrom([
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(applyMove(col, Direction.up).grid[0], 4);
      expect(applyMove(col, Direction.down).grid[12], 4);
    });

    test('does not mutate the input grid', () {
      final grid = gridFrom([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      final copy = List<int>.of(grid);
      applyMove(grid, Direction.left);
      expect(grid, copy);
    });
  });

  group('applyMove — merging', () {
    test('merges equal adjacent tiles and scores the sum', () {
      final result = applyMove(
        gridFrom([
          [2, 2, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
        Direction.left,
      );
      expect(result.grid[0], 4);
      expect(result.gained, 4);
      expect(result.mergedCells, contains(0));
    });

    test('merges only one pair per line per move', () {
      final result = applyMove(
        gridFrom([
          [4, 4, 8, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
        Direction.left,
      );
      expect(result.grid.sublist(0, 4), [8, 8, 0, 0]);
      expect(result.gained, 8);
    });

    test('four equal tiles merge into two pairs', () {
      final result = applyMove(
        gridFrom([
          [2, 2, 2, 2],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
        Direction.left,
      );
      expect(result.grid.sublist(0, 4), [4, 4, 0, 0]);
      expect(result.gained, 8);
      expect(result.mergedCells.length, 2);
    });

    test('three equal tiles merge the pair nearest the wall', () {
      final result = applyMove(
        gridFrom([
          [2, 2, 2, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
        Direction.left,
      );
      expect(result.grid.sublist(0, 4), [4, 2, 0, 0]);
    });

    test('emits a move for every tile with correct merge flags', () {
      final result = applyMove(
        gridFrom([
          [2, 2, 4, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
        Direction.left,
      );
      expect(result.moves.length, 3); // two merging + one sliding
      expect(result.moves.where((m) => m.merging).length, 2);
    });
  });

  group('applyMove — no-op detection', () {
    test('reports no change when nothing can move', () {
      final grid = gridFrom([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ]);
      expect(applyMove(grid, Direction.left).changed, isFalse);
      expect(applyMove(grid, Direction.up).changed, isFalse);
    });
  });

  group('canMove', () {
    test('true when an empty cell exists', () {
      expect(canMove(emptyGrid()), isTrue);
    });

    test('true when a merge is possible on a full board', () {
      expect(
        canMove(gridFrom([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 4],
        ])),
        isTrue,
      );
    });

    test('false when the board is full with no merges', () {
      expect(
        canMove(gridFrom([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2],
        ])),
        isFalse,
      );
    });
  });

  group('spawnTile', () {
    test('fills exactly one empty cell with a 2 or a 4', () {
      final grid = emptyGrid();
      final index = spawnTile(grid, Random(7));
      expect(index, isNotNull);
      expect(grid.where((v) => v != 0).length, 1);
      expect(grid[index!], anyOf(2, 4));
    });

    test('returns null when the grid is full', () {
      expect(spawnTile(List<int>.filled(kCellCount, 2), Random(1)), isNull);
    });
  });

  group('highestTile', () {
    test('reports the largest value on the board', () {
      expect(
        highestTile(gridFrom([
          [2, 4, 8, 16],
          [0, 0, 0, 0],
          [0, 0, 2048, 0],
          [0, 0, 0, 0],
        ])),
        2048,
      );
    });
  });
}
