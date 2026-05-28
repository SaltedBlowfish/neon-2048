# Neon 2048

A neon-styled 2048 clone for Android, written in Flutter. Single screen, swipe
to play, tiles glow brighter the bigger they get, top 10 high scores kept on
device. Ships with two modes: classic **2048** (square 4×4, base-2 merges)
and **2187** (pointy-top hex board, base-3 merges) — toggle between them at
the top of the screen.

<p align="center">
  <img src="screenshots/home.png" alt="Neon 2048 home screen" width="280" />
</p>

## Screenshots

| Home | Gameplay | High scores |
|---|---|---|
| <img src="screenshots/home.png" width="220" /> | <img src="screenshots/gameplay.png" width="220" /> | <img src="screenshots/high-scores.png" width="220" /> |

## Features

- **Two game modes**, picked via the title-tab toggle:
  - **2048** — classic 4×4 grid, pair-merge ×2 (`2 + 2 → 4 → 8 → … → 2048`).
  - **2187** — pointy-top hexagonal grid (19 cells), pair-merge ×3
    (`3 + 3 → 9 → 27 → … → 2187`). Six-direction swipe input. Distinct red
    tile palette to contrast with 2048's cyan.
- Mode persists across launches; each mode keeps its own top-10 scoreboard.
- Mid-game mode switch shows a confirm dialog so you don't lose progress.
- Swipe gestures (and arrow keys on hardware keyboards in 2048 mode) for
  input. Hex mode resolves swipes through 60° wedges.
- Animated tile slides, merge pops, and spawn appearances.
- A breathing neon frame around the board.
- Per-value tile palette — a dim slate-blue 2 climbing to a white-hot 2048
  in classic mode; deep crimson 3 climbing to hot-pink 2187 in hex mode.
- Live `SCORE` and `BEST` panels, with the best loaded from device storage.
- Top 10 high scores persisted per mode via `shared_preferences`. The
  current run is banked on game over or whenever you start a new one.
- Game-over (`GRID LOCKED`) and win (`SYSTEM ONLINE`) overlays with a
  "keep playing" option.
- Reset / new game and high scores buttons reachable at all times.
- Haptic feedback on every successful move.

## Install

A debug-signed APK is available in the latest release (or build your own —
see below). Sideload it onto your Android device:

1. Transfer the `.apk` to the phone (USB, Drive, email — whatever's easiest).
2. Open it from the Files app. Android will prompt to allow installs from
   that source; toggle it on.
3. Install. The launcher icon will read **Neon 2048**.

This is signed with the Flutter debug key, so it installs on any Android
phone — no Play Store or release keystore required.

## Build from source

### Prerequisites

- Flutter 3.38+ (Dart 3.10+).
- Android SDK + platform tools (`adb`), Java 17.
- `ANDROID_HOME` set, or Android Studio installed.

### One-time setup

```bash
git clone https://github.com/SaltedBlowfish/neon-2048.git
cd neon-2048
flutter pub get
```

### Run on a connected device or emulator

```bash
flutter run --release
```

### Produce an installable APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

The Flutter template's default `android/app/build.gradle.kts` maps the release
build to the debug signing config, so no keystore configuration is needed.

### Produce an Android App Bundle

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Run the tests

```bash
flutter test
```

61 unit tests cover both modes' pure board logic — slides, merges, scoring,
no-op detection, game-over and win checks, hex coord round-trips, swipe
direction resolution, mode persistence, and per-mode high-score migration.

### Static analysis

```bash
flutter analyze
```

## Project layout

```
lib/
├── main.dart                          # app entry, theme + orientation lock
├── theme/neon_theme.dart              # palette, per-mode tile styles
├── game/
│   ├── game_logic.dart                # pure 2048 engine (no Flutter)
│   ├── hex_logic.dart                 # pure 2187 hex engine (no Flutter)
│   ├── game_mode.dart                 # GameMode enum (2048 / 2187)
│   ├── move_result.dart               # MoveResult/TileMove shared by both modes
│   └── tile.dart                      # Tile + HexTile models for animation
├── services/
│   ├── high_score_service.dart        # per-mode top-10, with legacy migration
│   └── game_mode_service.dart         # persists the active mode
├── screens/game_screen.dart           # the single screen, mode-aware
└── widgets/
    ├── board_metrics.dart             # square board pixel geometry
    ├── board_view.dart                # square board + animated tile widgets
    ├── grid_painter.dart              # square neon frame, cells, light streaks
    ├── hex_board_metrics.dart         # axial→pixel + swipe-angle→direction
    ├── hex_board_view.dart            # hex board + animated tile widgets
    ├── hex_grid_painter.dart          # hex neon frame and cell slots
    ├── mode_toggle_header.dart        # title-as-toggle (2048 | 2187)
    ├── neon_widgets.dart              # NeonButton, ScoreBox
    └── overlays.dart                  # game-over / win / high-scores panels

test/                                  # 61 engine + service unit tests
assets/fonts/Orbitron.ttf              # display font (SIL OFL)
docs/adr/                              # architecture decision records
CONTEXT.md                             # domain glossary
```

## How it works

The engines in `lib/game/game_logic.dart` (square) and `lib/game/hex_logic.dart`
(hex) are pure Dart with no Flutter imports. Each `applyMove(grid, direction)`
returns a shared `MoveResult` containing the post-merge grid, every tile
movement (with merge flags), and the points gained — enough for the UI to
drive both gameplay and the slide / pop / spawn animations. Hex mode uses
axial `(q, r)` coordinates internally and exposes them as opaque cell indices
via `MoveResult` so the rendering layer stays mode-agnostic.

The screen owns a 210 ms `AnimationController` for moves and a looping 4 s
`AnimationController` for the ambient pulse. Tiles are rendered as
`Positioned` widgets inside a `Stack`; their position, scale, and opacity
are interpolated from the move animation according to the tile's `TileSpawn`
role (`slide`, `consumed`, `merged`, or `fresh`). Square tiles are rounded
rectangles laid out on a row/column grid; hex tiles are pointy-top hexagons
laid out via axial→pixel math in `hex_board_metrics.dart`.

Architectural decisions (two parallel logic files, pair-merge ×3 mechanic
for 2187) are documented in `docs/adr/`.

## Tech

- [Flutter](https://flutter.dev/) 3.38 / Dart 3.10
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) for
  persisting the high-score table
- [Orbitron](https://fonts.google.com/specimen/Orbitron) as the display
  font (SIL Open Font License — see `assets/fonts/OFL.txt`)

## License

Source code is released under the [MIT License](LICENSE).

The bundled Orbitron font is © 2018 The Orbitron Project Authors and is
licensed under the SIL Open Font License v1.1 — a copy is included at
`assets/fonts/OFL.txt`.
