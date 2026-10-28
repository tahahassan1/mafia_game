import 'assignment.dart';

class GameSession {
  List<Assignment> _assignments = const [];

  List<Assignment> get assignments => _assignments;

  void start(List<Assignment> assignments) {
    _assignments = List.unmodifiable(assignments);
  }

  void clear() {
    _assignments = const [];
  }
}
