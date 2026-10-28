import 'package:flutter/material.dart';

import '../../../../core/strings_ar.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_labeled_input.dart';

class PlayerNameEditor extends StatefulWidget {
  const PlayerNameEditor({
    super.key,
    required this.editingIndex,
    required this.editingName,
    required this.error,
    required this.onSubmit,
    required this.onChanged,
    required this.onCancel,
  });

  final int? editingIndex;
  final String? editingName;
  final String? error;
  final Future<bool> Function(String) onSubmit;
  final VoidCallback onChanged;
  final VoidCallback onCancel;

  @override
  State<PlayerNameEditor> createState() => _PlayerNameEditorState();
}

class _PlayerNameEditorState extends State<PlayerNameEditor> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.editingName ?? '';
  }

  @override
  void didUpdateWidget(covariant PlayerNameEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editingName != widget.editingName) {
      _controller.text = widget.editingName ?? '';
      if (widget.editingIndex != null) _focusNode.requestFocus();
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final accepted = await widget.onSubmit(_controller.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (accepted) _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: MediaQuery.textScalerOf(context).scale(AppSpacing.sm),
      bottom: AppSpacing.sm,
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppLabeledInput(
                controller: _controller,
                focusNode: _focusNode,
                label: AppStrings.playerName,
                error: widget.error,
                onChanged: (_) => widget.onChanged(),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton.filled(
              tooltip: widget.editingIndex == null
                  ? AppStrings.addPlayer
                  : AppStrings.saveName,
              onPressed: _submitting ? null : _submit,
              icon: Icon(widget.editingIndex == null ? Icons.add : Icons.check),
              constraints: const BoxConstraints(
                minWidth: AppSizes.minTouchTarget,
                minHeight: AppSizes.minTouchTarget,
              ),
            ),
          ],
        ),
        if (widget.editingIndex != null) ...[
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: AppStrings.cancel,
            onPressed: _submitting ? null : widget.onCancel,
            secondary: true,
          ),
        ],
      ],
    ),
  );
}
