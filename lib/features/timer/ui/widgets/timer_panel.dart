import 'package:flutter/material.dart';

import '../../../../core/strings_ar.dart';
import '../../../../core/theme.dart';

class TimerPanel extends StatelessWidget {
  const TimerPanel({
    super.key,
    required this.seconds,
    required this.finished,
    this.controls,
  });

  final int seconds;
  final bool finished;
  final Widget? controls;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(
        color: finished ? AppColors.brandPrimary : AppColors.ink,
        width: AppBorders.strong,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            AppStrings.timerDigits(seconds),
            textDirection: TextDirection.ltr,
            style: AppStyles.timerDigits.copyWith(
              color: finished ? AppColors.brandPrimary : AppColors.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (finished)
          const Text(
            AppStrings.timerFinished,
            style: AppStyles.sectionHeading,
            textAlign: TextAlign.center,
          ),
        if (controls != null) ...[
          const SizedBox(height: AppSpacing.md),
          controls!,
        ],
      ],
    ),
  );
}
