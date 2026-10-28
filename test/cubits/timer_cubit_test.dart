import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/core/constants.dart';
import 'package:mafia/features/timer/timer_cubit.dart';
import 'package:mafia/features/timer/timer_state.dart';

void main() {
  late DateTime now;
  const duration = Duration(minutes: 3);
  TimerCubit buildCubit() => TimerCubit(() => now, initialDuration: duration);
  setUp(() => now = DateTime.utc(2026, 10, 28));

  test(
    'initial state uses the configured duration and ceiling seconds',
    () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      expect(cubit.state, const TimerIdle(duration));
      expect(TimerLimits.defaultDuration, duration);
      cubit.start();
      expect((cubit.state as TimerRunning).endAt, now.add(duration));
      now = now.add(const Duration(milliseconds: 1));
      cubit.refresh();
      expect(cubit.state.displaySeconds, 180);
      now = now.add(const Duration(milliseconds: 999));
      cubit.refresh();
      expect(cubit.state.displaySeconds, 179);
    },
  );

  blocTest<TimerCubit, TimerState>(
    'pause recomputes from endAt; resume excludes a long paused gap',
    build: buildCubit,
    act: (cubit) {
      cubit.start();
      cubit.start();
      now = now.add(const Duration(seconds: 7, milliseconds: 125));
      cubit.pause();
      now = now.add(const Duration(hours: 5));
      cubit.refresh();
      cubit.resume();
      cubit.resume();
      now = now.add(const Duration(seconds: 2));
      cubit.refresh();
    },
    expect: () => [
      isA<TimerRunning>().having((s) => s.remaining, 'initial', duration),
      isA<TimerRunning>().having(
        (s) => s.remaining,
        'exact pause time',
        const Duration(seconds: 172, milliseconds: 875),
      ),
      const TimerPaused(
        duration,
        remaining: Duration(seconds: 172, milliseconds: 875),
      ),
      isA<TimerRunning>()
          .having(
            (s) => s.remaining,
            'resumed',
            const Duration(seconds: 172, milliseconds: 875),
          )
          .having(
            (s) => s.endAt,
            'new deadline',
            DateTime.utc(2026, 10, 28, 5, 3),
          ),
      isA<TimerRunning>().having(
        (s) => s.remaining,
        'after resume',
        const Duration(seconds: 170, milliseconds: 875),
      ),
    ],
  );

  blocTest<TimerCubit, TimerState>(
    'a gap past the deadline finishes once; restart is a new run',
    build: buildCubit,
    act: (cubit) {
      cubit.start();
      now = now.add(const Duration(days: 1));
      cubit.refresh();
      cubit.refresh();
      cubit.pause();
      cubit.resume();
      cubit.start();
      now = now.add(duration);
      cubit.pause();
    },
    expect: () => [
      isA<TimerRunning>(),
      const TimerFinished(duration),
      isA<TimerRunning>(),
      const TimerFinished(duration),
    ],
  );

  test('reset restores configured duration from every phase', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    cubit.setDuration(const Duration(seconds: 12));
    for (final pause in [true, false]) {
      cubit.start();
      now = now.add(const Duration(seconds: 3));
      if (pause) cubit.pause();
      cubit.reset();
      expect(cubit.state, const TimerIdle(Duration(seconds: 12)));
    }
    cubit.start();
    now = now.add(const Duration(seconds: 12));
    cubit.refresh();
    cubit.reset();
    expect(cubit.state, const TimerIdle(Duration(seconds: 12)));
  });

  test('duration limits and independent stepper bounds', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    for (final invalid in [
      Duration.zero,
      const Duration(seconds: -1),
      const Duration(minutes: 100),
      const Duration(milliseconds: 1500),
    ]) {
      cubit.setDuration(invalid);
      expect(cubit.state, const TimerIdle(duration));
      expect(
        () => TimerCubit(() => now, initialDuration: invalid),
        throwsArgumentError,
      );
    }
    cubit.setDuration(TimerLimits.minDuration);
    cubit.decreaseSeconds();
    cubit.decreaseMinutes();
    expect(cubit.state.duration, TimerLimits.minDuration);
    expect(cubit.state.canDecreaseSeconds, isFalse);
    expect(cubit.state.canDecreaseMinutes, isFalse);
    cubit.increaseMinutes();
    cubit.decreaseSeconds();
    expect(cubit.state.duration, const Duration(minutes: 1));
    expect(cubit.state.canDecreaseMinutes, isFalse);
    cubit.setDuration(TimerLimits.maxDuration);
    cubit.increaseMinutes();
    cubit.increaseSeconds();
    expect(cubit.state.duration, TimerLimits.maxDuration);
    expect(cubit.state.canIncreaseMinutes, isFalse);
    expect(cubit.state.canIncreaseSeconds, isFalse);
    cubit.start();
    cubit.setDuration(duration);
    cubit.decreaseSeconds();
    expect(cubit.state.duration, TimerLimits.maxDuration);
    cubit.pause();
    cubit.setDuration(duration);
    expect(cubit.state.duration, TimerLimits.maxDuration);
  });

  testWidgets('periodic refresh uses the clock; close cancels the ticker', (
    tester,
  ) async {
    final cubit = buildCubit();
    cubit.start();
    now = now.add(const Duration(seconds: 20));
    await tester.pump(TimerLimits.refreshInterval);
    expect(cubit.state.remaining, const Duration(seconds: 160));
    await tester.runAsync(cubit.close);
    now = now.add(const Duration(hours: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(cubit.state.remaining, const Duration(seconds: 160));
    cubit.refresh();
    expect(tester.takeException(), isNull);
  });

  test('state equality accounts for all relevant fields', () {
    final end = now.add(duration);
    expect(
      TimerRunning(duration, endAt: end, remaining: duration),
      TimerRunning(duration, endAt: end, remaining: duration),
    );
    expect(
      TimerRunning(duration, endAt: end, remaining: duration),
      isNot(
        TimerRunning(
          duration,
          endAt: end.add(const Duration(seconds: 1)),
          remaining: duration,
        ),
      ),
    );
    expect(
      const TimerPaused(duration, remaining: Duration(seconds: 4)),
      isNot(const TimerPaused(duration, remaining: Duration(seconds: 5))),
    );
    expect(const TimerIdle(duration), isNot(const TimerFinished(duration)));
    expect(const TimerFinished(duration).displaySeconds, 0);
  });
}
