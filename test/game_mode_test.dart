import 'package:flutter_test/flutter_test.dart';
import 'package:free_2048/game/game_mode.dart';

void main() {
  group('GameMode', () {
    test('mode2048 has expected display label and storage key', () {
      expect(GameMode.mode2048.label, '2048');
      expect(GameMode.mode2048.storageKey, '2048');
      expect(GameMode.mode2048.winValue, 2048);
    });

    test('mode2187 has expected display label and storage key', () {
      expect(GameMode.mode2187.label, '2187');
      expect(GameMode.mode2187.storageKey, '2187');
      expect(GameMode.mode2187.winValue, 2187);
    });

    test('fromStorageKey round-trips both modes', () {
      expect(GameMode.fromStorageKey('2048'), GameMode.mode2048);
      expect(GameMode.fromStorageKey('2187'), GameMode.mode2187);
    });

    test('fromStorageKey returns null for unknown keys', () {
      expect(GameMode.fromStorageKey('nope'), isNull);
      expect(GameMode.fromStorageKey(null), isNull);
    });
  });
}
