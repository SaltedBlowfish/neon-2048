/// Which gameplay variant is active.
enum GameMode {
  mode2048(label: '2048', storageKey: '2048', winValue: 2048),
  mode2187(label: '2187', storageKey: '2187', winValue: 2187);

  const GameMode({
    required this.label,
    required this.storageKey,
    required this.winValue,
  });

  /// Text shown in the title toggle and the win overlay.
  final String label;

  /// String saved in SharedPreferences keys (e.g. `neon2048.highscores.2048`).
  /// Kept separate from [label] so renaming the display name doesn't break
  /// storage.
  final String storageKey;

  /// Reaching a tile of this value triggers the win overlay.
  final int winValue;

  /// Reverse of [storageKey]. Returns null when the key isn't recognised so
  /// callers can fall back to a default without throwing.
  static GameMode? fromStorageKey(String? key) {
    if (key == null) return null;
    for (final m in GameMode.values) {
      if (m.storageKey == key) return m;
    }
    return null;
  }
}
