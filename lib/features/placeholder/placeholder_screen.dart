import 'package:flutter/material.dart';

import '../../core/strings_ar.dart';
import '../../core/theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.screenInset,
              end: AppSpacing.screenInset,
            ),
            child: Text(
              AppStrings.dealtPlaceholder,
              style: AppStyles.screenTitle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
