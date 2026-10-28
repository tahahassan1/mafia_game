import 'package:shared_preferences/shared_preferences.dart';

class PlayersStore {
  PlayersStore({this._preferences});

  static const String namesKey = 'player_names';
  SharedPreferencesAsync? _preferences;
  Future<void> _pendingWrite = Future<void>.value();

  SharedPreferencesAsync get _storage =>
      _preferences ??= SharedPreferencesAsync();

  Future<List<String>> loadNames() async {
    await _pendingWrite;
    return List.unmodifiable(
      await _storage.getStringList(namesKey) ?? const <String>[],
    );
  }

  Future<void> saveNames(List<String> names) {
    final snapshot = List<String>.of(names);
    final write = _pendingWrite.then(
      (_) => _storage.setStringList(namesKey, snapshot),
    );
    // Recover only the queue; the returned future still reports this failure.
    _pendingWrite = write.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return write;
  }
}
