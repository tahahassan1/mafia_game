import 'package:equatable/equatable.dart';

import '../../core/constants.dart';

sealed class TimerState extends Equatable {
  const TimerState(this.duration);

  final Duration duration;

  Duration get remaining => duration;
  int get minutes => duration.inMinutes;
  int get seconds => duration.inSeconds.remainder(Duration.secondsPerMinute);
  int get displaySeconds =>
      (remaining.inMicroseconds + Duration.microsecondsPerSecond - 1) ~/
      Duration.microsecondsPerSecond;

  bool get canIncreaseMinutes =>
      this is TimerIdle && minutes < TimerLimits.maxMinutes;
  bool get canDecreaseMinutes =>
      this is TimerIdle &&
      duration - const Duration(minutes: 1) >= TimerLimits.minDuration;
  bool get canIncreaseSeconds =>
      this is TimerIdle && seconds < TimerLimits.maxSeconds;
  bool get canDecreaseSeconds =>
      this is TimerIdle && seconds > 0 && duration > TimerLimits.minDuration;
}

final class TimerIdle extends TimerState {
  const TimerIdle(super.duration);

  @override
  List<Object> get props => [duration];
}

final class TimerRunning extends TimerState {
  const TimerRunning(
    super.duration, {
    required this.endAt,
    required this.remaining,
  });

  final DateTime endAt;
  @override
  final Duration remaining;

  @override
  List<Object> get props => [duration, endAt, remaining];
}

final class TimerPaused extends TimerState {
  const TimerPaused(super.duration, {required this.remaining});

  @override
  final Duration remaining;

  @override
  List<Object> get props => [duration, remaining];
}

final class TimerFinished extends TimerState {
  const TimerFinished(super.duration);

  @override
  Duration get remaining => Duration.zero;

  @override
  List<Object> get props => [duration];
}
