import 'dart:math';

import 'package:get_it/get_it.dart';

import '../features/game/domain/game_session.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<GameSession>(GameSession.new);
  getIt.registerLazySingleton<Random>(Random.new);
}
