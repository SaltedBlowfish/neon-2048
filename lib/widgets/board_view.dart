import 'dart:ui';

import 'package:flutter/material.dart';

import '../game/game_mode.dart';
import '../game/tile.dart';
import '../theme/neon_theme.dart';
import 'board_metrics.dart';
import 'grid_painter.dart';

/// The 4x4 board: the painted grid chrome with the animating tiles on top.
class BoardView extends StatelessWidget {
  final double size;
  final List<Tile> tiles;
  final Animation<double> move;
  final Animation<double> ambient;
  final GameMode mode;

  const BoardView({
    super.key,
    required this.size,
    required this.tiles,
    required this.move,
    required this.ambient,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = BoardMetrics(size);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(metrics: metrics, ambient: ambient),
            ),
          ),
          for (final tile in tiles)
            TileView(
              key: ValueKey(tile.id),
              tile: tile,
              metrics: metrics,
              move: move,
              mode: mode,
            ),
        ],
      ),
    );
  }
}

/// A single tile, positioned and scaled from the shared move animation.
class TileView extends StatelessWidget {
  final Tile tile;
  final BoardMetrics metrics;
  final Animation<double> move;
  final GameMode mode;

  const TileView({
    super.key,
    required this.tile,
    required this.metrics,
    required this.move,
    required this.mode,
  });

  /// Fraction of the move animation spent sliding; the rest is for pops.
  static const double _slideEnd = 0.62;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: move,
      child: _TileBox(value: tile.value, cell: metrics.cell, mode: mode),
      builder: (context, child) {
        final t = move.value;
        final slide =
            Curves.easeOutCubic.transform((t / _slideEnd).clamp(0.0, 1.0));
        final row = lerpDouble(tile.fromRow, tile.toRow, slide)!;
        final col = lerpDouble(tile.fromCol, tile.toCol, slide)!;
        final tl = metrics.topLeftOf(row, col);
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
          left: tl.dx,
          top: tl.dy,
          width: metrics.cell,
          height: metrics.cell,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}

/// The painted face of a tile: dark fill, neon edge, glowing number.
class _TileBox extends StatelessWidget {
  final int value;
  final double cell;
  final GameMode mode;

  const _TileBox({required this.value, required this.cell, required this.mode});

  double get _fontSize {
    final digits = value.toString().length;
    if (digits <= 2) return cell * 0.40;
    if (digits == 3) return cell * 0.32;
    if (digits == 4) return cell * 0.26;
    return cell * 0.21;
  }

  @override
  Widget build(BuildContext context) {
    final style = NeonTheme.styleFor(mode, value);
    final glowAlpha = (0.45 * style.glow).clamp(0.0, 0.95);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(cell * 0.14),
        border: Border.all(
          color: style.edge,
          width: (cell * 0.03).clamp(1.5, 3.2),
        ),
        boxShadow: [
          BoxShadow(
            color: style.edge.withValues(alpha: glowAlpha),
            blurRadius: cell * 0.22 * style.glow,
            spreadRadius: cell * 0.01 * style.glow,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontFamily: NeonTheme.fontFamily,
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            color: style.edge,
            letterSpacing: -0.5,
            height: 1.0,
            shadows: [
              Shadow(
                color: style.edge.withValues(alpha: glowAlpha),
                blurRadius: cell * 0.14 * style.glow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
