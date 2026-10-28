import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/strings_ar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/round_exit_scope.dart';
import '../../game/domain/game_session.dart';
import '../../timer/timer_cubit.dart';
import '../../timer/ui/timer_screen.dart';
import '../reveal_cubit.dart';
import '../reveal_state.dart';
import 'widgets/handoff_prompt.dart';
import 'widgets/reveal_page_layout.dart';
import 'widgets/reveal_role_card.dart';

class HandoffRevealScreen extends StatefulWidget {
  const HandoffRevealScreen({super.key});

  @override
  State<HandoffRevealScreen> createState() => _HandoffRevealScreenState();
}

class _HandoffRevealScreenState extends State<HandoffRevealScreen> {
  bool _openingTimer = false;

  @override
  void initState() {
    super.initState();
    if (context.read<RevealCubit>().state.isFinished) _openTimerAfterFrame();
  }

  void _openTimerAfterFrame() {
    if (_openingTimer) return;
    _openingTimer = true;
    // First render the neutral finished state, removing even the final role.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<TimerCubit>(),
            child: const TimerScreen(),
          ),
        ),
      );
    });
  }

  void _hideAndNext() {
    if (context.read<RevealCubit>().hideAndNext()) _openTimerAfterFrame();
  }

  @override
  Widget build(BuildContext context) => RoundExitScope(
    onConfirmed: () => getIt<GameSession>().clear(),
    canRequestExit: () => !_openingTimer,
    child: Scaffold(
      body: BlocBuilder<RevealCubit, RevealState>(
        builder: (context, state) {
          final assignment = context.read<RevealCubit>().currentAssignment;
          if (state.isFinished || assignment == null) {
            return const SizedBox.shrink();
          }
          return RevealPageLayout(
            contentKey: ValueKey((state.currentIndex, state.isRevealed)),
            content: state.isRevealed
                ? RevealRoleCard(
                    name: assignment.role.nameAr,
                    description: assignment.role.descriptionAr,
                  )
                : HandoffPrompt(playerName: assignment.player.name),
            action: AppButton(
              key: ValueKey((state.currentIndex, state.isRevealed)),
              label: state.isRevealed
                  ? AppStrings.hideAndNext
                  : AppStrings.revealRole,
              secondary: state.isRevealed,
              onPressed: state.isRevealed
                  ? _hideAndNext
                  : context.read<RevealCubit>().reveal,
            ),
          );
        },
      ),
    ),
  );
}
