import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/app.dart';
import 'package:mafia/core/strings_ar.dart';
import 'package:mafia/core/widgets/app_button.dart';
import 'package:mafia/core/widgets/app_lottie.dart';
import 'package:mafia/core/widgets/role_toggle_card.dart';
import 'package:mafia/features/game/data/players_store.dart';
import 'package:mafia/features/game/domain/game_session.dart';
import 'package:mafia/features/game/domain/validation_reason.dart';
import 'package:mafia/features/placeholder/placeholder_screen.dart';
import 'package:mafia/features/roles/domain/role_catalog.dart';
import 'package:mafia/features/setup/setup_cubit.dart';
import 'package:mafia/features/setup/ui/game_setup_screen.dart';
import 'package:mafia/features/setup/ui/players_screen.dart';

void main() {
  testWidgets(
    'empty animation hides after adding; bad names show inline errors',
    (tester) async {
      final cubit = SetupCubit(PlayersStore(), GameSession(), Random(1));
      addTearDown(cubit.close);
      await _pumpPlayers(tester, cubit);
      expect(find.byType(AppLottie), findsOneWidget);
      expect(_button(tester, AppStrings.next).onPressed, isNull);
      await tester.tap(find.byTooltip(AppStrings.addPlayer));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.nameError(ValidationReason.emptyPlayerName)!),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'أحمد');
      await tester.tap(find.byTooltip(AppStrings.addPlayer));
      await tester.pumpAndSettle();
      expect(find.byType(AppLottie), findsNothing);
      expect(cubit.state.players, ['أحمد']);
      await tester.enterText(find.byType(TextField), ' أحمد ');
      await tester.tap(find.byTooltip(AppStrings.addPlayer));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.nameError(ValidationReason.duplicatePlayerName)!),
        findsOneWidget,
      );
      expect(cubit.state.players, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'edit, delete, configure, validate, and deal to a neutral placeholder',
    (tester) async {
      final store = PlayersStore();
      final session = GameSession();
      await store.saveNames(['أحمد', 'محمد', 'علي', 'حسن']);
      final cubit = SetupCubit(store, session, Random(1));
      addTearDown(cubit.close);
      await cubit.loadPlayers();
      await _pumpPlayers(tester, cubit);
      await tester.tap(find.text('أحمد'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'سمير');
      await tester.tap(find.byTooltip(AppStrings.saveName));
      await tester.pumpAndSettle();
      expect(cubit.state.players.first, 'سمير');
      await tester.tap(find.byTooltip(AppStrings.deletePlayer).first);
      await tester.pumpAndSettle();
      expect(_button(tester, AppStrings.next).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'خالد');
      await tester.tap(find.byTooltip(AppStrings.addPlayer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.next));
      await tester.tap(find.text(AppStrings.next), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(GameSetupScreen), findsOneWidget);
      expect(find.byType(AppLottie), findsNothing);

      await _toggleRole(tester, RoleCatalog.guard.nameAr);
      await _toggleRole(tester, RoleCatalog.jester.nameAr);
      expect(_button(tester, AppStrings.dealRoles).onPressed, isNull);
      expect(
        find.text(
          AppStrings.validationMessage(
            ValidationReason.tooManySpecialRoles,
            excessRoles: 1,
          ),
        ),
        findsOneWidget,
      );
      await _toggleRole(tester, RoleCatalog.jester.nameAr);
      await tester.tap(find.text(AppStrings.dealRoles));
      await tester.tap(find.text(AppStrings.dealRoles), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(PlaceholderScreen), findsOneWidget);
      expect(find.text(AppStrings.dealtPlaceholder), findsOneWidget);
      expect(session.assignments, hasLength(4));
      for (final assignment in session.assignments) {
        expect(find.text(assignment.player.name), findsNothing);
      }
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(PlayersScreen), findsOneWidget);
      expect(cubit.state.players, ['محمد', 'علي', 'حسن', 'خالد']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('removing an earlier row preserves an unfinished edit', (
    tester,
  ) async {
    final store = PlayersStore();
    await store.saveNames(['أحمد', 'محمد', 'علي', 'حسن']);
    final cubit = SetupCubit(store, GameSession(), Random(1));
    addTearDown(cubit.close);
    await cubit.loadPlayers();
    await _pumpPlayers(tester, cubit);
    await tester.tap(find.text('علي'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'يوسف');
    await cubit.removePlayer(0);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'يوسف',
    );
    await tester.tap(find.byTooltip(AppStrings.saveName));
    await tester.pumpAndSettle();
    expect(cubit.state.players, ['محمد', 'يوسف', 'حسن']);
  });

  for (final width in [320.0, 360.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final keyboard in [0.0, 260.0]) {
        testWidgets(
          'width $width scale $scale keyboard $keyboard supports long names and setup',
          (tester) async {
            final store = PlayersStore();
            await store.saveNames([
              'عبد الرحمن محمد أحمد عبد الله الاسم الطويل',
              'محمد',
              'علي',
              'حسن',
            ]);
            final cubit = SetupCubit(store, GameSession(), Random(1));
            addTearDown(cubit.close);
            await cubit.loadPlayers();
            await _pumpPlayers(tester, cubit, width: width, scale: scale);
            expect(tester.takeException(), isNull);
            await tester.enterText(find.byType(TextField), 'مسودة');
            tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
            await tester.pumpAndSettle();
            expect(
              tester.widget<TextField>(find.byType(TextField)).controller!.text,
              'مسودة',
            );
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(find.text(AppStrings.next));
            await tester.tap(find.text(AppStrings.next));
            await tester.pumpAndSettle();
            expect(find.byType(GameSetupScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
            final deal = find.widgetWithText(AppButton, AppStrings.dealRoles);
            await tester.ensureVisible(deal);
            await tester.pumpAndSettle();
            expect(
              tester.getRect(deal).bottom,
              lessThanOrEqualTo(640 - keyboard),
            );
            cubit.toggleRole(RoleCatalog.guard.id);
            cubit.toggleRole(RoleCatalog.jester.id);
            await tester.pumpAndSettle();
            expect(_button(tester, AppStrings.dealRoles).onPressed, isNull);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'enabled role cards use both outline weight and switch position',
    (tester) async {
      final store = PlayersStore();
      await store.saveNames(['أحمد', 'محمد', 'علي', 'حسن']);
      final cubit = SetupCubit(store, GameSession(), Random(1));
      addTearDown(cubit.close);
      await cubit.loadPlayers();
      await _pumpPlayers(tester, cubit);
      await tester.tap(find.text(AppStrings.next));
      await tester.pumpAndSettle();
      final cards = tester
          .widgetList<RoleToggleCard>(find.byType(RoleToggleCard))
          .toList();
      expect(cards.where((card) => card.enabled).map((card) => card.name), [
        RoleCatalog.detective.nameAr,
        RoleCatalog.doctor.nameAr,
      ]);
      for (final card in find.byType(RoleToggleCard).evaluate()) {
        final finder = find.byWidget(card.widget);
        final decorated = tester.widget<DecoratedBox>(
          find
              .descendant(of: finder, matching: find.byType(DecoratedBox))
              .first,
        );
        final border = (decorated.decoration as BoxDecoration).border as Border;
        final toggle = tester.widget<Switch>(
          find.descendant(of: finder, matching: find.byType(Switch)),
        );
        expect(border.top.width, toggle.value ? 3 : 1.5);
      }
    },
  );
}

Future<void> _pumpPlayers(
  WidgetTester tester,
  SetupCubit cubit, {
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
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    MafiaApp(
      home: BlocProvider.value(value: cubit, child: const PlayersScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

AppButton _button(WidgetTester tester, String label) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, label));

Future<void> _toggleRole(WidgetTester tester, String name) async {
  final card = find.byWidgetPredicate(
    (widget) => widget is RoleToggleCard && widget.name == name,
  );
  final toggle = find.descendant(of: card, matching: find.byType(Switch));
  await tester.ensureVisible(toggle);
  await tester.tap(toggle);
  await tester.pumpAndSettle();
}
