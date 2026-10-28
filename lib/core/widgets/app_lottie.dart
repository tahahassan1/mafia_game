import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme.dart';

class AppLottie extends StatelessWidget {
  const AppLottie({
    super.key,
    required this.asset,
    this.size = AppSizes.lottieDefault,
    this.controller,
    this.fit = BoxFit.contain,
    this.onLoaded,
  });

  final String asset;
  final double size;
  final Animation<double>? controller;
  final BoxFit fit;
  final void Function(LottieComposition)? onLoaded;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final externalController = reduceMotion ? null : controller;

    return SizedBox.square(
      dimension: size,
      child: Lottie.asset(
        asset,
        controller: externalController,
        animate: externalController == null && !reduceMotion,
        repeat: true,
        fit: fit,
        alignment: Alignment.center,
        onLoaded: onLoaded,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}
