import 'package:flutter/material.dart';

class RevealContentViewport extends StatelessWidget {
  const RevealContentViewport({super.key, required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(child: content),
      ),
    ),
  );
}
