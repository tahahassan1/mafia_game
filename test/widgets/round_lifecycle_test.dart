import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/app.dart';
import 'package:mafia/core/di.dart';
import 'package:mafia/core/strings_ar.dart';
import 'package:mafia/core/widgets/app_button.dart';
import 'package:mafia/core/widgets/round_exit_dialog.dart';
import 'package:mafia/features/game/data/players_store.dart';
import 'package:mafia/features/game/domain/game_session.dart';
import 'package:mafia/features/reveal/reveal_cubit.dart';
import 'package:mafia/features/reveal/ui/handoff_reveal_screen.dart';
import 'package:mafia/features/reveal/ui/widgets/reveal_role_card.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';
import 'package:mafia/features/roles/domain/team.dart';
import 'package:mafia/features/setup/setup_cubit.dart';
import 'package:mafia/features/setup/ui/game_setup_screen.dart';
import 'package:mafia/features/setup/ui/players_screen.dart';
import 'package:mafia/features/timer/timer_cubit.dart';
import 'package:mafia/features/timer/timer_state.dart';
import 'package:mafia/features/timer/ui/timer_screen.dart';
import 'package:mafia/features/timer/ui/widgets/host_roles_button.dart';
import 'package:mafia/features/timer/ui/widgets/timer_panel.dart';

import '../support/controlled_players_store.dart';
import '../support/memory_players_store.dart';
import '../support/platform_calls.dart';
import '../support/test_preferences.dart';

