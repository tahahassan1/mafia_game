import 'role.dart';
import 'team.dart';

abstract final class RoleCatalog {
  static const Role mafia = Role(
    id: 'mafia',
    nameAr: 'مافيا',
    descriptionAr: 'عضو في المافيا',
    team: Team.mafia,
    isSpecial: false,
  );
  static const Role citizen = Role(
    id: 'citizen',
    nameAr: 'مواطن',
    descriptionAr: 'مواطن عادي',
    team: Team.civilian,
    isSpecial: false,
  );
  static const Role godfather = Role(
    id: 'godfather',
    nameAr: 'العراب',
    descriptionAr: 'قائد المافيا، يخدع المحقق',
    team: Team.mafia,
    isSpecial: true,
  );
  static const Role detective = Role(
    id: 'detective',
    nameAr: 'المحقق',
    descriptionAr: 'يكشف هوية لاعب كل ليلة',
    team: Team.civilian,
    isSpecial: true,
  );
  static const Role doctor = Role(
    id: 'doctor',
    nameAr: 'الدكتور',
    descriptionAr: 'يحمي لاعب من القتل كل ليلة',
    team: Team.civilian,
    isSpecial: true,
  );
  static const Role guard = Role(
    id: 'guard',
    nameAr: 'الحارس',
    descriptionAr: 'يحمي لاعب ويموت بدلًا عنه',
    team: Team.civilian,
    isSpecial: true,
  );
  static const Role spy = Role(
    id: 'spy',
    nameAr: 'الجاسوس',
    descriptionAr: 'يقتل أو يتجسس كل ليلة',
    team: Team.civilian, // TODO: confirm
    isSpecial: true,
  );
  static const Role hunter = Role(
    id: 'hunter',
    nameAr: 'الصياد',
    descriptionAr: 'ينتقم عند إقصائه بالتصويت',
    team: Team.civilian, // TODO: confirm
    isSpecial: true,
  );
  static const Role gambler = Role(
    id: 'gambler',
    nameAr: 'المراهن',
    descriptionAr: 'يراهن على إقصاء لاعب بالتصويت',
    team: Team.civilian, // TODO: confirm
    isSpecial: true,
  );
  static const Role jester = Role(
    id: 'jester',
    nameAr: 'المهرج',
    descriptionAr: 'يفوز إذا تم إقصاؤه بالتصويت',
    team: Team.neutral,
    isSpecial: true,
  );

  static const List<Role> specials = [
    godfather,
    detective,
    doctor,
    guard,
    spy,
    hunter,
    gambler,
    jester,
  ];

  static const List<Role> all = [mafia, citizen, ...specials];

  static const List<Role> defaultSpecials = [detective, doctor];
}
