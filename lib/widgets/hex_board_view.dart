import 'dart:ui';

import 'package:flutter/material.dart';

import '../game/game_mode.dart';
import '../game/tile.dart';
import '../theme/neon_theme.dart';
import 'hex_board_metrics.dart';
import 'hex_grid_painter.dart';

/// The hex board: painted grid chrome with animating tiles on top.
class HexBoardView extends StatelessWidget {
  final double size;
  final List<HexTile> tiles;
  final Animation<double> move;
  final Animation<double> ambient;

  const HexBoardView({
    super.key,
    required this.size,
    required this.tiles,
    required this.move,
    required this.ambient,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = HexBoardMetrics(size);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: HexGridPainter(metrics: metrics, ambient: ambient),
            ),
          ),
          for (final tile in tiles)
            HexTileView(
              key: ValueKey(tile.id),
              tile: tile,
              metrics: metrics,
              move: move,
            ),
        ],
      ),
    );
  }
}

/// A single hex tile, positioned and scaled from the shared move animation.
class HexTileView extends StatelessWidget {
  final HexTile tile;
  final HexBoardMetrics metrics;
  final Animation<double> move;

  const HexTileView({
    super.key,
    required this.tile,
    required this.metrics,
    required this.move,
  });

  static const double _slideEnd = 0.62;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: move,
      child: _HexTileBox(value: tile.value, cellSize: metrics.cellSize),
      builder: (context, child) {
        final t = move.value;
        final slide =
            Curves.easeOutCubic.transform((t / _slideEnd).clamp(0.0, 1.0));
        final q = lerpDouble(tile.fromQ, tile.toQ, slide)!;
        final r = lerpDouble(tile.fromR, tile.toR, slide)!;
        final centre = metrics.centerOf(q, r);
        final appear = ((t - _slideEnd) / (1 - _slideEnd)).clamp(0.0, 1.0);

        var scale = 1.0;
        var opacity = 1.0;
        switch (tile.spawn) {
          case TileSpawn.slide:
            break;
          case TileSpawn.consumed:
            opacity = 1.0 - ((t - _slideEnd) / 0.22).clamp(0.0, 1.0);
          case TileSpawn.merged:
            scale = Curves.easeOutBack.transform(appear);
          case TileSpawn.fresh:
            scale = Curves.easeOut.transform(appear);
        }

        return Positioned(
          left: centre.dx - metrics.cellSize,
          top: centre.dy - metrics.cellSize,
          width: metrics.cellSize * 2,
          height: metrics.cellSize * 2,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}

/// Painted face of a hex tile.
class _HexTileBox extends StatelessWidget {
  final int value;
  final double cellSize;

  const _HexTileBox({required this.value, required this.cellSize});

  double get _fontSize {
    final digits = value.toString().length;
    if (digits <= 2) return cellSize * 0.70;
    if (digits == 3) return cellSize * 0.55;
    return cellSize * 0.42;
  }

  @override
  Widget build(BuildContext context) {
    final style = NeonTheme.styleFor(GameMode.mode2187, value);
    return CustomPaint(
      painter: _HexTilePainter(
        fill: style.fill,
        edge: style.edge,
        glow: style.glow,
        cellSize: cellSize,
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(cellSize * 0.15),
          child: FittedBox(
            child: Text(
              value.toString(),
              style: TextStyle(
                color: NeonTheme.neonHot,
                fontSize: _fontSize,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: style.edge.withValues(alpha: 0.85),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HexTilePainter extends CustomPainter {
  final Color fill;
  final Color edge;
  final double glow;
  final double cellSize;

  _HexTilePainter({
    required this.fill,
    required this.edge,
    required this.glow,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final path = pointyTopHexPath(centre, cellSize * 0.92);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = edge.withValues(alpha: 0.4 + 0.6 * glow.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = edge,
    );
  }

  @override
  bool shouldRepaint(covariant _HexTilePainter old) =>
      old.fill != fill ||
      old.edge != edge ||
      old.glow != glow ||
      old.cellSize != cellSize;
}
