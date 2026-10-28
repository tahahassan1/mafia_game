import 'dart:async';

import 'memory_players_store.dart';

class ControlledPlayersStore extends MemoryPlayersStore {
  bool failReads = false;
  bool failWrites = false;
  bool deferWrites = false;
  final List<List<String>> attempts = [];
  final List<Completer<void>> pending = [];

  @override
  Future<List<String>> loadNames() async {
    if (failReads) throw StateError('read');
    return super.loadNames();
  }

  @override
  Future<void> saveNames(List<String> names) async {
    final snapshot = List<String>.of(names);
    attempts.add(snapshot);
    if (deferWrites) {
      final completion = Completer<void>();
      pending.add(completion);
      await completion.future;
    }
    if (failWrites) throw StateError('write');
    await super.saveNames(snapshot);
  }
}
