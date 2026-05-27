import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_mode.dart';

/// Persists the player's top 10 scores per game mode.
///
/// Storage key is `neon2048.highscores.<mode.storageKey>`. Includes a one-shot
/// migration from the pre-multi-mode key `neon2048.highscores` into the 2048
/// bucket; the legacy key is removed after migration.
///
/// Every method degrades gracefully: if device storage is unavailable the game
/// still runs and simply sees an empty high-score table.
class HighScoreService {
  static const String _legacyKey = 'neon2048.highscores';
  static const String _keyPrefix = 'neon2048.highscores.';

  /// How many scores each mode's table keeps.
  static const int maxEntries = 10;

  String _keyFor(GameMode mode) => '$_keyPrefix${mode.storageKey}';

  /// Loads the top-10 scores for [mode], highest first. Returns an empty list
  /// on any failure.
  Future<List<int>> load(GameMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrateLegacyIfNeeded(prefs);
      final raw = prefs.getString(_keyFor(mode));
      if (raw == null) return <int>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <int>[];
      final scores = decoded.whereType<num>().map((n) => n.toInt()).toList()
        ..sort((a, b) => b.compareTo(a));
      return scores.take(maxEntries).toList();
    } catch (_) {
      return <int>[];
    }
  }

  /// Adds [score] to [mode]'s table and returns the updated top 10. If the
  /// write fails the updated list is still returned so the UI stays
  /// consistent.
  Future<List<int>> submit(GameMode mode, int score) async {
    final scores = await load(mode)..add(score);
    scores.sort((a, b) => b.compareTo(a));
    final top = scores.take(maxEntries).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFor(mode), jsonEncode(top));
    } catch (_) {
      // Storage failed — keep the in-memory table.
    }
    return top;
  }

  /// If the legacy single-mode key exists, copy it into the 2048 bucket
  /// (unless that bucket already has data) and then delete the legacy key.
  Future<void> _migrateLegacyIfNeeded(SharedPreferences prefs) async {
    if (!prefs.containsKey(_legacyKey)) return;
    final mode2048Key = _keyFor(GameMode.mode2048);
    if (!prefs.containsKey(mode2048Key)) {
      final legacy = prefs.getString(_legacyKey);
      if (legacy != null) {
        await prefs.setString(mode2048Key, legacy);
      }
    }
    await prefs.remove(_legacyKey);
  }
}
