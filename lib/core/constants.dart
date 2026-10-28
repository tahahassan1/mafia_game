abstract final class GameLimits {
  static const int minPlayers = 4;
  static const int maxPlayers = 25;
}

abstract final class TimerLimits {
  static const Duration defaultDuration = Duration(minutes: 3);
  static const Duration minDuration = Duration(seconds: 1);
  static const Duration maxDuration = Duration(minutes: 99, seconds: 59);
  static const int maxMinutes = 99;
  static const int maxSeconds = 59;
  static const Duration refreshInterval = Duration(milliseconds: 250);
  static const Duration hostLongPress = Duration(seconds: 1);
  static const Duration hostAutoClose = Duration(seconds: 10);
}
