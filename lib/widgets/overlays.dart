import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/high_score_service.dart';
import '../theme/neon_theme.dart';
import 'neon_widgets.dart';

/// Full-screen blurred scrim wrapping a panel that pops into view.
class _OverlayShell extends StatelessWidget {
  final Widget child;
  const _OverlayShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.62),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                builder: (context, v, child) => Opacity(
                  opacity: v.clamp(0.0, 1.0),
                  child: Transform.scale(scale: 0.85 + 0.15 * v, child: child),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A bordered, glowing panel that holds overlay content.
class _Panel extends StatelessWidget {
  final Color accent;
  final List<Widget> children;
  const _Panel({required this.accent, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
      decoration: BoxDecoration(
        color: NeonTheme.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.85), width: 1.8),
        boxShadow: NeonTheme.glow(accent, blur: 32, spread: 2, opacity: 0.35),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

Widget _title(String text, Color color, {double size = 30}) => Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        shadows: [Shadow(color: color.withValues(alpha: 0.8), blurRadius: 18)],
      ),
    );

Widget _caption(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: NeonTheme.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );

/// A large score readout — caption above a glowing number.
class _ScoreReadout extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ScoreReadout(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _caption(label),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            color: NeonTheme.neonHot,
            fontSize: 44,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.8), blurRadius: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordBadge extends StatelessWidget {
  const _RecordBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: NeonTheme.neon.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeonTheme.neon, width: 1.3),
        boxShadow: NeonTheme.glow(NeonTheme.neon, blur: 14, opacity: 0.4),
      ),
      child: const Text(
        '★  NEW HIGH SCORE  ★',
        style: TextStyle(
          color: NeonTheme.neon,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

/// Shown when the board locks up with no moves left.
class GameOverOverlay extends StatelessWidget {
  final int score;
  final bool isRecord;
  final VoidCallback onNewGame;
  final VoidCallback onViewScores;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.isRecord,
    required this.onNewGame,
    required this.onViewScores,
  });

  @override
  Widget build(BuildContext context) {
    return _OverlayShell(
      child: _Panel(
        accent: NeonTheme.danger,
        children: [
          _title('GRID LOCKED', NeonTheme.danger),
          const SizedBox(height: 6),
          _caption('NO MOVES REMAIN'),
          const SizedBox(height: 22),
          _ScoreReadout(
              label: 'FINAL SCORE', value: score, color: NeonTheme.danger),
          if (isRecord) ...[
            const SizedBox(height: 14),
            const _RecordBadge(),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: NeonButton(
                  label: 'New Game',
                  icon: Icons.refresh,
                  color: NeonTheme.neon,
                  filled: true,
                  onTap: onNewGame,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeonButton(
                  label: 'Scores',
                  icon: Icons.leaderboard,
                  color: NeonTheme.neonDeep,
                  onTap: onViewScores,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown once the player first reaches a 2048 tile.
class WinOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onKeepPlaying;
  final VoidCallback onNewGame;

  const WinOverlay({
    super.key,
    required this.score,
    required this.onKeepPlaying,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    return _OverlayShell(
      child: _Panel(
        accent: NeonTheme.neon,
        children: [
          _title('2048', NeonTheme.neon, size: 54),
          const SizedBox(height: 4),
          _caption('SYSTEM ONLINE'),
          const SizedBox(height: 20),
          _ScoreReadout(label: 'SCORE', value: score, color: NeonTheme.neon),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: 'Keep Playing',
              icon: Icons.play_arrow,
              color: NeonTheme.neon,
              filled: true,
              onTap: onKeepPlaying,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: 'New Game',
              icon: Icons.refresh,
              color: NeonTheme.neonDeep,
              onTap: onNewGame,
            ),
          ),
        ],
      ),
    );
  }
}

/// The top-10 high-score table.
class HighScoresOverlay extends StatelessWidget {
  final List<int> scores;

  /// A score to highlight — the player's most recent run.
  final int? highlight;
  final VoidCallback onClose;

  const HighScoresOverlay({
    super.key,
    required this.scores,
    required this.highlight,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final highlightIndex =
        highlight == null ? -1 : scores.indexOf(highlight!);
    return _OverlayShell(
      child: _Panel(
        accent: NeonTheme.neonDeep,
        children: [
          _title('HIGH SCORES', NeonTheme.neon, size: 24),
          const SizedBox(height: 4),
          _caption('TOP ${HighScoreService.maxEntries}'),
          const SizedBox(height: 18),
          for (var i = 0; i < HighScoreService.maxEntries; i++)
            _ScoreRow(
              rank: i + 1,
              score: i < scores.length ? scores[i] : null,
              highlighted: i == highlightIndex,
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              label: 'Close',
              color: NeonTheme.neon,
              onTap: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int rank;
  final int? score;
  final bool highlighted;

  const _ScoreRow({
    required this.rank,
    required this.score,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlighted ? NeonTheme.neon : NeonTheme.neonDim;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: highlighted
            ? NeonTheme.neon.withValues(alpha: 0.12)
            : NeonTheme.boardBackdrop,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: accent.withValues(alpha: highlighted ? 0.9 : 0.4),
          width: 1.2,
        ),
        boxShadow: highlighted
            ? NeonTheme.glow(NeonTheme.neon, blur: 12, opacity: 0.3)
            : null,
      ),
      child: Row(
        children: [
          Text(
            rank.toString().padLeft(2, '0'),
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              score != null ? '$score' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: score != null
                    ? NeonTheme.neonHot
                    : NeonTheme.textDim,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
