import 'package:flutter/material.dart';

import '../theme/neon_theme.dart';

/// A neon-bordered button: dark fill, glowing edge, uppercase label.
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color color;

  /// When true the fill is tinted with [color] to read as the primary action.
  final bool filled;

  const NeonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = NeonTheme.neon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withValues(alpha: 0.22),
        highlightColor: color.withValues(alpha: 0.10),
        child: Ink(
          decoration: BoxDecoration(
            color: filled ? color.withValues(alpha: 0.16) : NeonTheme.panel,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: color.withValues(alpha: 0.85), width: 1.6),
            boxShadow: NeonTheme.glow(color, blur: 14, opacity: 0.28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small labelled readout panel — used for SCORE and BEST. The value counts
/// up smoothly when it changes.
class ScoreBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const ScoreBox({
    super.key,
    required this.label,
    required this.value,
    this.color = NeonTheme.neon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: NeonTheme.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.3),
        boxShadow: NeonTheme.glow(color, blur: 10, opacity: 0.16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, shown, _) => Text(
              '$shown',
              style: TextStyle(
                color: NeonTheme.neonHot,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.7), blurRadius: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
