import 'package:flutter/material.dart';

import '../game/game_mode.dart';

/// The neon visual identity: deep-space background, neon cyan grid, and tiles
/// that glow brighter the larger they get.
class NeonTheme {
  NeonTheme._();

  static const String fontFamily = 'Orbitron';

  // Surfaces.
  static const Color background = Color(0xFF03060D);
  static const Color backgroundLow = Color(0xFF071018);
  static const Color panel = Color(0xFF081320);
  static const Color boardBackdrop = Color(0xFF050B14);
  static const Color emptyCell = Color(0xFF0C1A29);

  // Neon palette.
  static const Color neon = Color(0xFF22E6FF); // primary cyan
  static const Color neonDim = Color(0xFF14546A); // resting grid lines
  static const Color neonDeep = Color(0xFF2C7CD6); // electric blue
  static const Color neonHot = Color(0xFFEAFBFF); // white-hot accents
  static const Color danger = Color(0xFFFF4D6D); // game-over accent
  static const Color textDim = Color(0xFF6F93A6);

  /// Per-value tile styling dispatched by [GameMode].
  static TileStyle styleFor(GameMode mode, int value) {
    switch (mode) {
      case GameMode.mode2048:
        return _styleFor2048(value);
      case GameMode.mode2187:
        return _styleFor2187(value);
    }
  }

  /// Cyan ramp — dim slate-blue 2 climbing to a white-hot 2048.
  static TileStyle _styleFor2048(int value) {
    switch (value) {
      case 2:
        return const TileStyle(Color(0xFF0E2236), Color(0xFF3D6E88), 0.22);
      case 4:
        return const TileStyle(Color(0xFF0E2A45), Color(0xFF4A86B8), 0.30);
      case 8:
        return const TileStyle(Color(0xFF103352), Color(0xFF44A2DC), 0.42);
      case 16:
        return const TileStyle(Color(0xFF0F3D63), Color(0xFF3CBCEC), 0.54);
      case 32:
        return const TileStyle(Color(0xFF0E4570), Color(0xFF2AD4F2), 0.66);
      case 64:
        return const TileStyle(Color(0xFF0C4E78), Color(0xFF22E6FF), 0.80);
      case 128:
        return const TileStyle(Color(0xFF0A5478), Color(0xFF5FEEFF), 0.92);
      case 256:
        return const TileStyle(Color(0xFF0B5C7C), Color(0xFF8EF3FF), 1.04);
      case 512:
        return const TileStyle(Color(0xFF0D6280), Color(0xFFBAF9FF), 1.16);
      case 1024:
        return const TileStyle(Color(0xFF136882), Color(0xFFDFFCFF), 1.30);
      case 2048:
        return const TileStyle(Color(0xFF177084), Color(0xFFEAFBFF), 1.48);
      default:
        return const TileStyle(Color(0xFF1C7A86), Color(0xFFEAFBFF), 1.6);
    }
  }

  // Red ramp for 2187 mode. Crimson at the low end → hot pink at the top.
  // Kept distinct from the `danger` accent so the game-over banner remains
  // visually separable.
  static TileStyle _styleFor2187(int value) {
    switch (value) {
      case 3:
        return const TileStyle(Color(0xFF360E1B), Color(0xFF88406A), 0.22);
      case 9:
        return const TileStyle(Color(0xFF45112B), Color(0xFFB8497A), 0.30);
      case 27:
        return const TileStyle(Color(0xFF55143A), Color(0xFFDC4C8C), 0.42);
      case 81:
        return const TileStyle(Color(0xFF63174A), Color(0xFFEC4FA0), 0.56);
      case 243:
        return const TileStyle(Color(0xFF701A5A), Color(0xFFF252B6), 0.72);
      case 729:
        return const TileStyle(Color(0xFF7A1D6A), Color(0xFFFF5AC8), 0.92);
      case 2187:
        return const TileStyle(Color(0xFF84207A), Color(0xFFFFB1E4), 1.16);
      default:
        return const TileStyle(Color(0xFF86238E), Color(0xFFFFB1E4), 1.3);
    }
  }

  /// A neon glow shadow around [color].
  static List<BoxShadow> glow(Color color,
      {double blur = 16, double spread = 0, double opacity = 0.55}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static ThemeData themeData() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: neon,
        secondary: neonDeep,
        surface: panel,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: neonHot,
        displayColor: neonHot,
      ),
    );
  }
}

/// Fill colour, neon edge colour, and glow strength for one tile value.
class TileStyle {
  final Color fill;
  final Color edge;

  /// Multiplier on the tile's glow blur — bigger tiles glow harder.
  final double glow;

  const TileStyle(this.fill, this.edge, this.glow);
}
