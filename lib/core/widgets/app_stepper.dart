import 'package:flutter/material.dart';

import '../strings_ar.dart';
import '../theme.dart';

class AppStepper extends StatelessWidget {
  const AppStepper({
    super.key,
    required this.value,
    required this.increaseLabel,
    required this.decreaseLabel,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int value;
  final String increaseLabel;
  final String decreaseLabel;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      IconButton.outlined(
        tooltip: decreaseLabel,
        onPressed: onDecrease,
        icon: const Icon(Icons.remove),
        constraints: const BoxConstraints(
          minWidth: AppSizes.minTouchTarget,
          minHeight: AppSizes.minTouchTarget,
        ),
      ),
      Flexible(
        child: Text(
          AppStrings.number(value),
          textDirection: TextDirection.ltr,
          style: AppStyles.screenTitle,
        ),
      ),
      IconButton.outlined(
        tooltip: increaseLabel,
        onPressed: onIncrease,
        icon: const Icon(Icons.add),
        constraints: const BoxConstraints(
          minWidth: AppSizes.minTouchTarget,
          minHeight: AppSizes.minTouchTarget,
        ),
      ),
    ],
  );
}
