import 'package:flutter_test/flutter_test.dart';
import 'package:free_2048/game/game_mode.dart';
import 'package:free_2048/services/game_mode_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameModeService', () {
    test('defaults to mode2048 when nothing is stored', () async {
      final service = GameModeService();
      expect(await service.load(), GameMode.mode2048);
    });

    test('round-trips the saved mode', () async {
      final service = GameModeService();
      await service.save(GameMode.mode2187);
      expect(await service.load(), GameMode.mode2187);
    });

    test('falls back to mode2048 when stored value is corrupted', () async {
      SharedPreferences.setMockInitialValues({
        'neon2048.activeMode': 'garbage',
      });
      final service = GameModeService();
      expect(await service.load(), GameMode.mode2048);
    });
  });
}
