import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/features/game/data/players_store.dart';

void main() {
  test('store retains an immutable copy of names in memory', () async {
    final store = PlayersStore();
    final names = ['أحمد'];
    await store.saveNames(names);
    names.add('محمد');
    final loaded = await store.loadNames();
    expect(loaded, ['أحمد']);
    expect(() => loaded.clear(), throwsUnsupportedError);
    expect(await PlayersStore().loadNames(), isEmpty);
  });
}
