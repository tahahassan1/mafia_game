import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants.dart';
import 'timer_state.dart';

class TimerCubit extends Cubit<TimerState> {
  TimerCubit(this._now, {required Duration initialDuration})
    : super(TimerIdle(_validatedDuration(initialDuration)));

  final DateTime Function() _now;
  StreamSubscription<int>? _ticker;

  static Duration _validatedDuration(Duration duration) {
    if (duration < TimerLimits.minDuration ||
        duration > TimerLimits.maxDuration ||
        duration.inMicroseconds.remainder(Duration.microsecondsPerSecond) !=
            0) {
      throw ArgumentError.value(duration);
    }
    return duration;
  }

  void setDuration(Duration duration) {
    if (state is! TimerIdle ||
        duration < TimerLimits.minDuration ||
        duration > TimerLimits.maxDuration ||
        duration.inMicroseconds.remainder(Duration.microsecondsPerSecond) !=
            0) {
      return;
    }
    emit(TimerIdle(duration));
  }

  void increaseMinutes() {
    if (state.canIncreaseMinutes) {
      setDuration(state.duration + const Duration(minutes: 1));
    }
  }

  void decreaseMinutes() {
    if (state.canDecreaseMinutes) {
      setDuration(state.duration - const Duration(minutes: 1));
    }
  }

  void increaseSeconds() {
    if (state.canIncreaseSeconds) {
      setDuration(state.duration + const Duration(seconds: 1));
    }
  }

  void decreaseSeconds() {
    if (state.canDecreaseSeconds) {
      setDuration(state.duration - const Duration(seconds: 1));
    }
  }

  void start() {
    if (state is! TimerIdle && state is! TimerFinished) return;
    _run(state.duration);
  }

  void resume() {
    if (state case TimerPaused(:final remaining)) _run(remaining);
  }

  void _run(Duration remaining) {
    emit(
      TimerRunning(
        state.duration,
        endAt: _now().add(remaining),
        remaining: remaining,
      ),
    );
    _ticker = Stream<int>.periodic(
      TimerLimits.refreshInterval,
      (tick) => tick,
    ).listen((_) => refresh());
  }

  void refresh() {
    if (isClosed) return;
    if (state case TimerRunning(:final endAt)) {
      final remaining = endAt.difference(_now());
      if (remaining <= Duration.zero) {
        _stopTicker();
        emit(TimerFinished(state.duration));
      } else {
        emit(TimerRunning(state.duration, endAt: endAt, remaining: remaining));
      }
    }
  }

  void pause() {
    refresh();
    if (state case TimerRunning(:final remaining)) {
      _stopTicker();
      emit(TimerPaused(state.duration, remaining: remaining));
    }
  }

  void reset() {
    _stopTicker();
    emit(TimerIdle(state.duration));
  }

  void _stopTicker() {
    unawaited(_ticker?.cancel());
    _ticker = null;
  }

  @override
  Future<void> close() async {
    await _ticker?.cancel();
    _ticker = null;
    return super.close();
  }
}
