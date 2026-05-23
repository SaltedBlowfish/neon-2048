import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_logic.dart';
import '../game/tile.dart';
import '../services/high_score_service.dart';
import '../theme/neon_theme.dart';
import '../widgets/board_view.dart';
import '../widgets/overlays.dart';
import '../widgets/neon_widgets.dart';

/// The single screen: header, board, controls, and the overlays stacked above.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  final HighScoreService _highScoreService = HighScoreService();
  final Random _random = Random();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _moveController;
  late final AnimationController _ambientController;

  late List<int> _grid;
  List<Tile> _tiles = [];
  int _score = 0;
  List<int> _highScores = [];
  int _idCounter = 0;

  bool _reachedWin = false; // a 2048 tile has appeared this run
  bool _keepPlaying = false; // chose to continue past the win
  bool _gameOver = false;
  bool _scoreBanked = false; // this run's score is already saved
  bool _showHighScores = false;
  int? _lastBankedScore;

  Offset _dragAccum = Offset.zero;

  bool get _winPending => _reachedWin && !_keepPlaying && !_gameOver;

  bool get _inputLocked =>
      _moveController.isAnimating ||
      _gameOver ||
      _winPending ||
      _showHighScores;

  int get _best {
    final stored = _highScores.isEmpty ? 0 : _highScores.first;
    return max(stored, _score);
  }

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _settleMove();
      });
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _loadHighScores();
    _startNewGame();
  }

  @override
  void dispose() {
    _moveController.dispose();
    _ambientController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHighScores() async {
    final scores = await _highScoreService.load();
    if (!mounted) return;
    setState(() => _highScores = scores);
  }

  int _nextId() => _idCounter++;

  /// Builds a static tile that sits in one cell with the given [spawn] role.
  Tile _cellTile(int value, int index, TileSpawn spawn) => Tile(
        id: _nextId(),
        value: value,
        fromRow: cellRow(index).toDouble(),
        fromCol: cellCol(index).toDouble(),
        toRow: cellRow(index).toDouble(),
        toCol: cellCol(index).toDouble(),
        spawn: spawn,
      );

  void _startNewGame() {
    _bankScore(); // save the run that is ending, if it earned anything

    final grid = emptyGrid();
    final first = spawnTile(grid, _random)!;
    final second = spawnTile(grid, _random)!;
    setState(() {
      _grid = grid;
      _tiles = [
        _cellTile(grid[first], first, TileSpawn.fresh),
        _cellTile(grid[second], second, TileSpawn.fresh),
      ];
      _score = 0;
      _reachedWin = false;
      _keepPlaying = false;
      _gameOver = false;
      _scoreBanked = false;
      _showHighScores = false;
      _lastBankedScore = null;
    });
    _moveController.forward(from: 0);
  }

  void _move(Direction dir) {
    if (_inputLocked) return;

    final result = applyMove(_grid, dir);
    if (!result.changed) return;

    HapticFeedback.selectionClick();

    final next = List<int>.of(result.grid);
    final spawnIndex = spawnTile(next, _random);

    final tiles = <Tile>[];
    // Sliding and consumed tiles render first, beneath the merge pops.
    for (final m in result.moves) {
      tiles.add(Tile(
        id: _nextId(),
        value: m.value,
        fromRow: cellRow(m.from).toDouble(),
        fromCol: cellCol(m.from).toDouble(),
        toRow: cellRow(m.to).toDouble(),
        toCol: cellCol(m.to).toDouble(),
        spawn: m.merging ? TileSpawn.consumed : TileSpawn.slide,
      ));
    }
    for (final c in result.mergedCells) {
      tiles.add(_cellTile(result.grid[c], c, TileSpawn.merged));
    }
    if (spawnIndex != null) {
      tiles.add(_cellTile(next[spawnIndex], spawnIndex, TileSpawn.fresh));
    }

    setState(() {
      _grid = next;
      _score += result.gained;
      _tiles = tiles;
    });
    _moveController.forward(from: 0);
  }

  /// Runs when a move animation finishes: freeze the tiles and check the
  /// win / game-over conditions.
  void _settleMove() {
    final settled = <Tile>[];
    for (var i = 0; i < kCellCount; i++) {
      if (_grid[i] != 0) {
        settled.add(_cellTile(_grid[i], i, TileSpawn.slide));
      }
    }
    final justWon = !_reachedWin && highestTile(_grid) >= kWinValue;
    final isOver = !canMove(_grid);

    setState(() {
      _tiles = settled;
      if (justWon) _reachedWin = true;
      if (isOver) _gameOver = true;
    });

    if (justWon) HapticFeedback.mediumImpact();
    if (isOver) {
      HapticFeedback.heavyImpact();
      _bankScore();
    }
  }

  /// Saves the current run's score to the high-score table exactly once.
  Future<void> _bankScore() async {
    if (_scoreBanked || _score <= 0) return;
    _scoreBanked = true;
    final banked = _score;
    final updated = await _highScoreService.submit(banked);
    if (!mounted) return;
    setState(() {
      _highScores = updated;
      _lastBankedScore = banked;
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(Direction.up);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _move(Direction.down);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _move(Direction.left);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _move(Direction.right);
    } else if (key == LogicalKeyboardKey.keyR) {
      _startNewGame();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final drag = _dragAccum;
    if (drag.distance < 18) return;
    if (drag.dx.abs() > drag.dy.abs()) {
      _move(drag.dx > 0 ? Direction.right : Direction.left);
    } else {
      _move(drag.dy > 0 ? Direction.down : Direction.up);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => _dragAccum = Offset.zero,
          onPanUpdate: (d) => _dragAccum += d.delta,
          onPanEnd: _handlePanEnd,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NeonTheme.background,
                  NeonTheme.backgroundLow,
                  NeonTheme.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  _buildLayout(),
                  if (_winPending)
                    WinOverlay(
                      score: _score,
                      onKeepPlaying: () =>
                          setState(() => _keepPlaying = true),
                      onNewGame: _startNewGame,
                    ),
                  if (_gameOver)
                    GameOverOverlay(
                      score: _score,
                      isRecord: _highScores.isNotEmpty &&
                          _score > 0 &&
                          _highScores.first == _score,
                      onNewGame: _startNewGame,
                      onViewScores: () =>
                          setState(() => _showHighScores = true),
                    ),
                  if (_showHighScores)
                    HighScoresOverlay(
                      scores: _highScores,
                      highlight: _lastBankedScore,
                      onClose: () =>
                          setState(() => _showHighScores = false),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side =
                      min(constraints.maxWidth, constraints.maxHeight);
                  return BoardView(
                    size: side,
                    tiles: _tiles,
                    move: _moveController,
                    ambient: _ambientController,
                  );
                },
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '// NEON GRID',
            style: TextStyle(
              color: NeonTheme.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          const Text(
            '2048',
            style: TextStyle(
              color: NeonTheme.neon,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              height: 1.1,
              shadows: [
                Shadow(color: NeonTheme.neon, blurRadius: 22),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ScoreBox(
                  label: 'Score',
                  value: _score,
                  color: NeonTheme.neon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ScoreBox(
                  label: 'Best',
                  value: _best,
                  color: NeonTheme.neonDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: NeonButton(
              label: 'New Game',
              icon: Icons.refresh,
              color: NeonTheme.neon,
              filled: true,
              onTap: _startNewGame,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: NeonButton(
              label: 'High Scores',
              icon: Icons.leaderboard,
              color: NeonTheme.neonDeep,
              onTap: () => setState(() => _showHighScores = true),
            ),
          ),
        ],
      ),
    );
  }
}
