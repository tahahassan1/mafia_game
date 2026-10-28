import 'package:flutter/material.dart';

import '../../../../core/strings_ar.dart';
import '../../../../core/theme.dart';

class PlayerRow extends StatelessWidget {
  const PlayerRow({
    super.key,
    required this.name,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink,
                alignment: AlignmentDirectional.centerStart,
                minimumSize: const Size(0, AppSizes.minTouchTarget),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              ),
              child: Semantics(
                label: AppStrings.editPlayer,
                child: Text(name, style: AppStyles.bodyStrong),
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.deletePlayer,
            onPressed: onDelete,
            icon: const Icon(Icons.close, color: AppColors.ink),
            constraints: const BoxConstraints(
              minWidth: AppSizes.minTouchTarget,
              minHeight: AppSizes.minTouchTarget,
            ),
          ),
        ],
      ),
      const Divider(height: AppSpacing.xxs),
    ],
  );
}
