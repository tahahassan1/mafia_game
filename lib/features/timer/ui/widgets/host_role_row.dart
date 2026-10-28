import 'package:flutter/material.dart';

import '../../../../core/strings_ar.dart';
import '../../../../core/theme.dart';
import '../../../game/domain/assignment.dart';
import '../../../roles/domain/team.dart';

class HostRoleRow extends StatelessWidget {
  const HostRoleRow({super.key, required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(assignment.player.name, style: AppStyles.bodyStrong),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(assignment.role.nameAr, style: AppStyles.body),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    width: AppBorders.strong,
                    color: switch (assignment.role.team) {
                      Team.mafia => AppColors.teamMafia,
                      Team.civilian => AppColors.teamCivilian,
                      Team.neutral => AppColors.teamNeutral,
                    },
                  ),
                ),
              ),
              child: Text(
                AppStrings.teamLabel(assignment.role.team),
                style: AppStyles.supporting,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
