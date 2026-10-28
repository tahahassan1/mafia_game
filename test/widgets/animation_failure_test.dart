import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:mafia/app.dart';
import 'package:mafia/core/assets.dart';
import 'package:mafia/core/constants.dart';
import 'package:mafia/core/di.dart';
import 'package:mafia/core/strings_ar.dart';
import 'package:mafia/core/widgets/app_lottie.dart';
import 'package:mafia/features/game/domain/assignment.dart';
import 'package:mafia/features/game/domain/game_session.dart';
import 'package:mafia/features/game/domain/player.dart';
import 'package:mafia/features/reveal/reveal_cubit.dart';
import 'package:mafia/features/reveal/ui/handoff_reveal_screen.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';
import 'package:mafia/features/setup/setup_cubit.dart';
import 'package:mafia/features/setup/ui/players_screen.dart';
import 'package:mafia/features/timer/timer_cubit.dart';
import 'package:mafia/features/timer/timer_state.dart';
import 'package:mafia/features/timer/ui/timer_screen.dart';

import '../support/memory_players_store.dart';
import '../support/platform_calls.dart';

void main() {
  setUp(() {
    Lottie.cache.clear();
    PlatformCalls().install();
  });
  tearDown(() async {
    Lottie.cache.clear();
    await getIt.reset();
  });

  testWidgets(
    'Players empty animation is bounded and static in reduced motion',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final cubit = SetupCubit(MemoryPlayersStore(), GameSession(), Random(1));
      await pumpScreen(
        tester,
        rootBundle,
        BlocProvider(create: (_) => cubit, child: const PlayersScreen()),
      );
      expect(find.byType(AppLottie), findsOneWidget);
      final animation = tester.widget<AppLottie>(find.byType(AppLottie));
      expect(animation.asset, AppAssets.mafiaLoadingLottie);
      expect(
        tester.getSize(find.byType(AppLottie)),
        Size.square(animation.size),
      );
      final lottie = tester.widget<Lottie>(find.byType(Lottie));
      expect(lottie.animate, isFalse);
      expect(lottie.controller, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'أحمد');
      await tester.tap(find.byTooltip(AppStrings.addPlayer));
      await tester.pumpAndSettle();
      expect(find.byType(AppLottie), findsNothing);
    },
  );

  for (final corrupt in [false, true]) {
    final failure = corrupt ? 'malformed JSON' : 'missing asset';

    testWidgets('Players remains usable with $failure', (tester) async {
      final bundle = FailingAnimationBundle(corrupt: corrupt);
      final cubit = SetupCubit(MemoryPlayersStore(), GameSession(), Random(1));
      await pumpScreen(
        tester,
        bundle,
        BlocProvider(create: (_) => cubit, child: const PlayersScreen()),
      );
      expectFailedAnimation(tester, bundle, AppAssets.mafiaLoadingLottie);
      expect(find.text(AppStrings.emptyPlayers), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'أحمد');
      await tester.tap(find.byTooltip(AppStrings.addPlayer));
      await tester.pumpAndSettle();
      expect(cubit.state.players, ['أحمد']);
      expect(find.byType(AppLottie), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Handoff and Reveal remain private with $failure', (
      tester,
    ) async {
      final bundle = FailingAnimationBundle(corrupt: corrupt);
      final session = GameSession()
        ..start(const [
          Assignment(
            player: Player(name: 'أحمد'),
            role: RoleCatalog.mafia,
          ),
          Assignment(
            player: Player(name: 'منى'),
            role: RoleCatalog.doctor,
          ),
        ]);
      final cubit = RevealCubit(session);
      await pumpScreen(
        tester,
        bundle,
        BlocProvider(create: (_) => cubit, child: const HandoffRevealScreen()),
      );
      expectFailedAnimation(tester, bundle, AppAssets.mafiaLoadingLottie);
      expect(find.text('أحمد'), findsOneWidget);
      expect(find.text(RoleCatalog.mafia.descriptionAr), findsNothing);
      await tester.tap(find.text(AppStrings.revealRole));
      await tester.pumpAndSettle();
      expect(find.text(RoleCatalog.mafia.descriptionAr), findsOneWidget);
      expectFailedAnimation(tester, bundle, AppAssets.mafiaLoadingLottie);
      await tester.tap(find.text(AppStrings.hideAndNext));
      await tester.pump();
      expect(cubit.state.currentIndex, 1);
      expect(find.text('منى'), findsOneWidget);
      expect(
        find.text(RoleCatalog.mafia.descriptionAr, skipOffstage: false),
        findsNothing,
      );
      expect(find.text(RoleCatalog.doctor.descriptionAr), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Timer controls and finish work with $failure', (tester) async {
      final bundle = FailingAnimationBundle(corrupt: corrupt);
      var now = DateTime.utc(2026, 10, 28);
      final cubit = TimerCubit(
        () => now,
        initialDuration: TimerLimits.defaultDuration,
      );
      await pumpScreen(
        tester,
        bundle,
        BlocProvider(create: (_) => cubit, child: const TimerScreen()),
      );
      expectFailedAnimation(tester, bundle, AppAssets.mafiaClockLottie);
      await tester.tap(find.text(AppStrings.startTimer));
      await tester.pump();
      expect(cubit.state, isA<TimerRunning>());
      await tester.tap(find.text(AppStrings.pauseTimer));
      await tester.pumpAndSettle();
      expect(cubit.state, isA<TimerPaused>());
      await tester.tap(find.text(AppStrings.resumeTimer));
      await tester.pump();
      now = now.add(const Duration(minutes: 4));
      cubit.refresh();
      await tester.pumpAndSettle();
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text(AppStrings.timerFinished), findsOneWidget);
      expectFailedAnimation(tester, bundle, AppAssets.mafiaClockLottie);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> pumpScreen(
  WidgetTester tester,
  AssetBundle bundle,
  Widget screen,
) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: bundle,
      child: MafiaApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void expectFailedAnimation(
  WidgetTester tester,
  FailingAnimationBundle bundle,
  String asset,
) {
  expect(bundle.attempted, contains(asset));
  expect(find.byType(AppLottie), findsOneWidget);
  expect(find.byType(Lottie), findsNothing);
  final animation = tester.widget<AppLottie>(find.byType(AppLottie));
  expect(animation.asset, asset);
  expect(tester.getSize(find.byType(AppLottie)), Size.square(animation.size));
  expect(tester.takeException(), isNull);
}

class FailingAnimationBundle extends CachingAssetBundle {
  FailingAnimationBundle({required this.corrupt});

  final bool corrupt;
  final Set<String> attempted = {};

  @override
  Future<ByteData> load(String key) {
    if (key == AppAssets.mafiaLoadingLottie ||
        key == AppAssets.mafiaClockLottie) {
      attempted.add(key);
      if (corrupt) {
        return Future.value(
          ByteData.sublistView(Uint8List.fromList(utf8.encode('{broken'))),
        );
      }
      throw FlutterError('Missing test animation: $key');
    }
    return rootBundle.load(key);
  }
}
