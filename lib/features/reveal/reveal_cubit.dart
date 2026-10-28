import 'package:flutter_bloc/flutter_bloc.dart';

import '../game/domain/assignment.dart';
import '../game/domain/game_session.dart';
import 'reveal_state.dart';

class RevealCubit extends Cubit<RevealState> {
  RevealCubit(this._session)
    : super(RevealState(isFinished: _session.assignments.isEmpty));

  final GameSession _session;

  Assignment? get currentAssignment {
    if (state.isFinished || state.currentIndex >= _session.assignments.length) {
      return null;
    }
    return _session.assignments[state.currentIndex];
  }

  void reveal() {
    if (state.isFinished || state.isRevealed) return;
    emit(
      RevealState(
        currentIndex: state.currentIndex,
        isRevealed: currentAssignment != null,
        isFinished: currentAssignment == null,
      ),
    );
  }

  /// Returns true only when this action completes the loop.
  bool hideAndNext() {
    if (state.isFinished || !state.isRevealed) return false;
    final nextIndex = state.currentIndex + 1;
    final finished = nextIndex >= _session.assignments.length;
    emit(RevealState(currentIndex: nextIndex, isFinished: finished));
    return finished;
  }
}
