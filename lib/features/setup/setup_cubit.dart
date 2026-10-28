import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants.dart';
import '../game/data/players_store.dart';
import '../game/domain/game_session.dart';
import '../game/domain/player.dart';
import '../game/domain/role_distributor.dart';
import '../game/domain/setup_config.dart';
import '../game/domain/setup_validator.dart';
import '../game/domain/validation_reason.dart';
import '../game/domain/validation_result.dart';
import '../roles/domain/role_catalog.dart';
import '../roles/domain/team.dart';
import 'setup_state.dart';

class SetupCubit extends Cubit<SetupState> {
  SetupCubit(this._store, this._session, this._random) : super(_initialState());

  final PlayersStore _store;
  final GameSession _session;
  final Random _random;
  int _playersVersion = 0;

  static SetupState _initialState() => SetupState(
    players: const [],
    mafiaCount: 1,
    enabledRoleIds: Set.unmodifiable(
      RoleCatalog.defaultSpecials.map((role) => role.id),
    ),
    validation: const Invalid(ValidationReason.tooFewPlayers),
    playersValidation: const Invalid(ValidationReason.tooFewPlayers),
    minMafiaCount: 1,
    maxMafiaCount: 1,
    specialRolesToDisable: 3,
  );

  Future<void> loadPlayers() async {
    final version = _playersVersion;
    final names = await _store.loadNames();
    if (isClosed || version != _playersVersion) return;
    _apply(state.copyWith(players: List.unmodifiable(names)));
  }

  void startEditing(int index) {
    if (index < 0 || index >= state.players.length) return;
    emit(state.copyWith(editingIndex: index, clearNameError: true));
  }

  void cancelEditing() {
    emit(state.copyWith(clearEditing: true, clearNameError: true));
  }

  void nameChanged() {
    if (state.nameError != null) emit(state.copyWith(clearNameError: true));
  }

  Future<bool> submitPlayer(String value) async {
    final name = value.trim();
    final index = state.editingIndex;
    if (name.isEmpty) {
      emit(state.copyWith(nameError: ValidationReason.emptyPlayerName));
      return false;
    }
    final duplicate = state.players.indexed.any(
      (entry) => entry.$1 != index && entry.$2.trim() == name,
    );
    if (duplicate) {
      emit(state.copyWith(nameError: ValidationReason.duplicatePlayerName));
      return false;
    }
    if (index == null && state.players.length >= GameLimits.maxPlayers) {
      emit(state.copyWith(nameError: ValidationReason.tooManyPlayers));
      return false;
    }

    final players = List<String>.of(state.players);
    if (index == null) {
      players.add(name);
    } else {
      players[index] = name;
    }
    _playersVersion++;
    _apply(
      state.copyWith(
        players: List.unmodifiable(players),
        clearEditing: true,
        clearNameError: true,
      ),
    );
    await _store.saveNames(state.players);
    return true;
  }

  Future<void> removePlayer(int index) async {
    if (index < 0 || index >= state.players.length) return;
    final players = List<String>.of(state.players)..removeAt(index);
    final editingIndex = state.editingIndex;
    _playersVersion++;
    _apply(
      state.copyWith(
        players: List.unmodifiable(players),
        editingIndex: editingIndex != null && editingIndex > index
            ? editingIndex - 1
            : editingIndex,
        clearEditing: editingIndex == index,
        clearNameError: true,
      ),
    );
    await _store.saveNames(state.players);
  }

  void increaseMafia() {
    if (state.canIncreaseMafia) {
      _apply(state.copyWith(mafiaCount: state.mafiaCount + 1));
    }
  }

  void decreaseMafia() {
    if (state.canDecreaseMafia) {
      _apply(state.copyWith(mafiaCount: state.mafiaCount - 1));
    }
  }

  void toggleRole(String id) {
    if (!RoleCatalog.specials.any((role) => role.id == id)) return;
    final ids = Set<String>.of(state.enabledRoleIds);
    if (!ids.remove(id)) ids.add(id);
    _apply(state.copyWith(enabledRoleIds: Set.unmodifiable(ids)));
  }

  void beginSetup() {
    emit(state.copyWith(hasDealt: false));
  }

  bool deal() {
    if (!state.canDeal) return false;
    final assignments = const RoleDistributor().deal(
      state.players.map((name) => Player(name: name)).toList(),
      SetupConfig(
        mafiaCount: state.mafiaCount,
        enabledRoleIds: state.enabledRoleIds,
      ),
      _random,
    );
    _session.start(assignments);
    emit(state.copyWith(hasDealt: true));
    return true;
  }

  void _apply(SetupState next) {
    final selected = SetupConfig(
      mafiaCount: next.mafiaCount,
      enabledRoleIds: next.enabledRoleIds,
    ).enabledRoles;
    final mafiaSpecials = selected
        .where((role) => role.team == Team.mafia)
        .length;
    final minimum = max(1, mafiaSpecials);
    final maximum = max(minimum, (next.players.length - 1) ~/ 2);
    final mafiaCount = next.mafiaCount.clamp(minimum, maximum);
    final config = SetupConfig(
      mafiaCount: mafiaCount,
      enabledRoleIds: next.enabledRoleIds,
    );
    const validator = SetupValidator();
    emit(
      next.copyWith(
        mafiaCount: mafiaCount,
        minMafiaCount: minimum,
        maxMafiaCount: maximum,
        specialRolesToDisable: max(
          0,
          mafiaCount + selected.length - mafiaSpecials - next.players.length,
        ),
        validation: validator.validate(next.players, config),
        playersValidation: validator.validate(
          next.players,
          SetupConfig(mafiaCount: 1, enabledRoleIds: {}),
        ),
      ),
    );
  }
}
