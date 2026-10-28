import 'package:equatable/equatable.dart';

import '../../roles/domain/role.dart';
import '../../roles/domain/role_catalog.dart';

class SetupConfig extends Equatable {
  SetupConfig({required this.mafiaCount, required Set<String> enabledRoleIds})
    : enabledRoleIds = Set.unmodifiable(enabledRoleIds);

  final int mafiaCount;
  final Set<String> enabledRoleIds;

  List<Role> get enabledRoles => List.unmodifiable(
    RoleCatalog.specials.where((role) => enabledRoleIds.contains(role.id)),
  );

  @override
  List<Object> get props => [mafiaCount, enabledRoleIds];
}
