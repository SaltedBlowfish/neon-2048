import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/game_logic.dart';
import '../theme/neon_theme.dart';
import 'board_metrics.dart';

/// Paints the board chrome: dark backdrop, the 16 empty cell slots, a neon
/// frame that breathes, and light streaks that orbit the perimeter.
class GridPainter extends CustomPainter {
  final BoardMetrics metrics;
  final Animation<double> ambient;

  GridPainter({required this.metrics, required this.ambient})
      : super(repaint: ambient);

  @override
  void paint(Canvas canvas, Size size) {
    final t = ambient.value; // 0..1, looping
    final pulse = 0.5 - 0.5 * cos(t * 2 * pi); // 0..1..0 breathing

    final radius = Radius.circular(size.width * 0.045);
    final boardRRect =
        RRect.fromRectAndRadius(Offset.zero & size, radius);

    // Backdrop.
    canvas.drawRRect(boardRRect, Paint()..color = NeonTheme.boardBackdrop);

    // Empty cell slots.
    final cellRadius = Radius.circular(metrics.cell * 0.16);
    final slotFill = Paint()..color = NeonTheme.emptyCell;
    final slotEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = NeonTheme.neonDim.withValues(alpha: 0.55 + 0.25 * pulse);
    for (var r = 0; r < kGridSide; r++) {
      for (var c = 0; c < kGridSide; c++) {
        final rect = RRect.fromRectAndRadius(
          metrics.topLeftOf(r.toDouble(), c.toDouble()) &
              Size(metrics.cell, metrics.cell),
          cellRadius,
        );
        canvas.drawRRect(rect, slotFill);
        canvas.drawRRect(rect.deflate(0.6), slotEdge);
      }
    }

    // Glowing neon frame — a soft blurred pass under a crisp line.
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

    // Two light streaks chasing each other around the frame.
    final framePath = Path()..addRRect(frame);
    for (final metric in framePath.computeMetrics()) {
      _drawStreak(canvas, metric, t);
      _drawStreak(canvas, metric, (t + 0.5) % 1.0);
    }
  }

  void _drawStreak(Canvas canvas, ui.PathMetric metric, double position) {
    final length = metric.length;
    final streak =
        _segmentPath(metric, position * length, length * 0.13, length);

    canvas.drawPath(
      streak,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = NeonTheme.neon.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      streak,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = NeonTheme.neonHot.withValues(alpha: 0.9),
    );
  }

  /// Extracts a sub-path of [segment] length starting at [start], wrapping
  /// around the end of the contour when needed.
  Path _segmentPath(
      ui.PathMetric metric, double start, double segment, double length) {
    final end = start + segment;
    if (end <= length) return metric.extractPath(start, end);
    return metric.extractPath(start, length)
      ..addPath(metric.extractPath(0, end - length), Offset.zero);
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.metrics.size != metrics.size;
}
