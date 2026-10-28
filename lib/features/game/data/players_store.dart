class PlayersStore {
  List<String> _names = const [];

  Future<List<String>> loadNames() async => _names;

  Future<void> saveNames(List<String> names) async {
    _names = List.unmodifiable(names);
  }
}
