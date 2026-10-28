import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/app.dart';
import 'package:mafia/core/constants.dart';
import 'package:mafia/core/widgets/app_lottie.dart';

void main() {
  test('game limits match the PRD assumptions', () {
    expect(GameLimits.minPlayers, 4);
    expect(GameLimits.maxPlayers, 25);
  });

  testWidgets('app resolves to a dark theme and RTL direction', (tester) async {
    await tester.pumpWidget(
      const MafiaApp(home: Scaffold(body: SizedBox.shrink())),
    );

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('missing Lottie asset renders silently', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppLottie(asset: 'assets/lotties/missing.json')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(AppLottie),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox && widget.width == 0 && widget.height == 0,
        ),
      ),
      findsOneWidget,
    );
  });
}
