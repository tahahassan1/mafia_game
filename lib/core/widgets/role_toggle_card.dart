import 'package:flutter/material.dart';

import '../theme.dart';

class RoleToggleCard extends StatelessWidget {
  const RoleToggleCard({
    super.key,
    required this.name,
    required this.description,
    required this.enabled,
    required this.onChanged,
  });

  final String name;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: enabled ? AppColors.surfaceRaised : AppColors.surface,
      borderRadius: AppRadii.cardBorder,
      border: Border.all(
        color: enabled ? AppColors.ink : AppColors.divider,
        width: enabled ? AppBorders.strong : AppBorders.quiet,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(description, style: AppStyles.supporting),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            label: name,
            child: Switch(value: enabled, onChanged: onChanged),
          ),
        ],
      ),
    ),
  );
}
