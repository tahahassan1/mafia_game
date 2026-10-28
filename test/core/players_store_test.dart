import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/features/game/data/players_store.dart';
import 'package:mafia/features/game/domain/assignment.dart';
import 'package:mafia/features/game/domain/game_session.dart';
import 'package:mafia/features/game/domain/player.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';

import '../support/test_preferences.dart';

void main() {
  test(
    'names survive a new store instance, with immutable snapshots',
    () async {
      final preferences = TestPreferences();
      final store = PlayersStore(preferences: preferences);
      expect(await store.loadNames(), isEmpty);
      final names = ['أحمد', 'منى'];
      final saved = store.saveNames(names);
      names.add('علي');
      await saved;
      final loaded = await PlayersStore(preferences: preferences).loadNames();
      expect(loaded, ['أحمد', 'منى']);
      expect(() => loaded.clear(), throwsUnsupportedError);
      await store.saveNames([]);
      expect(await PlayersStore(preferences: preferences).loadNames(), isEmpty);
    },
  );

  test(
    'only names are written; a session cannot add assignments to storage',
    () async {
      final preferences = TestPreferences();
      final session = GameSession()
        ..start(const [
          Assignment(
            player: Player(name: 'أحمد'),
            role: RoleCatalog.mafia,
          ),
        ]);
      await PlayersStore(preferences: preferences).saveNames(['أحمد']);
      expect(preferences.values, {
        PlayersStore.namesKey: ['أحمد'],
      });
      session.clear();
      expect(await PlayersStore(preferences: preferences).loadNames(), [
        'أحمد',
      ]);
    },
  );

  test(
    'overlapping writes are serialized and loading waits for them',
    () async {
      final preferences = TestPreferences(firstWrite: Completer<void>());
      final store = PlayersStore(preferences: preferences);
      final first = store.saveNames(['old']);
      final second = store.saveNames(['latest']);
      final loaded = store.loadNames();
      await Future<void>.delayed(Duration.zero);
      expect(preferences.writes, [
        ['old'],
      ]);
      preferences.firstWrite!.complete();
      await Future.wait([first, second]);
      expect(preferences.writes, [
        ['old'],
        ['latest'],
      ]);
      expect(await loaded, ['latest']);
    },
  );

  test(
    'a failed write propagates but does not poison the next write',
    () async {
      final preferences = TestPreferences()..failWrite = true;
      final store = PlayersStore(preferences: preferences);
      await expectLater(store.saveNames(['old']), throwsStateError);
      preferences.failWrite = false;
      await store.saveNames(['latest']);
      expect(await store.loadNames(), ['latest']);
    },
  );

  test('load errors propagate for the Cubit to present', () async {
    final preferences = TestPreferences()..failRead = true;
    await expectLater(
      PlayersStore(preferences: preferences).loadNames(),
      throwsStateError,
    );
  });
}
