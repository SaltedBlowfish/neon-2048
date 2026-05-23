import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the player's top 10 scores on the device.
///
/// Every method degrades gracefully: if device storage is unavailable the
/// game still runs and simply sees an empty high-score table.
class HighScoreService {
  static const String _key = 'neon2048.highscores';

  /// How many scores the table keeps.
  static const int maxEntries = 10;

  /// Loads saved scores, highest first. Returns an empty list on any failure.
  Future<List<int>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
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

  /// Adds [score] to the table and returns the updated top 10. If the write
  /// fails the updated list is still returned so the UI stays consistent.
  Future<List<int>> submit(int score) async {
    final scores = await load()..add(score);
    scores.sort((a, b) => b.compareTo(a));
    final top = scores.take(maxEntries).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(top));
    } catch (_) {
      // Storage failed — keep the in-memory table.
    }
    return top;
  }
}
