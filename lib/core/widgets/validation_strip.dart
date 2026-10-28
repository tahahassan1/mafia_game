import 'package:flutter/material.dart';

import '../theme.dart';

class ValidationStrip extends StatelessWidget {
  const ValidationStrip({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.dangerSurface,
            borderRadius: AppRadii.controlBorder,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    message!,
                    style: AppStyles.supporting.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
