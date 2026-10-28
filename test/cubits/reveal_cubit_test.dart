import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/features/game/domain/assignment.dart';
import 'package:mafia/features/game/domain/game_session.dart';
import 'package:mafia/features/game/domain/player.dart';
import 'package:mafia/features/reveal/reveal_cubit.dart';
import 'package:mafia/features/reveal/reveal_state.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';

void main() {
  late GameSession session;
  const assignments = [
    Assignment(
      player: Player(name: 'أحمد'),
      role: RoleCatalog.doctor,
    ),
    Assignment(
      player: Player(name: 'منى'),
      role: RoleCatalog.mafia,
    ),
  ];

  setUp(() => session = GameSession()..start(assignments));

  test('starts with the first assignment read from the session', () async {
    final cubit = RevealCubit(session);
    addTearDown(cubit.close);
    expect(cubit.state, const RevealState());
    expect(cubit.currentAssignment, same(session.assignments.first));
    expect(cubit.currentAssignment!.player.name, 'أحمد');
    expect(cubit.currentAssignment!.role, RoleCatalog.doctor);
  });

  blocTest<RevealCubit, RevealState>(
    'reveal, hide, advance and finish; repeated actions cannot skip or restart',
    build: () => RevealCubit(session),
    act: (cubit) {
      expect(cubit.hideAndNext(), isFalse);
      cubit.reveal();
      cubit.reveal();
      expect(cubit.hideAndNext(), isFalse);
      expect(cubit.currentAssignment, assignments.last);
      expect(cubit.hideAndNext(), isFalse);
      cubit.reveal();
      expect(cubit.hideAndNext(), isTrue);
      expect(cubit.currentAssignment, isNull);
      cubit.reveal();
      expect(cubit.hideAndNext(), isFalse);
    },
    expect: () => const [
      RevealState(isRevealed: true),
      RevealState(currentIndex: 1),
      RevealState(currentIndex: 1, isRevealed: true),
      RevealState(currentIndex: 2, isFinished: true),
    ],
    verify: (_) => expect(session.assignments, assignments),
  );

  blocTest<RevealCubit, RevealState>(
    'empty session is finished and all actions are safe no-ops',
    setUp: () => session.clear(),
    build: () => RevealCubit(session),
    act: (cubit) {
      expect(cubit.state, const RevealState(isFinished: true));
      expect(cubit.currentAssignment, isNull);
      cubit.reveal();
      expect(cubit.hideAndNext(), isFalse);
    },
    expect: () => <RevealState>[],
  );

  blocTest<RevealCubit, RevealState>(
    'one assignment finishes only after revealing and hiding',
    setUp: () => session.start([assignments.first]),
    build: () => RevealCubit(session),
    act: (cubit) {
      cubit.reveal();
      expect(cubit.hideAndNext(), isTrue);
    },
    expect: () => const [
      RevealState(isRevealed: true),
      RevealState(currentIndex: 1, isFinished: true),
    ],
  );

  blocTest<RevealCubit, RevealState>(
    'a cleared session cannot be indexed or reveal old data',
    build: () => RevealCubit(session),
    act: (cubit) {
      session.clear();
      expect(cubit.currentAssignment, isNull);
      cubit.reveal();
    },
    expect: () => const [RevealState(isFinished: true)],
  );

  test('state equality includes index, visibility, and completion', () {
    expect(const RevealState(), const RevealState());
    expect(const RevealState(currentIndex: 1), isNot(const RevealState()));
    expect(const RevealState(isRevealed: true), isNot(const RevealState()));
    expect(const RevealState(isFinished: true), isNot(const RevealState()));
  });
}
