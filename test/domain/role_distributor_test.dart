import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/features/game/domain/assignment.dart';
import 'package:mafia/features/game/domain/player.dart';
import 'package:mafia/features/game/domain/role_distributor.dart';
import 'package:mafia/features/game/domain/setup_config.dart';
import 'package:mafia/features/roles/domain/role.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';
import 'package:mafia/features/roles/domain/team.dart';

void main() {
  const distributor = RoleDistributor();

  test('same seed reproduces assignments without changing inputs', () {
    final players = _players(7);
    final originalPlayers = List<Player>.of(players);
    final config = SetupConfig(
      mafiaCount: 2,
      enabledRoleIds: {RoleCatalog.detective.id, RoleCatalog.doctor.id},
    );

    final first = distributor.deal(players, config, Random(42));
    final second = distributor.deal(players, config, Random(42));

    expect(first, second);
    expect(players, originalPlayers);
    expect(first.map((assignment) => assignment.player), originalPlayers);
    expect(
      first.indexed.every(
        (entry) => identical(entry.$2.player, players[entry.$1]),
      ),
      isTrue,
    );
  });

  test('seed affects which player receives each role', () {
    final config = SetupConfig(
      mafiaCount: 2,
      enabledRoleIds: {RoleCatalog.detective.id, RoleCatalog.doctor.id},
    );
    final players = _players(7);
    final arrangements = {
      for (var seed = 0; seed < 10; seed++)
        distributor
            .deal(players, config, Random(seed))
            .map((assignment) => assignment.role.id)
            .join(','),
    };

    expect(arrangements.length, greaterThan(1));
  });

  test('documented seven-player round has the exact expected counts', () {
    final assignments = distributor.deal(
      _players(7),
      SetupConfig(
        mafiaCount: 2,
        enabledRoleIds: {
          RoleCatalog.godfather.id,
          RoleCatalog.detective.id,
          RoleCatalog.doctor.id,
          RoleCatalog.jester.id,
        },
      ),
      Random(7),
    );

    expect(assignments, hasLength(7));
    expect(_count(assignments, RoleCatalog.godfather), 1);
    expect(_count(assignments, RoleCatalog.mafia), 1);
    expect(_count(assignments, RoleCatalog.detective), 1);
    expect(_count(assignments, RoleCatalog.doctor), 1);
    expect(_count(assignments, RoleCatalog.jester), 1);
    expect(_count(assignments, RoleCatalog.citizen), 2);
    expect(
      assignments.where((assignment) => assignment.role.team == Team.mafia),
      hasLength(2),
    );
  });

  test('every enabled special appears once and citizens fill the rest', () {
    final assignments = distributor.deal(
      _players(12),
      SetupConfig(
        mafiaCount: 3,
        enabledRoleIds: RoleCatalog.specials.map((role) => role.id).toSet(),
      ),
      Random(10),
    );

    expect(assignments, hasLength(12));
    for (final role in RoleCatalog.specials) {
      expect(_count(assignments, role), 1, reason: role.id);
    }
    expect(_count(assignments, RoleCatalog.mafia), 2);
    expect(_count(assignments, RoleCatalog.citizen), 2);
  });

  test('no enabled specials gives only the configured mafia and citizens', () {
    final assignments = distributor.deal(
      _players(25),
      SetupConfig(mafiaCount: 12, enabledRoleIds: {}),
      Random(1),
    );

    expect(assignments, hasLength(25));
    expect(_count(assignments, RoleCatalog.mafia), 12);
    expect(_count(assignments, RoleCatalog.citizen), 13);
  });

  test('a single mafia slot may consist entirely of the godfather', () {
    final assignments = distributor.deal(
      _players(4),
      SetupConfig(mafiaCount: 1, enabledRoleIds: {RoleCatalog.godfather.id}),
      Random(1),
    );

    expect(_count(assignments, RoleCatalog.godfather), 1);
    expect(_count(assignments, RoleCatalog.mafia), 0);
    expect(_count(assignments, RoleCatalog.citizen), 3);
  });

  test('zero citizens is valid and no disabled role appears', () {
    final config = SetupConfig(
      mafiaCount: 1,
      enabledRoleIds: {
        RoleCatalog.godfather.id,
        RoleCatalog.detective.id,
        RoleCatalog.doctor.id,
        RoleCatalog.jester.id,
      },
    );
    final assignments = distributor.deal(_players(4), config, Random(1));

    expect(assignments, hasLength(4));
    expect(_count(assignments, RoleCatalog.citizen), 0);
    expect(_count(assignments, RoleCatalog.mafia), 0);
    expect(
      assignments.map((assignment) => assignment.role.id).toSet(),
      config.enabledRoleIds,
    );
  });

  test('all documented validation failures cause StateError on deal', () {
    for (final count in [3, 26]) {
      expect(
        () => distributor.deal(
          _players(count),
          SetupConfig(mafiaCount: 1, enabledRoleIds: {}),
          Random(1),
        ),
        throwsStateError,
      );
    }
    for (final config in [
      SetupConfig(mafiaCount: 0, enabledRoleIds: {}),
      SetupConfig(mafiaCount: -1, enabledRoleIds: {}),
      SetupConfig(mafiaCount: 2, enabledRoleIds: {}),
      SetupConfig(mafiaCount: 1, enabledRoleIds: {'unknown'}),
      SetupConfig(
        mafiaCount: 1,
        enabledRoleIds: RoleCatalog.specials.map((role) => role.id).toSet(),
      ),
    ]) {
      expect(
        () => distributor.deal(_players(4), config, Random(1)),
        throwsStateError,
      );
    }
    for (final name in ['', '   ', 'player 1', ' player 1 ']) {
      expect(
        () => distributor.deal(
          [Player(name: name), ..._players(3)],
          SetupConfig(mafiaCount: 1, enabledRoleIds: {}),
          Random(1),
        ),
        throwsStateError,
      );
    }
  });

  test('returned assignments cannot be modified', () {
    final assignments = distributor.deal(
      _players(4),
      SetupConfig(mafiaCount: 1, enabledRoleIds: {}),
      Random(1),
    );

    expect(assignments.clear, throwsUnsupportedError);
  });
}

List<Player> _players(int count) =>
    List.generate(count, (index) => Player(name: 'player $index'));

int _count(List<Assignment> assignments, Role role) =>
    assignments.where((assignment) => assignment.role == role).length;
