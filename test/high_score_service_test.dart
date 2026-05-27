import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:free_2048/game/game_mode.dart';
import 'package:free_2048/services/high_score_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HighScoreService', () {
    test('returns an empty list for a fresh mode', () async {
      final service = HighScoreService();
      expect(await service.load(GameMode.mode2048), isEmpty);
      expect(await service.load(GameMode.mode2187), isEmpty);
    });

    test('submitted scores are persisted per-mode and sorted', () async {
      final service = HighScoreService();
      await service.submit(GameMode.mode2048, 100);
      await service.submit(GameMode.mode2048, 300);
      await service.submit(GameMode.mode2048, 200);
      expect(await service.load(GameMode.mode2048), [300, 200, 100]);
      expect(await service.load(GameMode.mode2187), isEmpty);
    });

    test('scores in one mode do not appear in the other', () async {
      final service = HighScoreService();
      await service.submit(GameMode.mode2048, 500);
      await service.submit(GameMode.mode2187, 27);
      expect(await service.load(GameMode.mode2048), [500]);
      expect(await service.load(GameMode.mode2187), [27]);
    });

    test('caps each mode at 10 entries', () async {
      final service = HighScoreService();
      for (var i = 1; i <= 15; i++) {
        await service.submit(GameMode.mode2048, i * 10);
      }
      final scores = await service.load(GameMode.mode2048);
      expect(scores.length, 10);
      expect(scores.first, 150);
      expect(scores.last, 60);
    });

    test('migrates legacy single-mode key into the 2048 bucket', () async {
      SharedPreferences.setMockInitialValues({
        'neon2048.highscores': jsonEncode([400, 200, 100]),
      });
      final service = HighScoreService();
      expect(await service.load(GameMode.mode2048), [400, 200, 100]);
      // After migration the legacy key is gone and the new key holds the data.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('neon2048.highscores'), isFalse);
      expect(prefs.getString('neon2048.highscores.2048'), isNotNull);
    });

    test('migration does not clobber existing per-mode data', () async {
      SharedPreferences.setMockInitialValues({
        'neon2048.highscores': jsonEncode([100]),
        'neon2048.highscores.2048': jsonEncode([999]),
      });
      final service = HighScoreService();
      // Per-mode data wins; legacy is discarded (and removed).
      expect(await service.load(GameMode.mode2048), [999]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('neon2048.highscores'), isFalse);
    });
  });
}
