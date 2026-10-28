import 'package:flutter/material.dart';

import '../../../../core/strings_ar.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/validation_strip.dart';

class PlayersFooter extends StatelessWidget {
  const PlayersFooter({
    super.key,
    required this.count,
    required this.message,
    required this.onNext,
  });

  final int count;
  final String? message;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(AppStrings.playerCount(count), style: AppStyles.supporting),
      const SizedBox(height: AppSpacing.xs),
      ValidationStrip(message: message),
      AppButton(label: AppStrings.next, onPressed: onNext),
      const SizedBox(height: AppSpacing.xs),
    ],
  );
}
