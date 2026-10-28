import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/core/di.dart';
import 'package:mafia/features/game/domain/game_session.dart';

void main() {
  setUp(() => getIt.reset());
  tearDown(() => getIt.reset());

  test('session and random are registered as lazy singletons', () {
    configureDependencies();

    expect(getIt<GameSession>(), same(getIt<GameSession>()));
    expect(getIt<Random>(), same(getIt<Random>()));
  });

  test('tests can replace the registered random with a fixed seed', () async {
    configureDependencies();
    await getIt.unregister<Random>();
    getIt.registerLazySingleton<Random>(() => Random(42));

    expect(getIt<Random>().nextInt(1000), Random(42).nextInt(1000));
  });
}
