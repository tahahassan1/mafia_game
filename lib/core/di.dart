import 'dart:math';

import 'package:get_it/get_it.dart';

import '../features/game/data/players_store.dart';
import '../features/game/domain/game_session.dart';
import '../features/setup/setup_cubit.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<GameSession>(GameSession.new);
  getIt.registerLazySingleton<Random>(Random.new);
  getIt.registerLazySingleton<PlayersStore>(PlayersStore.new);
  getIt.registerFactory<SetupCubit>(
    () => SetupCubit(getIt(), getIt(), getIt()),
  );
}
