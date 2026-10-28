import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/features/game/domain/assignment.dart';
import 'package:mafia/features/game/domain/game_session.dart';
import 'package:mafia/features/game/domain/player.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';

void main() {
  const first = Assignment(
    player: Player(name: 'أحمد'),
    role: RoleCatalog.mafia,
  );
  const second = Assignment(
    player: Player(name: 'محمد'),
    role: RoleCatalog.citizen,
  );

  test('session starts empty and clear discards the current round', () {
    final session = GameSession();
    expect(session.assignments, isEmpty);

    session.start([first, second]);
    expect(session.assignments, [first, second]);

    session.clear();
    expect(session.assignments, isEmpty);
  });

  test('session protects its round from mutation through input and getter', () {
    final assignments = [first];
    final session = GameSession()..start(assignments);
    assignments.add(second);

    expect(session.assignments, [first]);
    expect(session.assignments.clear, throwsUnsupportedError);
  });

  test('starting a new round replaces the previous assignments', () {
    final session = GameSession()..start([first]);

    session.start([second]);

    expect(session.assignments, [second]);
    expect(GameSession().assignments, isEmpty);
  });
}
