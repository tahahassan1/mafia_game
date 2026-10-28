import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:mafia/app.dart';
import 'package:mafia/core/assets.dart';
import 'package:mafia/core/constants.dart';
import 'package:mafia/core/di.dart';
import 'package:mafia/core/strings_ar.dart';
import 'package:mafia/core/theme.dart';
import 'package:mafia/core/widgets/app_button.dart';
import 'package:mafia/core/widgets/app_lottie.dart';
import 'package:mafia/features/game/domain/assignment.dart';
import 'package:mafia/features/game/domain/game_session.dart';
import 'package:mafia/features/game/domain/player.dart';
import 'package:mafia/features/reveal/reveal_cubit.dart';
import 'package:mafia/features/reveal/ui/handoff_reveal_screen.dart';
import 'package:mafia/features/reveal/ui/widgets/handoff_prompt.dart';
import 'package:mafia/features/reveal/ui/widgets/reveal_role_card.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';
import 'package:mafia/features/timer/timer_cubit.dart';
import 'package:mafia/features/timer/ui/timer_screen.dart';

import '../support/platform_calls.dart';

void main() {
  setUp(() {
    getIt.registerFactory<TimerCubit>(
      () => TimerCubit(
        DateTime.now,
        initialDuration: TimerLimits.defaultDuration,
      ),
    );
    PlatformCalls().install();
  });
  tearDown(() => getIt.reset());
  testWidgets('each handoff is private and only its assignment is revealed', (
    tester,
  ) async {
    final assignments = [
      for (final (index, role) in RoleCatalog.all.indexed)
        Assignment(
          player: Player(name: 'لاعب $index'),
          role: role,
        ),
    ];
    final cubit = await _pumpFlow(tester, assignments);
    final semantics = tester.ensureSemantics();

    for (final (index, assignment) in assignments.indexed) {
      expect(cubit.state.currentIndex, index);
      expect(find.text(assignment.player.name), findsOneWidget);
      expect(find.byType(RevealRoleCard), findsNothing);
      _expectNoRoles();
      await tester.tap(find.text(AppStrings.revealRole));
      await tester.pump();
      final card = tester.widget<RevealRoleCard>(find.byType(RevealRoleCard));
      expect(card.name, assignment.role.nameAr);
      expect(card.description, assignment.role.descriptionAr);
      expect(find.text(assignment.role.descriptionAr), findsOneWidget);
      expect(find.byType(HandoffPrompt), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await _cancelExit(tester);
      expect(cubit.state.currentIndex, index);
      expect(find.text(assignment.role.descriptionAr), findsOneWidget);

      final staleHide = _button(tester, AppStrings.hideAndNext).onPressed!;
      await tester.tap(find.text(AppStrings.hideAndNext));
      staleHide();
      expect(cubit.state.isRevealed, isFalse);
      expect(cubit.state.currentIndex, index + 1);
      await tester.pump();
      // Include offstage widgets: old cards must be removed, not just obscured.
      _expectNoRoles();
      expect(find.byType(RevealRoleCard, skipOffstage: false), findsNothing);
      expect(
        find.bySemanticsLabel(assignment.role.descriptionAr),
        findsNothing,
      );
      if (index < assignments.length - 1) {
        await tester.binding.handlePopRoute();
        await tester.pump();
        await _cancelExit(tester);
        expect(cubit.state.currentIndex, index + 1);
        expect(find.text(assignments[index + 1].player.name), findsOneWidget);
      }
    }
    await tester.pumpAndSettle();
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(find.text(AppStrings.timerTitle), findsOneWidget);
    expect(find.byType(HandoffRevealScreen, skipOffstage: false), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _cancelExit(tester);
    expect(find.byType(TimerScreen), findsOneWidget);
    _expectNoRoles();
    expect(
      tester.widget<AppLottie>(find.byType(AppLottie)).asset,
      AppAssets.mafiaClockLottie,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('empty session safely replaces the flow with the timer', (
    tester,
  ) async {
    final cubit = await _pumpFlow(tester, []);
    expect(cubit.state.isFinished, isTrue);
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(find.byType(HandoffRevealScreen, skipOffstage: false), findsNothing);
    _expectNoRoles();
    expect(tester.takeException(), isNull);
  });

  testWidgets('an already finished cubit cannot reopen a reveal', (
    tester,
  ) async {
    final session = GameSession()
      ..start(const [
        Assignment(
          player: Player(name: 'أحمد'),
          role: RoleCatalog.doctor,
        ),
      ]);
    final cubit = RevealCubit(session)..reveal();
    cubit.hideAndNext();
    await _pumpFlow(tester, [], cubit: cubit);
    expect(find.byType(TimerScreen), findsOneWidget);
    _expectNoRoles();
  });

  testWidgets('animation and styling stay identical for every role and phase', (
    tester,
  ) async {
    await _pumpFlow(tester, [
      for (final role in RoleCatalog.all)
        Assignment(
          player: const Player(name: 'اللاعب'),
          role: role,
        ),
    ]);
    final animationRect = tester.getRect(find.byType(AppLottie));
    BoxDecoration? cardStyle;
    for (final role in RoleCatalog.all) {
      for (final revealed in [false, true]) {
        if (revealed) {
          await tester.tap(find.text(AppStrings.revealRole));
          await tester.pump();
        }
        final animation = tester.widget<AppLottie>(find.byType(AppLottie));
        expect(animation.asset, AppAssets.mafiaLoadingLottie);
        expect(animation.size, AppSizes.lottieDefault);
        expect(animation.controller, isNull);
        expect(animation.fit, BoxFit.contain);
        expect(tester.getRect(find.byType(AppLottie)), animationRect);
        expect(find.byType(AppLottie), findsOneWidget);
        final lottie = tester.widget<Lottie>(find.byType(Lottie));
        expect(lottie.animate, isFalse);
        expect(lottie.delegates, isNull);
        final context = tester.element(find.byType(AppLottie));
        expect(Directionality.of(context), TextDirection.rtl);
        expect(Theme.of(context).scaffoldBackgroundColor, AppColors.canvas);
        expect(find.byType(BackButton), findsNothing);
        final button = tester.widget<AppButton>(find.byType(AppButton));
        expect(button.secondary, revealed);
        if (revealed) {
          final container = tester.widget<Container>(
            find.descendant(
              of: find.byType(RevealRoleCard),
              matching: find.byType(Container),
            ),
          );
          final decoration = container.decoration! as BoxDecoration;
          cardStyle ??= decoration;
          expect(decoration, cardStyle);
          expect(decoration.color, AppColors.surface);
          expect(decoration.boxShadow, AppShadows.revealCard);
          expect(
            tester.widget<Text>(find.text(role.nameAr)).style,
            AppStyles.roleName,
          );
          expect(
            tester.widget<Text>(find.text(role.descriptionAr)).style,
            AppStyles.body,
          );
        } else {
          _expectNoRoles();
        }
      }
      await tester.tap(find.text(AppStrings.hideAndNext));
      await tester.pump();
      _expectNoRoles();
    }
  });

  testWidgets('running animation never delays hide or retains a role', (
    tester,
  ) async {
    final cubit = await _pumpFlow(tester, const [
      Assignment(
        player: Player(name: 'أحمد'),
        role: RoleCatalog.doctor,
      ),
      Assignment(
        player: Player(name: 'منى'),
        role: RoleCatalog.jester,
      ),
    ], reduceMotion: false);
    await tester.tap(find.text(AppStrings.revealRole));
    await tester.pump();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isTrue);
    await tester.tap(find.text(AppStrings.hideAndNext));
    await tester.pump();
    expect(cubit.state.currentIndex, 1);
    expect(find.text('منى'), findsOneWidget);
    _expectNoRoles();
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final inset in [0.0, 260.0]) {
        testWidgets(
          'RTL width $width text $scale inset $inset remains usable',
          (tester) async {
            const longName = 'عبد الرحمن محمد أحمد عبد الله الاسم الطويل جدًا';
            await _pumpFlow(
              tester,
              const [
                Assignment(
                  player: Player(name: longName),
                  role: RoleCatalog.gambler,
                ),
                Assignment(
                  player: Player(name: 'منى'),
                  role: RoleCatalog.mafia,
                ),
              ],
              width: width,
              scale: scale,
              inset: inset,
            );
            expect(find.text(longName), findsOneWidget);
            final name = tester.widget<Text>(find.text(longName));
            expect(name.maxLines, isNull);
            final context = tester.element(find.byType(HandoffPrompt));
            expect(Directionality.of(context), TextDirection.rtl);
            expect(MediaQuery.textScalerOf(context).scale(10), 10 * scale);
            await tester.ensureVisible(find.text(longName));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            _expectReachableAction(tester, AppStrings.revealRole, inset);
            await tester.tap(find.text(AppStrings.revealRole));
            await tester.pumpAndSettle();
            expect(_contentScrollOffset(tester), 0);
            await tester.ensureVisible(
              find.text(RoleCatalog.gambler.descriptionAr),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            _expectReachableAction(tester, AppStrings.hideAndNext, inset);
            await tester.tap(find.text(AppStrings.hideAndNext));
            await tester.pump();
            expect(find.text('منى'), findsOneWidget);
            expect(_contentScrollOffset(tester), 0);
            _expectNoRoles();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

Future<RevealCubit> _pumpFlow(
  WidgetTester tester,
  List<Assignment> assignments, {
  RevealCubit? cubit,
  double width = 360,
  double scale = 1,
  double inset = 0,
  bool reduceMotion = true,
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: inset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final flowCubit = cubit ?? RevealCubit(GameSession()..start(assignments));
  addTearDown(flowCubit.close);
  await tester.pumpWidget(
    MafiaApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: flowCubit,
                  child: const HandoffRevealScreen(),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  if (reduceMotion) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
  return flowCubit;
}

void _expectNoRoles() {
  for (final role in RoleCatalog.all) {
    expect(find.text(role.nameAr, skipOffstage: false), findsNothing);
    expect(find.text(role.descriptionAr, skipOffstage: false), findsNothing);
  }
}

AppButton _button(WidgetTester tester, String label) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, label));

void _expectReachableAction(WidgetTester tester, String label, double inset) {
  final finder = find.widgetWithText(AppButton, label);
  expect(finder.hitTestable(), findsOneWidget);
  expect(tester.getRect(finder).bottom, lessThanOrEqualTo(640 - inset));
}

double _contentScrollOffset(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).last).position.pixels;

Future<void> _cancelExit(WidgetTester tester) async {
  expect(find.text(AppStrings.exitRoundTitle), findsOneWidget);
  await tester.tap(find.text(AppStrings.keepRound));
  await tester.pumpAndSettle();
}
