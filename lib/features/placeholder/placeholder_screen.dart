import 'package:flutter/material.dart';

import '../../core/assets.dart';
import '../../core/strings_ar.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_lottie.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.screenInset,
              end: AppSpacing.screenInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLottie(
                  asset: AppAssets.mafiaLoadingLottie,
                  size: AppSizes.lottiePlaceholder,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.appTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
