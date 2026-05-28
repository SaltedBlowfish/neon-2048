import 'dart:math';

import 'package:flutter/material.dart';

import '../game/hex_logic.dart';
import '../theme/neon_theme.dart';
import 'hex_board_metrics.dart';

/// Paints the hex-board chrome: dark backdrop, the 19 empty hex cell slots,
/// and a neon frame that breathes.
class HexGridPainter extends CustomPainter {
  final HexBoardMetrics metrics;
  final Animation<double> ambient;

  HexGridPainter({required this.metrics, required this.ambient})
      : super(repaint: ambient);

  @override
  void paint(Canvas canvas, Size size) {
    final t = ambient.value;
    final pulse = 0.5 - 0.5 * cos(t * 2 * pi);

    final radius = Radius.circular(size.width * 0.045);
    final boardRRect = RRect.fromRectAndRadius(Offset.zero & size, radius);

    canvas.drawRRect(boardRRect, Paint()..color = NeonTheme.boardBackdrop);

    final slotFill = Paint()..color = NeonTheme.emptyCell;
    final slotEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = NeonTheme.neonDim.withValues(alpha: 0.55 + 0.25 * pulse);

    for (var i = 0; i < kHexCellCount; i++) {
      final c = indexToAxial(i);
      final centre = metrics.centerOf(c.q.toDouble(), c.r.toDouble());
      final path = pointyTopHexPath(centre, metrics.cellSize * 0.92);
      canvas.drawPath(path, slotFill);
      canvas.drawPath(path, slotEdge);
    }

    final frame = boardRRect.deflate(1.5);
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + 3 * pulse
        ..color = NeonTheme.neon.withValues(alpha: 0.10 + 0.12 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = NeonTheme.neon.withValues(alpha: 0.45 + 0.35 * pulse),
    );
  }

  @override
  bool shouldRepaint(covariant HexGridPainter old) =>
      old.metrics.size != metrics.size;
}

/// Path of a pointy-top regular hexagon centred at [c] with circumradius [r].
Path pointyTopHexPath(Offset c, double r) {
  final path = Path();
  for (var i = 0; i < 6; i++) {
    final angle = pi / 3 * i - pi / 2; // start at top, rotate clockwise
    final x = c.dx + r * cos(angle);
    final y = c.dy + r * sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}
