import 'package:equatable/equatable.dart';

import '../../roles/domain/role.dart';
import 'player.dart';

class Assignment extends Equatable {
  const Assignment({required this.player, required this.role});

  final Player player;
  final Role role;

  @override
  List<Object> get props => [player, role];
}
