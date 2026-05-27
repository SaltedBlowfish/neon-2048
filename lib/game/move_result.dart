/// One tile sliding from [from] to [to] during a move. [value] is the tile's
/// value while it slides — its pre-merge value. [merging] is true when the
/// tile slides into a merge and is then replaced by the doubled/tripled tile.
class TileMove {
  final int from;
  final int to;
  final int value;
  final bool merging;

  const TileMove({
    required this.from,
    required this.to,
    required this.value,
    required this.merging,
  });
}

/// The outcome of applying a swipe: the new grid plus everything an animation
/// needs to play the move. Does not include the random tile that spawns after.
/// Cell indices are opaque integers — each mode's logic file owns the mapping
/// between an index and a 2D coord (row/col for square, axial q/r for hex).
class MoveResult {
  final List<int> grid;
  final List<TileMove> moves;
  final List<int> mergedCells;
  final int gained;

  const MoveResult({
    required this.grid,
    required this.moves,
    required this.mergedCells,
    required this.gained,
  });

  /// True when the swipe actually changed the board (a legal move).
  bool get changed =>
      mergedCells.isNotEmpty || moves.any((m) => m.from != m.to);
}
