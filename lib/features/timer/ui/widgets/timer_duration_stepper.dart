import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/widgets/app_stepper.dart';

class TimerDurationStepper extends StatelessWidget {
  const TimerDurationStepper({
    super.key,
    required this.label,
    required this.value,
    required this.increaseLabel,
    required this.decreaseLabel,
    required this.onIncrease,
    required this.onDecrease,
  });

  final String label;
  final int value;
  final String increaseLabel;
  final String decreaseLabel;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: AppStyles.supporting),
      AppStepper(
        value: value,
        increaseLabel: increaseLabel,
        decreaseLabel: decreaseLabel,
        onIncrease: onIncrease,
        onDecrease: onDecrease,
      ),
    ],
  );
}
