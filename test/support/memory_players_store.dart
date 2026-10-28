import 'package:mafia/features/game/data/players_store.dart';

class MemoryPlayersStore extends PlayersStore {
  List<String> _names = const [];

  @override
  Future<List<String>> loadNames() async => _names;

  @override
  Future<void> saveNames(List<String> names) async {
    _names = List.unmodifiable(names);
  }
}