void main() {
  const names = [
    'عبد الرحمن محمد أحمد عبد الله الاسم الطويل',
    'منى',
    'علي',
    'حسن',
    'سارة',
  ];
  late DateTime now;
  late PlatformCalls calls;

  setUp(() async {
    await getIt.reset();
    now = DateTime.utc(2026, 10, 28);
    calls = PlatformCalls()..install();
  });
  tearDown(() => getIt.reset());

  Future<void> configure(PlayersStore store) async {
    configureDependencies();
    await getIt.unregister<PlayersStore>();
    getIt.registerSingleton<PlayersStore>(store);
    await getIt.unregister<DateTime Function()>();
    getIt.registerSingleton<DateTime Function()>(() => now);
    await getIt.unregister<Random>();
    getIt.registerSingleton<Random>(Random(42));
  }

  testWidgets(
    'two complete rounds, safe cancellation, and disposal after confirmed Timer exit',
    (tester) async {
      final store = MemoryPlayersStore();
      await store.saveNames(names);
      await configure(store);
      await _pumpApp(tester);
      final session = getIt<GameSession>();
      await _deal(tester);
      final firstReveal = tester
          .element(find.byType(HandoffRevealScreen))
          .read<RevealCubit>();
      await _revealAll(tester, session);
      expect(firstReveal.isClosed, isTrue);
      final firstTimer = tester
          .element(find.byType(TimerScreen))
          .read<TimerCubit>();
      await tester.tap(find.text(AppStrings.startTimer));
      await tester.pump();
      final assignments = session.assignments;
      await _askToExit(tester);
      now = now.add(const Duration(seconds: 4));
      firstTimer.refresh();
      await tester.pump();
      expect(firstTimer.state.remaining, const Duration(seconds: 176));
      await tester.tap(find.text(AppStrings.keepRound));
      await tester.pumpAndSettle();
      expect(session.assignments, same(assignments));
      expect(find.byType(TimerScreen), findsOneWidget);
      await _askToExit(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RoundExitDialog), findsNothing);
      expect(session.assignments, same(assignments));
      await _askToExit(tester);
      await _confirmExit(tester);
      expect(firstTimer.isClosed, isTrue);
      expect(calls.wakeLock.last, isFalse);
      expect(session.assignments, isEmpty);
      expect(find.byType(PlayersScreen), findsOneWidget);
      expect(
        tester
            .element(find.byType(PlayersScreen))
            .read<SetupCubit>()
            .state
            .players,
        names,
      );
      _expectNoPrivateRoles();

      await _deal(tester, increaseMafia: true);
      expect(
        session.assignments.where((a) => a.role.team == Team.mafia),
        hasLength(2),
      );
      expect(
        tester
            .element(find.byType(HandoffRevealScreen))
            .read<RevealCubit>()
            .state
            .currentIndex,
        0,
      );
      await _revealAll(tester, session);
      final secondTimer = tester
          .element(find.byType(TimerScreen))
          .read<TimerCubit>();
      expect(secondTimer, isNot(same(firstTimer)));
      expect(secondTimer.state, const TimerIdle(Duration(minutes: 3)));
      await tester.tap(find.text(AppStrings.startTimer));
      await tester.pump();
      await _askToExit(tester);
      await _confirmExit(tester);
      expect(secondTimer.isClosed, isTrue);
      expect(session.assignments, isEmpty);
      expect(await store.loadNames(), names);
      now = now.add(const Duration(days: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(calls.finishSound, isEmpty);
      expect(find.byType(PlayersScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final revealed in [false, true]) {
    testWidgets(
      'confirmed exit from ${revealed ? 'Reveal' : 'Handoff'} clears the round without leaking role text',
      (tester) async {
        final store = MemoryPlayersStore();
        await store.saveNames(names);
        await configure(store);
        await _pumpApp(tester);
        await _deal(tester);
        final session = getIt<GameSession>();
        final assignments = session.assignments;
        final cubit = tester
            .element(find.byType(HandoffRevealScreen))
            .read<RevealCubit>();
        if (revealed) {
          await tester.tap(find.text(AppStrings.revealRole));
          await tester.pump();
        }
        await _askToExit(tester);
        await tester.tap(find.text(AppStrings.keepRound));
        await tester.pumpAndSettle();
        expect(session.assignments, same(assignments));
        expect(cubit.state.currentIndex, 0);
        expect(cubit.state.isRevealed, revealed);
        await _askToExit(tester);
        await tester.tapAt(const Offset(4, 4));
        await tester.pump();
        expect(find.byType(RoundExitDialog), findsOneWidget);
        await _confirmExit(tester);
        expect(cubit.isClosed, isTrue);
        expect(session.assignments, isEmpty);
        expect(find.byType(TimerScreen), findsNothing);
        expect(find.byType(PlayersScreen), findsOneWidget);
        _expectNoPrivateRoles();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'repeated or stale dialog actions cannot pop past the round or skip clearing it',
    (tester) async {
      final store = MemoryPlayersStore();
      await store.saveNames(names);
      await configure(store);
      await _pumpApp(tester);
      await _deal(tester);
      await _askToExit(tester);
      final stale = tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, AppStrings.exitRound),
          )
          .onPressed!;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      stale();
      expect(getIt<GameSession>().assignments, hasLength(names.length));
      expect(find.byType(HandoffRevealScreen), findsOneWidget);
      await _askToExit(tester);
      final confirm = tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, AppStrings.exitRound),
          )
          .onPressed!;
      confirm();
      confirm();
      await tester.pumpAndSettle();
      expect(getIt<GameSession>().assignments, isEmpty);
      expect(find.byType(PlayersScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new app/session restores names through a new store without restoring assignments',
    (tester) async {
      final preferences = TestPreferences();
      final store = PlayersStore(preferences: preferences);
      await store.saveNames(names);
      await configure(store);
      await _pumpApp(tester);
      await _deal(tester);
      expect(getIt<GameSession>().assignments, hasLength(names.length));
      await tester.tap(find.text(AppStrings.revealRole));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await getIt.reset();
      await configure(PlayersStore(preferences: preferences));
      await tester.pumpWidget(const MafiaApp());
      await tester.pumpAndSettle();
      expect(find.byType(PlayersScreen), findsOneWidget);
      expect(
        tester
            .element(find.byType(PlayersScreen))
            .read<SetupCubit>()
            .state
            .players,
        names,
      );
      expect(getIt<GameSession>().assignments, isEmpty);
      expect(preferences.values, {PlayersStore.namesKey: names});
      _expectNoPrivateRoles();
    },
  );

  testWidgets(
    'confirmed exit does not reopen the previously focused name keyboard',
    (tester) async {
      final store = MemoryPlayersStore();
      await store.saveNames(names);
      await configure(store);
      await _pumpApp(tester);
      await tester.showKeyboard(find.byType(TextField));
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
      await _deal(tester);
      await _askToExit(tester);
      await _confirmExit(tester);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.focusNode!.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );

  testWidgets(
    'failed save shows a non-blocking SnackBar and next edit retries all names',
    (tester) async {
      final store = ControlledPlayersStore();
      await store.saveNames(names);
      await configure(store);
      await _pumpApp(tester);
      store.failWrites = true;
      await tester.enterText(find.byType(TextField), 'يوسف');
      await tester.tap(find.byTooltip(AppStrings.addPlayer));
      await tester.pumpAndSettle();
      expect(find.text('يوسف'), findsOneWidget);
      expect(find.text(AppStrings.namesSaveFailed), findsOneWidget);
      final warning = tester.widget<SnackBar>(find.byType(SnackBar));
      final text = tester.widget<Text>(find.text(AppStrings.namesSaveFailed));
      final backgroundLuminance = warning.backgroundColor!.computeLuminance();
      final textLuminance = text.style!.color!.computeLuminance();
      final contrast =
          (max(backgroundLuminance, textLuminance) + 0.05) /
          (min(backgroundLuminance, textLuminance) + 0.05);
      expect(contrast, greaterThanOrEqualTo(4.5));
      final cubit = tester
          .element(find.byType(PlayersScreen))
          .read<SetupCubit>();
      expect(cubit.state.canAdvance, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();
      expect(find.byType(GameSetupScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      store.failWrites = false;
      ScaffoldMessenger.of(tester.element(find.byType(PlayersScreen)))
          .hideCurrentSnackBar();
      await tester.enterText(find.byType(TextField), 'عمر');
      await tester.tap(find.byTooltip(AppStrings.addPlayer));
      await tester.pumpAndSettle();
      expect(cubit.state.namesSaveFailed, isFalse);
      expect(await store.loadNames(), [...names, 'يوسف', 'عمر']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a load failure is visible and a late save does not refocus a hidden name field',
    (tester) async {
      final store = ControlledPlayersStore()..failReads = true;
      await configure(store);
      await _pumpApp(tester);
      expect(find.text(AppStrings.namesLoadFailed), findsOneWidget);
      store.failReads = false;
      final cubit = tester
          .element(find.byType(PlayersScreen))
          .read<SetupCubit>();
      for (final name in names) {
        await cubit.submitPlayer(name);
      }
      await tester.pumpAndSettle();
      store.deferWrites = true;
      await tester.enterText(find.byType(TextField), 'يوسف');
      await tester.tap(find.byTooltip(AppStrings.addPlayer));
      await tester.pump();
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();
      store.pending.single.completeError(StateError('late'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byType(TextField, skipOffstage: false),
      );
      expect(field.focusNode!.hasFocus, isFalse);
      expect(find.byType(GameSetupScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Back from the host sheet dismisses only the sheet', (
    tester,
  ) async {
    final store = MemoryPlayersStore();
    await store.saveNames(names);
    await configure(store);
    await _pumpApp(tester);
    await _deal(tester);
    await _revealAll(tester, getIt<GameSession>());
    await tester.tap(find.text(AppStrings.startTimer));
    await tester.pump();
    final button = find.byType(HostRolesButton);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(RoundExitDialog), findsNothing);
    expect(getIt<GameSession>().assignments, hasLength(names.length));
    expect(
      tester.element(find.byType(TimerScreen)).read<TimerCubit>().state,
      isA<TimerRunning>(),
    );
    await _askToExit(tester);
    await _confirmExit(tester);
  });

  testWidgets(
    'save warning leaves Next reachable at 320 width, 2x text and open keyboard',
    (tester) async {
      final store = ControlledPlayersStore();
      await store.saveNames(names);
      await configure(store);
      await _pumpApp(tester, width: 320, scale: 2);
      store.failWrites = true;
      await tester.enterText(find.byType(TextField), 'يوسف');
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.addPlayer));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.namesSaveFailed), findsOneWidget);
      final next = find.widgetWithText(AppButton, AppStrings.next);
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      expect(next.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 360.0]) {
    testWidgets('exit dialog RTL and actions fit width $width at 2x text', (
      tester,
    ) async {
      final store = MemoryPlayersStore();
      await store.saveNames(names);
      await configure(store);
      await _pumpApp(tester, width: width, scale: 2);
      await _deal(tester);
      await tester.tap(find.text(AppStrings.revealRole));
      await tester.pumpAndSettle();
      await _askToExit(tester);
      expect(
        Directionality.of(tester.element(find.byType(RoundExitDialog))),
        TextDirection.rtl,
      );
      expect(find.text(AppStrings.keepRound).hitTestable(), findsOneWidget);
      expect(find.text(AppStrings.exitRound).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _confirmExit(tester);
      _expectNoPrivateRoles();
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  double width = 360,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(const MafiaApp());
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'startup layout');
}

Future<void> _deal(WidgetTester tester, {bool increaseMafia = false}) async {
  await tester.ensureVisible(find.widgetWithText(AppButton, AppStrings.next));
  await tester.tap(find.text(AppStrings.next));
  await tester.pumpAndSettle();
  if (increaseMafia) {
    await tester.ensureVisible(find.byTooltip(AppStrings.increaseMafia));
    await tester.tap(find.byTooltip(AppStrings.increaseMafia));
    await tester.pumpAndSettle();
  }
  final deal = find.widgetWithText(AppButton, AppStrings.dealRoles);
  await tester.ensureVisible(deal);
  await tester.tap(deal);
  await tester.pumpAndSettle();
  expect(find.byType(HandoffRevealScreen), findsOneWidget);
}

Future<void> _revealAll(WidgetTester tester, GameSession session) async {
  for (final assignment in session.assignments) {
    expect(find.text(assignment.player.name), findsOneWidget);
    await tester.tap(find.text(AppStrings.revealRole));
    await tester.pump();
    expect(find.text(assignment.role.descriptionAr), findsOneWidget);
    await tester.tap(find.text(AppStrings.hideAndNext));
    await tester.pump();
    expect(find.byType(RevealRoleCard, skipOffstage: false), findsNothing);
  }
  await tester.pumpAndSettle();
  expect(find.byType(TimerScreen), findsOneWidget);
}

Future<void> _askToExit(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(find.byType(RoundExitDialog), findsOneWidget);
}

Future<void> _confirmExit(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.exitRound));
  await tester.pump();
  expect(find.byType(RevealRoleCard, skipOffstage: false), findsNothing);
  expect(find.byType(TimerPanel), findsNothing);
  await tester.pumpAndSettle();
}

void _expectNoPrivateRoles() {
  for (final role in RoleCatalog.all) {
    expect(find.text(role.nameAr, skipOffstage: false), findsNothing);
    expect(find.text(role.descriptionAr, skipOffstage: false), findsNothing);
  }
}
