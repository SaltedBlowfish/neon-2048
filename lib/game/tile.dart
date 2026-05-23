/// How a [Tile] behaves during the current move's animation.
enum TileSpawn {
  /// Already on the board — slides from its old cell to its new cell.
  slide,

  /// Slides into a merge, then fades out as the merged tile replaces it.
  consumed,

  /// The doubled tile a merge produces — pops in at the merge cell.
  merged,

  /// A brand new random tile — scales in at its cell.
  fresh,
}

/// A tile as drawn on screen for one move. Positions are fractional grid
/// coordinates (0..3) so the view can interpolate them into pixels.
class Tile {
  final int id;
  final int value;
  final double fromRow;
  final double fromCol;
  final double toRow;
  final double toCol;
  final TileSpawn spawn;

  const Tile({
    required this.id,
    required this.value,
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.spawn,
  });

  /// A tile sitting still in one cell — no animation.
  Tile.atRest({
    required this.id,
    required this.value,
    required int row,
    required int col,
  })  : fromRow = row.toDouble(),
        fromCol = col.toDouble(),
        toRow = row.toDouble(),
        toCol = col.toDouble(),
        spawn = TileSpawn.slide;
}
