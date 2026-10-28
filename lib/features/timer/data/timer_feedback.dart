import 'package:flutter/services.dart';

abstract final class TimerFeedback {
  static const String channelName = 'mafia/timer_feedback';
  static const MethodChannel _channel = MethodChannel(channelName);

  static Future<void> playFinishSound() =>
      _channel.invokeMethod<void>('playFinishSound');
}
