import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/strings_ar.dart';
import '../../../core/theme.dart';
import '../../game/domain/game_session.dart';
import 'widgets/host_role_row.dart';

class HostRolesSheet extends StatefulWidget {
  const HostRolesSheet({super.key, required this.session});

  final GameSession session;

  @override
  State<HostRolesSheet> createState() => _HostRolesSheetState();
}

class _HostRolesSheetState extends State<HostRolesSheet>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _countdown;
  late final Timer _autoClose;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _countdown = AnimationController(
      vsync: this,
      duration: TimerLimits.hostAutoClose,
      value: 1,
    );
    _autoClose = Timer(TimerLimits.hostAutoClose, _dismiss);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _countdown.stop();
    } else if (!_countdown.isAnimating) {
      _countdown.reverse();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _dismiss();
  }

  void _dismiss() {
    if (!mounted || _closing) return;
    setState(() => _closing = true);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoClose.cancel();
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: AppSizes.hostSheetHeightFactor,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.ink, width: AppBorders.strong),
        ),
      ),
      child: _closing
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _countdown,
                    builder: (context, child) => Semantics(
                      label: AppStrings.hostAutoClose,
                      child: ExcludeSemantics(
                        child: LinearProgressIndicator(
                          value: _countdown.value,
                          color: AppColors.ink,
                          backgroundColor: AppColors.divider,
                          minHeight: AppSpacing.xxs,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: widget.session.assignments.length,
                      itemBuilder: (context, index) => HostRoleRow(
                        assignment: widget.session.assignments[index],
                      ),
                      separatorBuilder: (context, index) => const Divider(),
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}
