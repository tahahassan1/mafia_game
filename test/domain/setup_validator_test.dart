import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/features/game/domain/setup_config.dart';
import 'package:mafia/features/game/domain/setup_validator.dart';
import 'package:mafia/features/game/domain/validation_reason.dart';
import 'package:mafia/features/game/domain/validation_result.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';

void main() {
  const validator = SetupValidator();

  group('player and mafia count boundaries', () {
    for (final (players, mafia, reason) in <(int, int, ValidationReason?)>[
      (3, 1, ValidationReason.tooFewPlayers),
      (4, 1, null),
      (4, 2, ValidationReason.mafiaNotMinority),
      (5, 2, null),
      (6, 2, null),
      (6, 3, ValidationReason.mafiaNotMinority),
      (25, 12, null),
      (25, 13, ValidationReason.mafiaNotMinority),
      (26, 1, ValidationReason.tooManyPlayers),
      (4, 0, ValidationReason.mafiaCountTooLow),
      (4, -1, ValidationReason.mafiaCountTooLow),
    ]) {
      test('$players players and $mafia mafia', () {
        final result = validator.validate(
          _names(players),
          SetupConfig(mafiaCount: mafia, enabledRoleIds: {}),
        );

        expect(result, reason == null ? const Valid() : Invalid(reason));
      });
    }
  });

  test('special roles may fill every remaining slot', () {
    final config = SetupConfig(
      mafiaCount: 1,
      enabledRoleIds: {
        RoleCatalog.detective.id,
        RoleCatalog.doctor.id,
        RoleCatalog.jester.id,
      },
    );

    expect(validator.validate(_names(4), config), const Valid());
  });

  test('one special beyond the remaining slots is rejected', () {
    final config = SetupConfig(
      mafiaCount: 1,
      enabledRoleIds: {
        RoleCatalog.detective.id,
        RoleCatalog.doctor.id,
        RoleCatalog.jester.id,
        RoleCatalog.guard.id,
      },
    );

    expect(
      validator.validate(_names(4), config),
      const Invalid(ValidationReason.tooManySpecialRoles),
    );
  });

  test('godfather consumes a mafia slot, including at full capacity', () {
    final config = SetupConfig(
      mafiaCount: 1,
      enabledRoleIds: {
        RoleCatalog.godfather.id,
        RoleCatalog.detective.id,
        RoleCatalog.doctor.id,
        RoleCatalog.jester.id,
      },
    );

    expect(validator.validate(_names(4), config), const Valid());
  });

  for (final name in ['', '   ', '\t\n']) {
    test('empty or whitespace-only name ${name.codeUnits} is rejected', () {
      expect(
        validator.validate([
          name,
          'أحمد',
          'محمد',
          'علي',
        ], SetupConfig(mafiaCount: 1, enabledRoleIds: {})),
        const Invalid(ValidationReason.emptyPlayerName),
      );
    });
  }

  for (final duplicate in ['أحمد', ' أحمد ']) {
    test('duplicate name "$duplicate" is rejected after trimming', () {
      expect(
        validator.validate([
          'أحمد',
          duplicate,
          'محمد',
          'علي',
        ], SetupConfig(mafiaCount: 1, enabledRoleIds: {})),
        const Invalid(ValidationReason.duplicatePlayerName),
      );
    });
  }

  test('distinct names are compared exactly and inputs are preserved', () {
    final names = [' أحمد ', 'محمد', 'Ali', 'ali'];

    expect(
      validator.validate(names, SetupConfig(mafiaCount: 1, enabledRoleIds: {})),
      const Valid(),
    );
    expect(names.first, ' أحمد ');
  });

  for (final invalidId in [
    'unknown',
    RoleCatalog.mafia.id,
    RoleCatalog.citizen.id,
  ]) {
    test('non-special or unknown selection "$invalidId" is rejected', () {
      expect(
        validator.validate(
          _names(4),
          SetupConfig(mafiaCount: 1, enabledRoleIds: {invalidId}),
        ),
        const Invalid(ValidationReason.invalidRoleSelection),
      );
    });
  }

  test('setup config owns an immutable copy of the selected IDs', () {
    final selectedIds = {RoleCatalog.doctor.id};
    final config = SetupConfig(mafiaCount: 1, enabledRoleIds: selectedIds);
    selectedIds.add(RoleCatalog.detective.id);

    expect(config.enabledRoleIds, {RoleCatalog.doctor.id});
    expect(
      () => config.enabledRoleIds.add(RoleCatalog.detective.id),
      throwsUnsupportedError,
    );
  });
}

List<String> _names(int count) =>
    List.generate(count, (index) => 'player $index');
