import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

class AppPageLayout extends StatelessWidget {
  const AppPageLayout({
    super.key,
    required this.title,
    required this.content,
    required this.footer,
    this.header,
  });

  final String title;
  final Widget content;
  final Widget footer;
  final Widget? header;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: AppStyles.screenTitle),
      toolbarHeight: max(
        AppSizes.minControlHeight,
        MediaQuery.textScalerOf(context).scale(AppSizes.appBarTitleHeight) +
            AppSpacing.md,
      ),
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenInset,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxHeight < AppSizes.compactViewportHeight) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        ?header,
                        content,
                        const SizedBox(height: AppSpacing.md),
                        footer,
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    ?header,
                    Expanded(
                      child: SingleChildScrollView(
                        child: SizedBox(width: double.infinity, child: content),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    footer,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
