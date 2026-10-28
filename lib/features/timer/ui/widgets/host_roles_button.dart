import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants.dart';
import '../../../../core/strings_ar.dart';
import '../../../../core/theme.dart';

class HostRolesButton extends StatelessWidget {
  const HostRolesButton({
    super.key,
    required this.onTap,
    required this.onLongPress,
  });

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: AppStrings.hostRoles,
    onTap: onTap,
    onLongPress: onLongPress,
    child: ExcludeSemantics(
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (recognizer) => recognizer.onTap = onTap,
              ),
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(
                  duration: TimerLimits.hostLongPress,
                ),
                (recognizer) => recognizer.onLongPress = onLongPress,
              ),
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minControlHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.ink, width: AppBorders.strong),
            borderRadius: AppRadii.controlBorder,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: AppColors.ink),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  AppStrings.hostRoles,
                  style: AppStyles.buttonLabel.copyWith(color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
