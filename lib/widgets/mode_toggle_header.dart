import 'package:flutter/material.dart';

import '../game/game_mode.dart';
import '../theme/neon_theme.dart';

/// Two-tab title that doubles as the mode selector. The active mode is bright
/// and glowing; the inactive mode is dim and tappable. Tapping the inactive
/// tab fires [onModeTap] with that mode (the caller may then show a confirm
/// dialog before actually switching).
class ModeToggleHeader extends StatelessWidget {
  final GameMode active;
  final ValueChanged<GameMode> onModeTap;

  const ModeToggleHeader({
    super.key,
    required this.active,
    required this.onModeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        _ModeTab(
          mode: GameMode.mode2048,
          active: active == GameMode.mode2048,
          onTap: () => onModeTap(GameMode.mode2048),
        ),
        const SizedBox(width: 18),
        const Text(
          '|',
          style: TextStyle(
            color: NeonTheme.neonDim,
            fontSize: 32,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(width: 18),
        _ModeTab(
          mode: GameMode.mode2187,
          active: active == GameMode.mode2187,
          onTap: () => onModeTap(GameMode.mode2187),
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final GameMode mode;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({
    required this.mode,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        mode == GameMode.mode2048 ? NeonTheme.neon : NeonTheme.neon2187;
    return Semantics(
      label: active
          ? '${mode.label} mode, selected'
          : 'Switch to ${mode.label} mode',
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active ? null : onTap,
        child: Text(
          mode.label,
          style: TextStyle(
            color: active ? color : NeonTheme.textDim,
            fontSize: 44,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            height: 1.1,
            shadows: active
                ? [Shadow(color: color, blurRadius: 22)]
                : const <Shadow>[],
          ),
        ),
      ),
    );
  }
}
