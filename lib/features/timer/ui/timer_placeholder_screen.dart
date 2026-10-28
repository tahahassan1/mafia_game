import 'package:flutter/material.dart';

import '../../../core/strings_ar.dart';
import '../../../core/theme.dart';

class TimerPlaceholderScreen extends StatelessWidget {
  const TimerPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenInset),
            child: Text(
              AppStrings.timerPlaceholder,
              style: AppStyles.screenTitle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );
}
