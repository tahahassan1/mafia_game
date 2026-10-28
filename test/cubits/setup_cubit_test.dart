import 'dart:async';
import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/features/game/data/players_store.dart';
import 'package:mafia/features/game/domain/assignment.dart';
import 'package:mafia/features/game/domain/game_session.dart';
import 'package:mafia/features/game/domain/player.dart';
import 'package:mafia/features/game/domain/validation_reason.dart';
import 'package:mafia/features/game/domain/validation_result.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';
import 'package:mafia/features/roles/domain/team.dart';
import 'package:mafia/features/setup/setup_cubit.dart';
import 'package:mafia/features/setup/setup_state.dart';

void main() {
  late PlayersStore store;
  late GameSession session;

  setUp(() {
    store = PlayersStore();
    session = GameSession();
  });

  SetupCubit buildCubit() => SetupCubit(store, session, Random(42));

  test('approved defaults and initial validation', () async {
    final cubit = buildCubit();
    expect(cubit.state.mafiaCount, 1);
    expect(cubit.state.enabledRoleIds, {
      RoleCatalog.detective.id,
      RoleCatalog.doctor.id,
    });
    expect(cubit.state.canAdvance, isFalse);
    expect(cubit.state.canDeal, isFalse);
    await cubit.close();
  });

  blocTest<SetupCubit, SetupState>(
    'adding and removing names immediately recomputes validation',
    build: buildCubit,
    act: (cubit) async {
      for (final name in ['أحمد', 'محمد', 'علي', 'حسن']) {
        await cubit.submitPlayer(name);
      }
      await cubit.removePlayer(0);
    },
    expect: () => [
      for (final count in [1, 2, 3, 4, 3])
        isA<SetupState>()
            .having((state) => state.players.length, 'count', count)
            .having((state) => state.canAdvance, 'can advance', count == 4)
            .having((state) => state.canDeal, 'can deal', count == 4),
    ],
    verify: (cubit) async {
      expect(await store.loadNames(), cubit.state.players);
    },
  );

  blocTest<SetupCubit, SetupState>(
    'empty and trimmed duplicate names produce inline error enums',
    build: buildCubit,
    act: (cubit) async {
      await cubit.submitPlayer('  ');
      cubit.nameChanged();
      await cubit.submitPlayer(' أحمد ');
      await cubit.submitPlayer('أحمد');
    },
    expect: () => [
      isA<SetupState>().having(
        (state) => state.nameError,
        'error',
        ValidationReason.emptyPlayerName,
      ),
      isA<SetupState>().having((state) => state.nameError, 'cleared', isNull),
      isA<SetupState>().having((state) => state.players, 'trimmed', ['أحمد']),
      isA<SetupState>().having(
        (state) => state.nameError,
        'error',
        ValidationReason.duplicatePlayerName,
      ),
    ],
  );

  test(
    'editing rejects duplicates, accepts the same name, and saves edits',
    () async {
      await store.saveNames(['أحمد', 'محمد', 'علي', 'حسن']);
      final cubit = buildCubit();
      await cubit.loadPlayers();
      cubit.startEditing(0);
      expect(await cubit.submitPlayer('محمد'), isFalse);
      expect(cubit.state.players.first, 'أحمد');
      expect(await cubit.submitPlayer('أحمد'), isTrue);
      cubit.startEditing(0);
      expect(await cubit.submitPlayer('سمير'), isTrue);
      expect(cubit.state.editingIndex, isNull);
      expect((await store.loadNames()).first, 'سمير');
      await cubit.close();
    },
  );

  test(
    'removing before the edited row preserves the selected player',
    () async {
      await store.saveNames(['أحمد', 'محمد', 'علي', 'حسن']);
      final cubit = buildCubit();
      await cubit.loadPlayers();
      cubit.startEditing(2);
      await cubit.removePlayer(0);
      expect(cubit.state.editingIndex, 1);
      await cubit.submitPlayer('سمير');
      expect(cubit.state.players, ['محمد', 'سمير', 'حسن']);
      cubit.startEditing(1);
      await cubit.removePlayer(1);
      expect(cubit.state.editingIndex, isNull);
      await cubit.close();
    },
  );

  test(
    'mafia stepper stays within limits and clamps after removing a player',
    () async {
      await store.saveNames(_names(5));
      final cubit = buildCubit();
      await cubit.loadPlayers();
      cubit.decreaseMafia();
      expect(cubit.state.mafiaCount, 1);
      cubit.increaseMafia();
      cubit.increaseMafia();
      expect(cubit.state.mafiaCount, 2);
      expect(cubit.state.canIncreaseMafia, isFalse);
      await cubit.removePlayer(0);
      expect(cubit.state.mafiaCount, 1);
      expect(cubit.state.canDecreaseMafia, isFalse);
      expect(cubit.state.validation, const Valid());
      await cubit.close();
    },
  );

  blocTest<SetupCubit, SetupState>(
    'role toggles update validity and required fix immediately',
    setUp: () => store.saveNames(_names(4)),
    build: buildCubit,
    act: (cubit) async {
      await cubit.loadPlayers();
      cubit.toggleRole(RoleCatalog.guard.id);
      cubit.toggleRole(RoleCatalog.jester.id);
      cubit.toggleRole(RoleCatalog.jester.id);
    },
    expect: () => [
      isA<SetupState>().having((state) => state.canDeal, 'valid', isTrue),
      isA<SetupState>().having(
        (state) => state.canDeal,
        'full capacity',
        isTrue,
      ),
      isA<SetupState>()
          .having(
            (state) => state.validation,
            'invalid',
            const Invalid(ValidationReason.tooManySpecialRoles),
          )
          .having((state) => state.specialRolesToDisable, 'excess', 1)
          .having((state) => state.canAdvance, 'names remain valid', isTrue),
      isA<SetupState>().having((state) => state.canDeal, 'fixed', isTrue),
    ],
  );

  test(
    'invalid deal returns false without changing an existing session',
    () async {
      const previous = Assignment(
        player: Player(name: 'previous'),
        role: RoleCatalog.citizen,
      );
      session.start([previous]);
      final cubit = buildCubit();
      expect(cubit.deal(), isFalse);
      expect(session.assignments, [previous]);
      await cubit.close();
    },
  );

  test(
    'valid seven-player deal fills session and rejects a second tap',
    () async {
      await store.saveNames(_names(7));
      final cubit = buildCubit();
      await cubit.loadPlayers();
      cubit.increaseMafia();
      cubit.toggleRole(RoleCatalog.godfather.id);
      cubit.toggleRole(RoleCatalog.jester.id);

      expect(cubit.deal(), isTrue);
      final assignments = session.assignments;
      expect(assignments, hasLength(7));
      expect(assignments.where((a) => a.role.team == Team.mafia), hasLength(2));
      for (final role in [
        RoleCatalog.godfather,
        RoleCatalog.detective,
        RoleCatalog.doctor,
        RoleCatalog.jester,
      ]) {
        expect(assignments.where((a) => a.role == role), hasLength(1));
      }
      expect(
        assignments.where((a) => a.role == RoleCatalog.citizen),
        hasLength(2),
      );
      expect(assignments.map((a) => a.player.name), cubit.state.players);
      expect(cubit.deal(), isFalse);
      expect(session.assignments, same(assignments));
      cubit.beginSetup();
      expect(cubit.deal(), isTrue);
      expect(session.assignments, isNot(same(assignments)));
      await cubit.close();
    },
  );

  test(
    '25-player cap rejects another name; loaded 26-player list is invalid',
    () async {
      await store.saveNames(_names(25));
      final cubit = buildCubit();
      await cubit.loadPlayers();
      expect(await cubit.submitPlayer('extra'), isFalse);
      expect(cubit.state.players, hasLength(25));
      expect(cubit.state.nameError, ValidationReason.tooManyPlayers);
      await store.saveNames(_names(26));
      await cubit.loadPlayers();
      expect(cubit.state.canAdvance, isFalse);
      expect(
        cubit.state.playersValidation,
        const Invalid(ValidationReason.tooManyPlayers),
      );
      await cubit.close();
    },
  );

  test('state collections cannot be modified by widgets', () async {
    final cubit = buildCubit();
    await cubit.submitPlayer('أحمد');
    expect(() => cubit.state.players.add('محمد'), throwsUnsupportedError);
    expect(() => cubit.state.enabledRoleIds.clear(), throwsUnsupportedError);
    await cubit.close();
  });

  test('delayed load cannot overwrite names edited while waiting', () async {
    final deferred = DeferredPlayersStore();
    final cubit = SetupCubit(deferred, session, Random(1));
    final pending = cubit.loadPlayers();
    await cubit.submitPlayer('new');
    deferred.completer.complete(['stale']);
    await pending;
    expect(cubit.state.players, ['new']);
    await cubit.close();
  });

  test('load completion after close does not emit', () async {
    final deferred = DeferredPlayersStore();
    final cubit = SetupCubit(deferred, session, Random(1));
    final pending = cubit.loadPlayers();
    await cubit.close();
    deferred.completer.complete([]);
    await pending;
  });
}

List<String> _names(int count) =>
    List.generate(count, (index) => 'player $index');

class DeferredPlayersStore extends PlayersStore {
  final completer = Completer<List<String>>();

  @override
  Future<List<String>> loadNames() => completer.future;
}
