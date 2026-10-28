import 'package:flutter/material.dart';

import '../../../../core/strings_ar.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/app_button.dart';

class TimerActions extends StatelessWidget {
  const TimerActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onReset,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final primary = AppButton(
      key: ValueKey(primaryLabel),
      label: primaryLabel,
      onPressed: onPrimary,
    );
    final reset = AppButton(
      label: AppStrings.resetTimer,
      secondary: true,
      onPressed: onReset,
    );
    if (MediaQuery.textScalerOf(context)
            .scale(AppStyles.buttonLabel.fontSize!) >
        AppStyles.buttonLabel.fontSize!) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primary,
          const SizedBox(height: AppSpacing.sm),
          reset,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: reset),
      ],
    );
  }
}
