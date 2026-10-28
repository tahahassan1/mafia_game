import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:mafia/app.dart';
import 'package:mafia/core/constants.dart';
import 'package:mafia/core/di.dart';
import 'package:mafia/core/strings_ar.dart';
import 'package:mafia/core/theme.dart';
import 'package:mafia/core/widgets/app_button.dart';
import 'package:mafia/core/widgets/app_lottie.dart';
import 'package:mafia/features/game/domain/assignment.dart';
import 'package:mafia/features/game/domain/game_session.dart';
import 'package:mafia/features/game/domain/player.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';
import 'package:mafia/features/timer/timer_cubit.dart';
import 'package:mafia/features/timer/timer_state.dart';
import 'package:mafia/features/timer/ui/host_roles_sheet.dart';
import 'package:mafia/features/timer/ui/timer_screen.dart';
import 'package:mafia/features/timer/ui/widgets/host_role_row.dart';
import 'package:mafia/features/timer/ui/widgets/host_roles_button.dart';
import 'package:mafia/features/timer/ui/widgets/timer_duration_controls.dart';
import 'package:mafia/features/timer/ui/widgets/timer_panel.dart';

import '../support/platform_calls.dart';

void main() {
  late DateTime now;
  late PlatformCalls calls;
  const assignments = [
    Assignment(
      player: Player(name: 'أحمد'),
      role: RoleCatalog.mafia,
    ),
    Assignment(
      player: Player(name: 'منى'),
      role: RoleCatalog.doctor,
    ),
    Assignment(
      player: Player(name: 'علي'),
      role: RoleCatalog.jester,
    ),
  ];

  setUp(() async {
    await getIt.reset();
    now = DateTime.utc(2026, 10, 28);
    calls = PlatformCalls()..install();
    getIt.registerSingleton<GameSession>(GameSession()..start(assignments));
  });
  tearDown(() => getIt.reset());

  TimerCubit buildCubit({Duration duration = TimerLimits.defaultDuration}) =>
      TimerCubit(() => now, initialDuration: duration);

  testWidgets('steppers, start, pause, resume, reset and Android Back', (
    tester,
  ) async {
    final cubit = buildCubit();
    await _pumpTimer(tester, cubit);
    expect(find.text('03:00'), findsOneWidget);
    expect(calls.wakeLock, [true]);
    expect(find.byType(BackButton), findsNothing);
    await tester.ensureVisible(find.byTooltip(AppStrings.increaseSeconds));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.increaseSeconds));
    await tester.pumpAndSettle();
    expect(find.text('03:01'), findsOneWidget);
    await tester.tap(find.text(AppStrings.startTimer));
    await tester.pump();
    expect(find.byType(TimerDurationControls), findsNothing);
    now = now.add(const Duration(seconds: 10));
    await tester.tap(find.text(AppStrings.pauseTimer));
    await tester.pump();
    expect(cubit.state.remaining, const Duration(seconds: 171));
    expect(find.text('02:51'), findsOneWidget);
    now = now.add(const Duration(hours: 2));
    await tester.tap(find.text(AppStrings.resumeTimer));
    await tester.pump();
    expect(
      (cubit.state as TimerRunning).endAt,
      now.add(const Duration(seconds: 171)),
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text(AppStrings.exitRoundTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.keepRound));
    await tester.pumpAndSettle();
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(cubit.state, isA<TimerRunning>());
    await tester.tap(find.text(AppStrings.resetTimer));
    await tester.pumpAndSettle();
    expect(find.text('03:01'), findsOneWidget);
    expect(find.byType(TimerDurationControls), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(calls.wakeLock, [true, false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expiry alerts once per run, uses red digits and restarts', (
    tester,
  ) async {
    final cubit = buildCubit(duration: const Duration(seconds: 1));
    await _pumpTimer(tester, cubit);
    await tester.tap(find.text(AppStrings.startTimer));
    await tester.pump();
    now = now.add(const Duration(seconds: 2));
    cubit.refresh();
    await tester.pump();
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text(AppStrings.timerFinished), findsOneWidget);
    final digits = tester.widget<Text>(find.text('00:00'));
    expect(digits.style!.color, AppColors.brandPrimary);
    expect(digits.textDirection, TextDirection.ltr);
    cubit.refresh();
    await tester.pump(const Duration(seconds: 1));
    expect(_vibrationCount(calls), 1);
    expect(calls.finishSound.map((call) => call.method), ['playFinishSound']);
    await tester.tap(find.text(AppStrings.restartTimer));
    await tester.pump();
    now = now.add(const Duration(seconds: 1));
    cubit.refresh();
    await tester.pump();
    expect(_vibrationCount(calls), 2);
    expect(calls.finishSound.map((call) => call.method), [
      'playFinishSound',
      'playFinishSound',
    ]);
    await tester.tap(find.text(AppStrings.resetTimer));
    await tester.pumpAndSettle();
    expect(find.text('00:01'), findsOneWidget);
    expect(find.text(AppStrings.timerFinished), findsNothing);
  });

  testWidgets('clock follows phases independently of timer duration', (
    tester,
  ) async {
    final cubit = buildCubit();
    await _pumpTimer(tester, cubit, reduceMotion: false);
    final clock =
        tester.widget<AppLottie>(find.byType(AppLottie)).controller!
            as AnimationController;
    expect(clock.duration, isNotNull);
    expect(clock.duration, isNot(cubit.state.duration));
    expect(clock.value, 0);
    expect(clock.isAnimating, isFalse);
    cubit.start();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(clock.isAnimating, isTrue);
    expect(clock.value, greaterThan(0));
    cubit.pause();
    await tester.pump();
    final pausedValue = clock.value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, pausedValue);
    expect(clock.isAnimating, isFalse);
    cubit.resume();
    await tester.pump();
    expect(clock.isAnimating, isTrue);
    now = now.add(const Duration(minutes: 4));
    cubit.refresh();
    await tester.pump();
    expect(clock.isAnimating, isFalse);
    expect(clock.value, 1);
    cubit.reset();
    await tester.pump();
    expect(clock.value, 0);
    expect(find.byType(AppLottie), findsOneWidget);
  });

  testWidgets('reduced motion keeps clock static in every phase', (
    tester,
  ) async {
    final cubit = buildCubit();
    await _pumpTimer(tester, cubit);
    final clock =
        tester.widget<AppLottie>(find.byType(AppLottie)).controller!
            as AnimationController;
    for (final action in [
      cubit.start,
      cubit.pause,
      cubit.resume,
      () {
        now = now.add(const Duration(minutes: 4));
        cubit.refresh();
      },
      cubit.reset,
    ]) {
      action();
      await tester.pump();
      expect(clock.isAnimating, isFalse);
      expect(clock.value, 0);
      expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
    }
  });

  testWidgets(
    'tap and a short hold reveal nothing; one-second hold opens roles',
    (tester) async {
      await _pumpTimer(tester, buildCubit());
      await tester.tap(find.byType(HostRolesButton));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(HostRolesSheet), findsNothing);
      _expectPrivate(assignments);
      final shortHold = await tester.startGesture(
        tester.getCenter(find.byType(HostRolesButton)),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(HostRolesSheet), findsNothing);
      await shortHold.up();
      await tester.pump();
      await _openSheet(tester);
      expect(find.byType(HostRoleRow), findsNWidgets(3));
      for (final assignment in assignments) {
        expect(find.text(assignment.player.name), findsOneWidget);
        expect(find.text(assignment.role.nameAr), findsOneWidget);
        expect(
          find.text(AppStrings.teamLabel(assignment.role.team)),
          findsOneWidget,
        );
      }
      final colors = [
        AppColors.teamMafia,
        AppColors.teamCivilian,
        AppColors.teamNeutral,
      ];
      for (final (index, element)
          in find.byType(HostRoleRow).evaluate().indexed) {
        final chip = tester.widget<Container>(
          find.descendant(
            of: find.byWidget(element.widget),
            matching: find.byType(Container),
          ),
        );
        final border = (chip.decoration! as BoxDecoration).border! as Border;
        expect(border.left.color, colors[index]);
      }
      expect(
        find.descendant(
          of: find.byType(HostRolesSheet),
          matching: find.byType(AppLottie),
        ),
        findsNothing,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      _expectPrivate(assignments);
    },
  );

  testWidgets(
    'sheet auto-closes after ten seconds while countdown keeps running',
    (tester) async {
      final cubit = buildCubit();
      await _pumpTimer(tester, cubit);
      cubit.start();
      await tester.pump();
      await _openSheet(tester);
      now = now.add(const Duration(seconds: 9));
      await tester.pump(const Duration(seconds: 8));
      expect(find.byType(HostRolesSheet), findsOneWidget);
      expect(cubit.state, isA<TimerRunning>());
      expect(cubit.state.remaining, const Duration(seconds: 171));
      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(HostRolesSheet), findsNothing);
      expect(cubit.state.remaining, const Duration(seconds: 169));
      _expectPrivate(assignments);
    },
  );

  for (final lifecycle in [
    AppLifecycleState.inactive,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
  ]) {
    testWidgets('sheet closes on $lifecycle and timer refreshes on resume', (
      tester,
    ) async {
      final cubit = buildCubit();
      await _pumpTimer(tester, cubit);
      cubit.start();
      await tester.pump();
      await _openSheet(tester);
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
      await tester.pumpAndSettle();
      if (lifecycle == AppLifecycleState.inactive) {
        _expectPrivate(assignments);
      }
      now = now.add(const Duration(minutes: 4));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      // Paused/hidden suspend frames. The first resumed frame must be private.
      _expectPrivate(assignments);
      await tester.pumpAndSettle();
      expect(find.byType(HostRolesSheet), findsNothing);
      expect(cubit.state, const TimerFinished(TimerLimits.defaultDuration));
      expect(calls.finishSound.map((call) => call.method), ['playFinishSound']);
    });
  }

  testWidgets('sheet countdown bar progresses and all names can be scrolled', (
    tester,
  ) async {
    getIt<GameSession>().start([
      for (var index = 0; index < 25; index++)
        Assignment(
          player: Player(name: 'عبد الرحمن محمد أحمد عبد الله $index'),
          role: RoleCatalog.citizen,
        ),
    ]);
    await _pumpTimer(
      tester,
      buildCubit(),
      reduceMotion: false,
      scale: 2,
      width: 320,
    );
    await _openSheet(tester, settle: false);
    final bar = find.byType(LinearProgressIndicator);
    final initial = tester.widget<LinearProgressIndicator>(bar).value!;
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(AppStrings.hostAutoClose))
          .getSemanticsData()
          .value,
      isEmpty,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<LinearProgressIndicator>(bar).value,
      lessThan(initial),
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(AppStrings.hostAutoClose))
          .getSemanticsData()
          .value,
      isEmpty,
    );
    await tester.scrollUntilVisible(
      find.text('عبد الرحمن محمد أحمد عبد الله 24'),
      300,
      scrollable: find.descendant(
        of: find.byType(HostRolesSheet),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      find.text('عبد الرحمن محمد أحمد عبد الله 24').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));
  });

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('timer RTL layout at width $width and text $scale', (
        tester,
      ) async {
        final cubit = buildCubit();
        await _pumpTimer(tester, cubit, width: width, scale: scale);
        expect(
          Directionality.of(tester.element(find.byType(TimerPanel))),
          TextDirection.rtl,
        );
        expect(
          tester.widget<Text>(find.text('03:00')).textDirection,
          TextDirection.ltr,
        );
        if (scale == 1) {
          expect(
            find.byTooltip(AppStrings.increaseSeconds).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byTooltip(AppStrings.increaseMinutes).hitTestable(),
            findsOneWidget,
          );
        }
        await tester.ensureVisible(find.byTooltip(AppStrings.increaseSeconds));
        await tester.pumpAndSettle();
        expect(
          find.byTooltip(AppStrings.increaseSeconds).hitTestable(),
          findsOneWidget,
          reason:
              'seconds ${tester.getRect(find.byTooltip(AppStrings.increaseSeconds))}; viewport ${tester.getRect(find.byType(SingleChildScrollView))}',
        );
        final start = find.widgetWithText(AppButton, AppStrings.startTimer);
        await tester.ensureVisible(start);
        await tester.tap(start);
        await tester.pump();
        expect(find.text(AppStrings.pauseTimer).hitTestable(), findsOneWidget);
        _expectPrivate(assignments);
        await _openSheet(tester);
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        cubit.reset();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _pumpTimer(
  WidgetTester tester,
  TimerCubit cubit, {
  double width = 360,
  double scale = 1,
  bool reduceMotion = true,
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    MafiaApp(
      home: BlocProvider(create: (_) => cubit, child: const TimerScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester, {bool settle = true}) async {
  final button = find.byType(HostRolesButton);
  await tester.ensureVisible(button);
  final gesture = await tester.startGesture(tester.getCenter(button));
  await tester.pump(TimerLimits.hostLongPress);
  await gesture.up();
  await tester.pump();
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(find.byType(HostRolesSheet), findsOneWidget);
}

void _expectPrivate(List<Assignment> assignments) {
  expect(find.byType(HostRoleRow), findsNothing);
  for (final assignment in assignments) {
    expect(find.text(assignment.player.name), findsNothing);
    expect(find.text(assignment.role.nameAr), findsNothing);
  }
}

int _vibrationCount(PlatformCalls calls) => calls.system
    .where(
      (call) =>
          call.method == 'HapticFeedback.vibrate' && call.arguments == null,
    )
    .length;
