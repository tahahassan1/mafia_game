import 'package:flutter/material.dart';

import '../../../../core/theme.dart';

class RevealRoleCard extends StatelessWidget {
  const RevealRoleCard({
    super.key,
    required this.name,
    required this.description,
  });

  final String name;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      right: AppShadows.hardOffset.dx,
      bottom: AppShadows.hardOffset.dy,
    ),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.ink, width: AppBorders.strong),
        borderRadius: AppRadii.cardBorder,
        boxShadow: AppShadows.revealCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: AppStyles.roleName, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(description, style: AppStyles.body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
