import 'package:flutter/material.dart';

import '../../../../core/assets.dart';
import '../../../../core/strings_ar.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/app_lottie.dart';

class PlayersEmptyState extends StatelessWidget {
  const PlayersEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Column(
      children: [
        const AppLottie(
          asset: AppAssets.mafiaLoadingLottie,
          size: AppSizes.emptyStateLottie,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.emptyPlayers,
          style: AppStyles.body,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
