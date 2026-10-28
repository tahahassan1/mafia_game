import 'package:flutter/material.dart';

import '../strings_ar.dart';
import '../theme.dart';

class RoundExitDialog extends StatelessWidget {
  const RoundExitDialog({super.key});

  void _answer(BuildContext context, bool exit) {
    if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      Navigator.of(context).pop(exit);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    elevation: 0,
    backgroundColor: AppColors.surface,
    surfaceTintColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadii.cardBorder,
      side: const BorderSide(color: AppColors.ink, width: AppBorders.strong),
    ),
    title: const Text(
      AppStrings.exitRoundTitle,
      style: AppStyles.sectionHeading,
    ),
    content: const Text(AppStrings.exitRoundDescription, style: AppStyles.body),
    actions: [
      TextButton(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppStyles.buttonLabel,
          minimumSize: const Size(
            AppSizes.minTouchTarget,
            AppSizes.minTouchTarget,
          ),
        ),
        onPressed: () => _answer(context, false),
        child: const Text(AppStrings.keepRound),
      ),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          textStyle: AppStyles.buttonLabel,
          minimumSize: const Size(
            AppSizes.minTouchTarget,
            AppSizes.minTouchTarget,
          ),
          side: const BorderSide(
            color: AppColors.danger,
            width: AppBorders.strong,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.controlBorder,
          ),
        ),
        onPressed: () => _answer(context, true),
        child: const Text(AppStrings.exitRound),
      ),
    ],
  );
}
