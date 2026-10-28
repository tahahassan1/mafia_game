import 'package:flutter/material.dart';

import '../../../../core/assets.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/app_lottie.dart';
import 'reveal_content_viewport.dart';

class RevealPageLayout extends StatelessWidget {
  const RevealPageLayout({
    super.key,
    required this.content,
    required this.contentKey,
    required this.action,
  });

  final Widget content;
  final Key contentKey;
  final Widget action;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: ExcludeSemantics(
                  child: AppLottie(asset: AppAssets.mafiaLoadingLottie),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: RevealContentViewport(key: contentKey, content: content),
              ),
              const SizedBox(height: AppSpacing.md),
              action,
            ],
          ),
        ),
      ),
    ),
  );
}
