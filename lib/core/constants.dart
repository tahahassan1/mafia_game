import 'package:flutter/widgets.dart';

abstract final class GameLimits {
  static const int minPlayers = 4;
  static const int maxPlayers = 25;
}

abstract final class AppLocale {
  static const Locale arabic = Locale('ar');
  static const List<Locale> supported = <Locale>[arabic];
}
