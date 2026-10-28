import 'package:equatable/equatable.dart';

import 'team.dart';

class Role extends Equatable {
  const Role({
    required this.id,
    required this.nameAr,
    required this.descriptionAr,
    required this.team,
    required this.isSpecial,
  });

  final String id;
  final String nameAr;
  final String descriptionAr;
  final Team team;
  final bool isSpecial;

  @override
  List<Object> get props => [id, nameAr, descriptionAr, team, isSpecial];
}
