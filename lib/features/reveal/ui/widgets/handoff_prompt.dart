import 'package:flutter/material.dart';

import '../../../../core/strings_ar.dart';
import '../../../../core/theme.dart';

class HandoffPrompt extends StatelessWidget {
  const HandoffPrompt({super.key, required this.playerName});

  final String playerName;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        AppStrings.handoffLabel,
        style: AppStyles.supporting,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        playerName,
        style: AppStyles.handoffName,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),
      const Text(
        AppStrings.handoffInstruction,
        style: AppStyles.body,
        textAlign: TextAlign.center,
      ),
    ],
  );
}
