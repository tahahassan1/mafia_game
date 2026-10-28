import 'package:flutter/material.dart';

import '../../../../core/strings_ar.dart';
import '../../../../core/theme.dart';
import 'timer_duration_stepper.dart';

class TimerDurationControls extends StatelessWidget {
  const TimerDurationControls({
    super.key,
    required this.minutes,
    required this.seconds,
    required this.onIncreaseMinutes,
    required this.onDecreaseMinutes,
    required this.onIncreaseSeconds,
    required this.onDecreaseSeconds,
  });

  final int minutes;
  final int seconds;
  final VoidCallback? onIncreaseMinutes;
  final VoidCallback? onDecreaseMinutes;
  final VoidCallback? onIncreaseSeconds;
  final VoidCallback? onDecreaseSeconds;

  @override
  Widget build(BuildContext context) {
    final minutesControl = TimerDurationStepper(
      label: AppStrings.minutes,
      value: minutes,
      increaseLabel: AppStrings.increaseMinutes,
      decreaseLabel: AppStrings.decreaseMinutes,
      onIncrease: onIncreaseMinutes,
      onDecrease: onDecreaseMinutes,
    );
    final secondsControl = TimerDurationStepper(
      label: AppStrings.seconds,
      value: seconds,
      increaseLabel: AppStrings.increaseSeconds,
      decreaseLabel: AppStrings.decreaseSeconds,
      onIncrease: onIncreaseSeconds,
      onDecrease: onDecreaseSeconds,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final normalText =
            MediaQuery.textScalerOf(context)
                .scale(AppStyles.screenTitle.fontSize!) <=
            AppStyles.screenTitle.fontSize!;
        if (normalText &&
            constraints.maxWidth >=
                AppSizes.timerStepperMinWidth * 2 + AppSpacing.md) {
          return Row(
            children: [
              Expanded(child: minutesControl),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: secondsControl),
            ],
          );
        }
        return Column(
          children: [
            minutesControl,
            const SizedBox(height: AppSpacing.sm),
            secondsControl,
          ],
        );
      },
    );
  }
}
