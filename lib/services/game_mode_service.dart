import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_mode.dart';

/// Persists which [GameMode] the player last had selected, so launches resume
/// in the same mode. Defaults to [GameMode.mode2048] when nothing is stored or
/// the stored value is unrecognised.
class GameModeService {
  static const String _key = 'neon2048.activeMode';

  /// Returns the stored mode, or [GameMode.mode2048] if nothing is saved, the
  /// stored value is unrecognised, or storage is unavailable.
  Future<GameMode> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return GameMode.fromStorageKey(prefs.getString(_key)) ??
          GameMode.mode2048;
    } catch (_) {
      return GameMode.mode2048;
    }
  }

  /// Stores [mode] so a later [load] returns it.
  Future<void> save(GameMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.storageKey);
    } catch (_) {
      // Storage failed — the in-memory mode is still correct for this session.
    }
  }
}
