import 'package:flutter/material.dart';

import '../theme.dart';
import 'round_exit_dialog.dart';

class RoundExitScope extends StatefulWidget {
  const RoundExitScope({
    super.key,
    required this.onConfirmed,
    required this.child,
    this.canRequestExit,
  });

  final VoidCallback onConfirmed;
  final Widget child;
  final bool Function()? canRequestExit;

  @override
  State<RoundExitScope> createState() => _RoundExitScopeState();
}

class _RoundExitScopeState extends State<RoundExitScope> {
  bool _dialogOpen = false;
  bool _exiting = false;

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop ||
        _dialogOpen ||
        _exiting ||
        !(widget.canRequestExit?.call() ?? true)) {
      return;
    }
    _dialogOpen = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        animationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : const AnimationStyle(
                duration: AppMotion.sheet,
                reverseDuration: AppMotion.sheet,
              ),
        builder: (_) => const RoundExitDialog(),
      );
      if (!mounted || confirmed != true) return;
      setState(() => _exiting = true);
      // Remove private content before the outgoing route can be painted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onConfirmed();
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: _onPopInvoked,
    child: _exiting ? const SizedBox.shrink() : widget.child,
  );
}
