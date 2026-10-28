import 'package:flutter/material.dart';

import '../theme.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool secondary;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final primary = enabled && !widget.secondary;
    final offset = _pressed && primary ? AppShadows.hardOffset : Offset.zero;
    final color = !enabled
        ? AppColors.textSecondary
        : primary
        ? AppColors.onBrandPrimary
        : AppColors.ink;

    return Semantics(
      button: true,
      enabled: enabled,
      child: Padding(
        padding: EdgeInsets.only(
          right: widget.secondary ? 0 : AppShadows.hardOffset.dx,
          bottom: widget.secondary ? 0 : AppShadows.hardOffset.dy,
        ),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.press,
          transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
          decoration: BoxDecoration(
            borderRadius: AppRadii.controlBorder,
            boxShadow: primary && !_pressed ? AppShadows.primaryButton : null,
          ),
          child: Material(
            color: primary ? AppColors.brandPrimary : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.controlBorder,
              side: BorderSide(
                color: enabled ? AppColors.ink : AppColors.divider,
                width: enabled ? AppBorders.strong : AppBorders.quiet,
              ),
            ),
            child: InkWell(
              onTap: widget.onPressed,
              onHighlightChanged: (pressed) =>
                  setState(() => _pressed = pressed),
              borderRadius: AppRadii.controlBorder,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.minControlHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Center(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: AppStyles.buttonLabel.copyWith(color: color),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
