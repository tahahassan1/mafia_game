import '../../../core/constants.dart';
import '../../roles/domain/team.dart';
import 'setup_config.dart';
import 'validation_reason.dart';
import 'validation_result.dart';

class SetupValidator {
  const SetupValidator();

  ValidationResult validate(List<String> playerNames, SetupConfig config) {
    if (playerNames.length < GameLimits.minPlayers) {
      return const Invalid(ValidationReason.tooFewPlayers);
    }
    if (playerNames.length > GameLimits.maxPlayers) {
      return const Invalid(ValidationReason.tooManyPlayers);
    }

    final names = playerNames.map((name) => name.trim()).toList();
    if (names.any((name) => name.isEmpty)) {
      return const Invalid(ValidationReason.emptyPlayerName);
    }
    if (names.toSet().length != names.length) {
      return const Invalid(ValidationReason.duplicatePlayerName);
    }

    final enabledRoles = config.enabledRoles;
    if (enabledRoles.length != config.enabledRoleIds.length) {
      return const Invalid(ValidationReason.invalidRoleSelection);
    }

    final mafiaSpecialCount = enabledRoles
        .where((role) => role.team == Team.mafia)
        .length;
    if (config.mafiaCount < 1 || config.mafiaCount < mafiaSpecialCount) {
      return const Invalid(ValidationReason.mafiaCountTooLow);
    }
    if (2 * config.mafiaCount >= playerNames.length) {
      return const Invalid(ValidationReason.mafiaNotMinority);
    }

    final nonMafiaSpecialCount = enabledRoles.length - mafiaSpecialCount;
    if (config.mafiaCount + nonMafiaSpecialCount > playerNames.length) {
      return const Invalid(ValidationReason.tooManySpecialRoles);
    }

    return const Valid();
  }
}
