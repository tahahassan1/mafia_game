import 'package:equatable/equatable.dart';

import '../game/domain/validation_reason.dart';
import '../game/domain/validation_result.dart';

class SetupState extends Equatable {
  const SetupState({
    required this.players,
    required this.mafiaCount,
    required this.enabledRoleIds,
    required this.validation,
    required this.playersValidation,
    required this.minMafiaCount,
    required this.maxMafiaCount,
    required this.specialRolesToDisable,
    this.nameError,
    this.editingIndex,
    this.hasDealt = false,
    this.namesSaveFailed = false,
    this.namesLoadFailed = false,
  });

  final List<String> players;
  final int mafiaCount;
  final Set<String> enabledRoleIds;
  final ValidationResult validation;
  final ValidationResult playersValidation;
  final int minMafiaCount;
  final int maxMafiaCount;
  final int specialRolesToDisable;
  final ValidationReason? nameError;
  final int? editingIndex;
  final bool hasDealt;
  final bool namesSaveFailed;
  final bool namesLoadFailed;

  bool get canAdvance => playersValidation is Valid;
  bool get canDeal => validation is Valid && !hasDealt;
  bool get canIncreaseMafia => mafiaCount < maxMafiaCount;
  bool get canDecreaseMafia => mafiaCount > minMafiaCount;

  SetupState copyWith({
    List<String>? players,
    int? mafiaCount,
    Set<String>? enabledRoleIds,
    ValidationResult? validation,
    ValidationResult? playersValidation,
    int? minMafiaCount,
    int? maxMafiaCount,
    int? specialRolesToDisable,
    ValidationReason? nameError,
    int? editingIndex,
    bool clearNameError = false,
    bool clearEditing = false,
    bool? hasDealt,
    bool? namesSaveFailed,
    bool? namesLoadFailed,
  }) => SetupState(
    players: players ?? this.players,
    mafiaCount: mafiaCount ?? this.mafiaCount,
    enabledRoleIds: enabledRoleIds ?? this.enabledRoleIds,
    validation: validation ?? this.validation,
    playersValidation: playersValidation ?? this.playersValidation,
    minMafiaCount: minMafiaCount ?? this.minMafiaCount,
    maxMafiaCount: maxMafiaCount ?? this.maxMafiaCount,
    specialRolesToDisable: specialRolesToDisable ?? this.specialRolesToDisable,
    nameError: clearNameError ? null : nameError ?? this.nameError,
    editingIndex: clearEditing ? null : editingIndex ?? this.editingIndex,
    hasDealt: hasDealt ?? this.hasDealt,
    namesSaveFailed: namesSaveFailed ?? this.namesSaveFailed,
    namesLoadFailed: namesLoadFailed ?? this.namesLoadFailed,
  );

  @override
  List<Object?> get props => [
    players,
    mafiaCount,
    enabledRoleIds,
    validation,
    playersValidation,
    minMafiaCount,
    maxMafiaCount,
    specialRolesToDisable,
    nameError,
    editingIndex,
    hasDealt,
    namesSaveFailed,
    namesLoadFailed,
  ];
}
