import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/assets.dart';
import '../../../core/di.dart';
import '../../../core/strings_ar.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_lottie.dart';
import '../../../core/widgets/app_page_layout.dart';
import '../../../core/widgets/round_exit_scope.dart';
import '../../game/domain/game_session.dart';
import '../data/timer_feedback.dart';
import '../timer_cubit.dart';
import '../timer_state.dart';
import 'host_roles_sheet.dart';
import 'widgets/host_roles_button.dart';
import 'widgets/timer_actions.dart';
import 'widgets/timer_duration_controls.dart';
import 'widgets/timer_panel.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  late final Future<void> _wakeLockReady;
  bool _reduceMotion = false;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = AnimationController(vsync: this);
    _wakeLockReady = WakelockPlus.enable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncClock(context.read<TimerCubit>().state);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TimerCubit>().refresh();
      unawaited(WakelockPlus.enable());
    }
  }

  void _onClockLoaded(LottieComposition composition) {
    if (!mounted) return;
    _clock.duration = composition.duration;
    _syncClock(context.read<TimerCubit>().state);
  }

  void _syncClock(TimerState state) {
    if (_reduceMotion) {
      _clock.stop();
      _clock.value = 0;
      return;
    }
    switch (state) {
      case TimerIdle():
        _clock.stop();
        _clock.value = 0;
      case TimerRunning():
        if (_clock.duration != null && !_clock.isAnimating) _clock.repeat();
      case TimerPaused():
        _clock.stop();
      case TimerFinished():
        _clock.stop();
        _clock.value = 1;
    }
  }

  void _onPhaseChanged(BuildContext context, TimerState state) {
    _syncClock(state);
    if (state is TimerFinished) {
      unawaited(HapticFeedback.vibrate());
      unawaited(TimerFeedback.playFinishSound());
    }
  }

  void _showHostHint() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.hostLongPressHint)));
  }

  Future<void> _openHostRoles() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.surface,
        barrierColor: AppColors.sheetScrim,
        sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : const AnimationStyle(
                duration: AppMotion.sheet,
                reverseDuration: AppMotion.sheet,
              ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.sheetTopBorder,
        ),
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        builder: (_) => HostRolesSheet(session: getIt<GameSession>()),
      );
    } finally {
      _sheetOpen = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    unawaited(_wakeLockReady.then((_) => WakelockPlus.disable()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RoundExitScope(
    onConfirmed: () {
      context.read<TimerCubit>().reset();
      getIt<GameSession>().clear();
    },
    child: BlocListener<TimerCubit, TimerState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: _onPhaseChanged,
      child: AppPageLayout(
        title: AppStrings.timerTitle,
        automaticallyImplyLeading: false,
        content: Column(
          children: [
            Center(
              child: ExcludeSemantics(
                child: AppLottie(
                  asset: AppAssets.mafiaClockLottie,
                  size: AppSizes.timerClockLottie,
                  controller: _clock,
                  onLoaded: _onClockLoaded,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            BlocBuilder<TimerCubit, TimerState>(
              buildWhen: (previous, current) =>
                  previous.displaySeconds != current.displaySeconds ||
                  previous.runtimeType != current.runtimeType ||
                  previous.duration != current.duration,
              builder: (context, state) {
                final cubit = context.read<TimerCubit>();
                return TimerPanel(
                  seconds: state.displaySeconds,
                  finished: state is TimerFinished,
                  controls: switch (state) {
                    TimerIdle() => TimerDurationControls(
                      minutes: state.minutes,
                      seconds: state.seconds,
                      onIncreaseMinutes: state.canIncreaseMinutes
                          ? cubit.increaseMinutes
                          : null,
                      onDecreaseMinutes: state.canDecreaseMinutes
                          ? cubit.decreaseMinutes
                          : null,
                      onIncreaseSeconds: state.canIncreaseSeconds
                          ? cubit.increaseSeconds
                          : null,
                      onDecreaseSeconds: state.canDecreaseSeconds
                          ? cubit.decreaseSeconds
                          : null,
                    ),
                    TimerRunning() || TimerPaused() || TimerFinished() => null,
                  },
                );
              },
            ),
          ],
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<TimerCubit, TimerState>(
              buildWhen: (previous, current) =>
                  previous.runtimeType != current.runtimeType,
              builder: (context, state) {
                final cubit = context.read<TimerCubit>();
                final (label, action) = switch (state) {
                  TimerIdle() => (AppStrings.startTimer, cubit.start),
                  TimerRunning() => (AppStrings.pauseTimer, cubit.pause),
                  TimerPaused() => (AppStrings.resumeTimer, cubit.resume),
                  TimerFinished() => (AppStrings.restartTimer, cubit.start),
                };
                return TimerActions(
                  primaryLabel: label,
                  onPrimary: action,
                  onReset: cubit.reset,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            HostRolesButton(onTap: _showHostHint, onLongPress: _openHostRoles),
            const SizedBox(height: AppSpacing.xxs),
            const Text(
              AppStrings.hostLongPressHint,
              style: AppStyles.supporting,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    ),
  );
}
