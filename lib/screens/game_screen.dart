import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_logic.dart';
import '../game/game_mode.dart';
import '../game/hex_logic.dart';
import '../game/tile.dart';
import '../services/game_mode_service.dart';
import '../services/high_score_service.dart';
import '../theme/neon_theme.dart';
import '../widgets/board_view.dart';
import '../widgets/hex_board_metrics.dart';
import '../widgets/hex_board_view.dart';
import '../widgets/mode_toggle_header.dart';
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
  final GameModeService _modeService = GameModeService();
  final Random _random = Random();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _moveController;
  late final AnimationController _ambientController;

  GameMode _mode = GameMode.mode2048;
  bool _modeReady = false;

  late List<int> _grid;
  List<Tile> _squareTiles = [];
  List<HexTile> _hexTiles = [];
  int _score = 0;
  List<int> _highScores = [];
  int _idCounter = 0;

  bool _reachedWin = false; // a winning tile has appeared this run
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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _mode = await _modeService.load();
    final scores = await _highScoreService.load(_mode);
    if (!mounted) return;
    setState(() {
      _highScores = scores;
      _modeReady = true;
    });
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
    final scores = await _highScoreService.load(_mode);
    if (!mounted) return;
    setState(() => _highScores = scores);
  }

  int _nextId() => _idCounter++;

  /// Builds a static square-mode tile that sits in one cell with the given
  /// [spawn] role.
  Tile _squareCellTile(int value, int index, TileSpawn spawn) => Tile(
        id: _nextId(),
        value: value,
        fromRow: cellRow(index).toDouble(),
        fromCol: cellCol(index).toDouble(),
        toRow: cellRow(index).toDouble(),
        toCol: cellCol(index).toDouble(),
        spawn: spawn,
      );

  /// Builds a static hex-mode tile that sits in one cell with the given
  /// [spawn] role.
  HexTile _hexCellTile(int value, int index, TileSpawn spawn) {
    final c = indexToAxial(index);
    return HexTile(
      id: _nextId(),
      value: value,
      fromQ: c.q.toDouble(),
      fromR: c.r.toDouble(),
      toQ: c.q.toDouble(),
      toR: c.r.toDouble(),
      spawn: spawn,
    );
  }

  void _startNewGame() {
    _bankScore(); // save the run that is ending, if it earned anything
    if (_mode == GameMode.mode2048) {
      final grid = emptyGrid();
      final first = spawnTile(grid, _random)!;
      final second = spawnTile(grid, _random)!;
      setState(() {
        _grid = grid;
        _squareTiles = [
          _squareCellTile(grid[first], first, TileSpawn.fresh),
          _squareCellTile(grid[second], second, TileSpawn.fresh),
        ];
        _hexTiles = [];
        _resetRunFlags();
      });
    } else {
      final grid = emptyHexGrid();
      final first = spawnHexTile(grid, _random)!;
      final second = spawnHexTile(grid, _random)!;
      setState(() {
        _grid = grid;
        _hexTiles = [
          _hexCellTile(grid[first], first, TileSpawn.fresh),
          _hexCellTile(grid[second], second, TileSpawn.fresh),
        ];
        _squareTiles = [];
        _resetRunFlags();
      });
    }
    _moveController.forward(from: 0);
  }

  void _resetRunFlags() {
    _score = 0;
    _reachedWin = false;
    _keepPlaying = false;
    _gameOver = false;
    _scoreBanked = false;
    _showHighScores = false;
    _lastBankedScore = null;
  }

  void _moveSquare(Direction dir) {
    if (_inputLocked || _mode != GameMode.mode2048) return;

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
      tiles.add(_squareCellTile(result.grid[c], c, TileSpawn.merged));
    }
    if (spawnIndex != null) {
      tiles.add(_squareCellTile(next[spawnIndex], spawnIndex, TileSpawn.fresh));
    }

    setState(() {
      _grid = next;
      _score += result.gained;
      _squareTiles = tiles;
    });
    _moveController.forward(from: 0);
  }

  void _moveHex(HexDirection dir) {
    if (_inputLocked || _mode != GameMode.mode2187) return;

    final result = applyHexMove(_grid, dir);
    if (!result.changed) return;

    HapticFeedback.selectionClick();

    final next = List<int>.of(result.grid);
    final spawnIndex = spawnHexTile(next, _random);

    final tiles = <HexTile>[];
    for (final m in result.moves) {
      final fromAxial = indexToAxial(m.from);
      final toAxial = indexToAxial(m.to);
      tiles.add(HexTile(
        id: _nextId(),
        value: m.value,
        fromQ: fromAxial.q.toDouble(),
        fromR: fromAxial.r.toDouble(),
        toQ: toAxial.q.toDouble(),
        toR: toAxial.r.toDouble(),
        spawn: m.merging ? TileSpawn.consumed : TileSpawn.slide,
      ));
    }
    for (final c in result.mergedCells) {
      tiles.add(_hexCellTile(result.grid[c], c, TileSpawn.merged));
    }
    if (spawnIndex != null) {
      tiles.add(_hexCellTile(next[spawnIndex], spawnIndex, TileSpawn.fresh));
    }

    setState(() {
      _grid = next;
      _score += result.gained;
      _hexTiles = tiles;
    });
    _moveController.forward(from: 0);
  }

  /// Runs when a move animation finishes: freeze the tiles and check the
  /// win / game-over conditions.
  void _settleMove() {
    bool justWon;
    bool isOver;
    if (_mode == GameMode.mode2048) {
      final settled = <Tile>[];
      for (var i = 0; i < kCellCount; i++) {
        if (_grid[i] != 0) {
          settled.add(_squareCellTile(_grid[i], i, TileSpawn.slide));
        }
      }
      justWon = !_reachedWin && highestTile(_grid) >= _mode.winValue;
      isOver = !canMove(_grid);
      setState(() {
        _squareTiles = settled;
        if (justWon) _reachedWin = true;
        if (isOver) _gameOver = true;
      });
    } else {
      final settled = <HexTile>[];
      for (var i = 0; i < kHexCellCount; i++) {
        if (_grid[i] != 0) {
          settled.add(_hexCellTile(_grid[i], i, TileSpawn.slide));
        }
      }
      justWon = !_reachedWin && highestHexTile(_grid) >= _mode.winValue;
      isOver = !canHexMove(_grid);
      setState(() {
        _hexTiles = settled;
        if (justWon) _reachedWin = true;
        if (isOver) _gameOver = true;
      });
    }
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
    final updated = await _highScoreService.submit(_mode, banked);
    if (!mounted) return;
    setState(() {
      _highScores = updated;
      _lastBankedScore = banked;
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    final key = event.logicalKey;
    if (_mode == GameMode.mode2048) {
      if (key == LogicalKeyboardKey.arrowUp) {
        _moveSquare(Direction.up);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        _moveSquare(Direction.down);
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        _moveSquare(Direction.left);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        _moveSquare(Direction.right);
      } else if (key == LogicalKeyboardKey.keyR) {
        _startNewGame();
      }
    } else {
      // Hex is touch-primary; arrows have no defined direction mapping.
      if (key == LogicalKeyboardKey.keyR) _startNewGame();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    final drag = _dragAccum;
    if (_mode == GameMode.mode2048) {
      if (drag.distance < minSwipeDistance) return;
      if (drag.dx.abs() > drag.dy.abs()) {
        _moveSquare(drag.dx > 0 ? Direction.right : Direction.left);
      } else {
        _moveSquare(drag.dy > 0 ? Direction.down : Direction.up);
      }
    } else {
      final dir = directionFromSwipe(drag);
      if (dir != null) _moveHex(dir);
    }
  }

  void _onModeTap(GameMode requested) {
    if (requested == _mode) return;
    final shouldConfirm = _score > 0 && !_gameOver;
    if (!shouldConfirm) {
      _applyModeSwitch(requested);
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NeonTheme.panel,
        title: Text('Switch to ${requested.label}?',
            style: const TextStyle(color: NeonTheme.neonHot)),
        content: const Text(
          'Your current game will end and the score will be saved.',
          style: TextStyle(color: NeonTheme.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) _applyModeSwitch(requested);
    });
  }

  Future<void> _applyModeSwitch(GameMode newMode) async {
    await _bankScore();
    await _modeService.save(newMode);
    if (!mounted) return;
    setState(() => _mode = newMode);
    _startNewGame();
    await _loadHighScores();
  }

  @override
  Widget build(BuildContext context) {
    if (!_modeReady) {
      return const Scaffold(
        backgroundColor: NeonTheme.background,
        body: SizedBox.shrink(),
      );
    }
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
                      winValue: _mode.winValue,
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
                  if (_mode == GameMode.mode2048) {
                    return BoardView(
                      size: side,
                      tiles: _squareTiles,
                      move: _moveController,
                      ambient: _ambientController,
                      mode: _mode,
                    );
                  }
                  return HexBoardView(
                    size: side,
                    tiles: _hexTiles,
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
          ModeToggleHeader(active: _mode, onModeTap: _onModeTap),
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
