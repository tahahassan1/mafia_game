import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/strings_ar.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_page_layout.dart';
import '../../../core/widgets/app_stepper.dart';
import '../../../core/widgets/role_toggle_card.dart';
import '../../../core/widgets/validation_strip.dart';
import '../../game/domain/validation_result.dart';
import '../../reveal/reveal_cubit.dart';
import '../../reveal/ui/handoff_reveal_screen.dart';
import '../../roles/domain/role_catalog.dart';
import '../setup_cubit.dart';
import '../setup_state.dart';

class GameSetupScreen extends StatelessWidget {
  const GameSetupScreen({super.key});

  void _deal(BuildContext context) {
    if (!context.read<SetupCubit>().deal()) return;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<RevealCubit>(),
          child: const HandoffRevealScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppPageLayout(
    title: AppStrings.setupTitle,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(AppStrings.mafiaCount, style: AppStyles.sectionHeading),
        const SizedBox(height: AppSpacing.sm),
        BlocBuilder<SetupCubit, SetupState>(
          buildWhen: (previous, current) =>
              previous.mafiaCount != current.mafiaCount ||
              previous.minMafiaCount != current.minMafiaCount ||
              previous.maxMafiaCount != current.maxMafiaCount,
          builder: (context, state) => AppStepper(
            value: state.mafiaCount,
            increaseLabel: AppStrings.increaseMafia,
            decreaseLabel: AppStrings.decreaseMafia,
            onIncrease: state.canIncreaseMafia
                ? context.read<SetupCubit>().increaseMafia
                : null,
            onDecrease: state.canDecreaseMafia
                ? context.read<SetupCubit>().decreaseMafia
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(AppStrings.mafiaLimits, style: AppStyles.supporting),
        const SizedBox(height: AppSpacing.lg),
        const Text(AppStrings.optionalRoles, style: AppStyles.sectionHeading),
        const SizedBox(height: AppSpacing.sm),
        for (final role in RoleCatalog.specials) ...[
          BlocSelector<SetupCubit, SetupState, bool>(
            selector: (state) => state.enabledRoleIds.contains(role.id),
            builder: (context, enabled) => RoleToggleCard(
              name: role.nameAr,
              description: role.descriptionAr,
              enabled: enabled,
              onChanged: (_) => context.read<SetupCubit>().toggleRole(role.id),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    ),
    footer: BlocBuilder<SetupCubit, SetupState>(
      buildWhen: (previous, current) =>
          previous.validation != current.validation ||
          previous.canDeal != current.canDeal ||
          previous.specialRolesToDisable != current.specialRolesToDisable,
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValidationStrip(
            message: switch (state.validation) {
              Valid() => null,
              Invalid(:final reason) => AppStrings.validationMessage(
                reason,
                minMafia: state.minMafiaCount,
                maxMafia: state.maxMafiaCount,
                excessRoles: state.specialRolesToDisable,
              ),
            },
          ),
          AppButton(
            label: AppStrings.dealRoles,
            onPressed: state.canDeal ? () => _deal(context) : null,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    ),
  );
}
