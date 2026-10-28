import 'package:flutter/material.dart';

class AppLabeledInput extends StatelessWidget {
  const AppLabeledInput({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    required this.onSubmitted,
    this.error,
    this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? error;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    textInputAction: TextInputAction.done,
    decoration: InputDecoration(labelText: label, errorText: error),
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );
}
