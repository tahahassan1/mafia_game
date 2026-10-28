import 'dart:math';

import '../../roles/domain/role.dart';
import '../../roles/domain/role_catalog.dart';
import '../../roles/domain/team.dart';
import 'assignment.dart';
import 'player.dart';
import 'setup_config.dart';
import 'setup_validator.dart';
import 'validation_result.dart';

class RoleDistributor {
  const RoleDistributor();

  List<Assignment> deal(
    List<Player> players,
    SetupConfig config,
    Random random,
  ) {
    final validation = const SetupValidator().validate(
      players.map((player) => player.name).toList(),
      config,
    );
    if (validation case Invalid(:final reason)) {
      throw StateError(reason.name);
    }

    final enabledRoles = config.enabledRoles;
    final mafiaSpecialCount = enabledRoles
        .where((role) => role.team == Team.mafia)
        .length;
    final roles = <Role>[
      ...List.filled(config.mafiaCount - mafiaSpecialCount, RoleCatalog.mafia),
      ...enabledRoles,
    ];
    roles.addAll(
      List.filled(players.length - roles.length, RoleCatalog.citizen),
    );
    roles.shuffle(random);

    return List.unmodifiable([
      for (var index = 0; index < players.length; index++)
        Assignment(player: players[index], role: roles[index]),
    ]);
  }
}
