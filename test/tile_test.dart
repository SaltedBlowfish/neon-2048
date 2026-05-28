import 'package:flutter_test/flutter_test.dart';
import 'package:free_2048/game/tile.dart';

void main() {
  test('HexTile.atRest sets from and to coords equal', () {
    final t = HexTile.atRest(id: 1, value: 3, q: -1, r: 2);
    expect(t.fromQ, -1);
    expect(t.toQ, -1);
    expect(t.fromR, 2);
    expect(t.toR, 2);
    expect(t.spawn, TileSpawn.slide);
  });
}
