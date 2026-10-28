import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class TestPreferences implements SharedPreferencesAsync {
  TestPreferences({this.firstWrite});

  final Map<String, List<String>> values = {};
  final List<List<String>> writes = [];
  final Completer<void>? firstWrite;
  final Map<String, bool> _failures = {};
  bool get failWrite => _failures['write'] ?? false;
  set failWrite(bool value) => _failures['write'] = value;
  bool get failRead => _failures['read'] ?? false;
  set failRead(bool value) => _failures['read'] = value;

  @override
  Future<List<String>?> getStringList(String key) async {
    if (failRead) throw StateError('read');
    return values[key];
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    writes.add(List.of(value));
    if (writes.length == 1 && firstWrite != null) await firstWrite!.future;
    if (failWrite) throw StateError('write');
    values[key] = List.of(value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
