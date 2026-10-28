import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/strings_ar.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_page_layout.dart';
import '../../game/domain/validation_result.dart';
import '../setup_cubit.dart';
import '../setup_state.dart';
import 'game_setup_screen.dart';
import 'widgets/player_name_editor.dart';
import 'widgets/player_row.dart';
import 'widgets/players_empty_state.dart';
import 'widgets/players_footer.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _editorKey = GlobalKey();
  bool _openingSetup = false;

  Future<void> _openSetup() async {
    if (_openingSetup) return;
    _openingSetup = true;
    FocusManager.instance.primaryFocus?.unfocus();
    final cubit = context.read<SetupCubit>()..beginSetup();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const GameSetupScreen()),
      ),
    );
    _openingSetup = false;
  }

  void _showStorageIssue(BuildContext context, SetupState state) {
    final labelHeight = MediaQuery.textScalerOf(context)
        .scale(AppStyles.buttonLabel.fontSize! * AppStyles.buttonLabel.height!);
    final actionHeight = max(
      AppSizes.minControlHeight,
      labelHeight + AppSpacing.sm * 2,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceRaised,
        margin: EdgeInsetsDirectional.only(
          start: AppSpacing.md,
          end: AppSpacing.md,
          bottom: actionHeight + AppShadows.hardOffset.dy + AppSpacing.lg,
        ),
        content: Text(
          state.namesSaveFailed
              ? AppStrings.namesSaveFailed
              : AppStrings.namesLoadFailed,
          style: AppStyles.supporting.copyWith(color: AppColors.ink),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocListener<SetupCubit, SetupState>(
    listenWhen: (previous, current) =>
        (!previous.namesSaveFailed && current.namesSaveFailed) ||
        (!previous.namesLoadFailed && current.namesLoadFailed),
    listener: _showStorageIssue,
    child: AppPageLayout(
      title: AppStrings.playersTitle,
      header: BlocBuilder<SetupCubit, SetupState>(
        buildWhen: (previous, current) =>
            previous.editingIndex != current.editingIndex ||
            previous.nameError != current.nameError ||
            previous.players != current.players,
        builder: (context, state) => PlayerNameEditor(
          key: _editorKey,
          editingIndex: state.editingIndex,
          editingName: state.editingIndex == null
              ? null
              : state.players[state.editingIndex!],
          error: AppStrings.nameError(state.nameError),
          onSubmit: context.read<SetupCubit>().submitPlayer,
          onChanged: context.read<SetupCubit>().nameChanged,
          onCancel: context.read<SetupCubit>().cancelEditing,
        ),
      ),
      content: BlocSelector<SetupCubit, SetupState, List<String>>(
        selector: (state) => state.players,
        builder: (context, players) => players.isEmpty
            ? const PlayersEmptyState()
            : Column(
                children: [
                  for (final (index, name) in players.indexed)
                    PlayerRow(
                      name: name,
                      onEdit: () =>
                          context.read<SetupCubit>().startEditing(index),
                      onDelete: () =>
                          context.read<SetupCubit>().removePlayer(index),
                    ),
                ],
              ),
      ),
      footer: BlocBuilder<SetupCubit, SetupState>(
        buildWhen: (previous, current) =>
            previous.players.length != current.players.length ||
            previous.playersValidation != current.playersValidation,
        builder: (context, state) => PlayersFooter(
          count: state.players.length,
          message: switch (state.playersValidation) {
            Valid() => null,
            Invalid(:final reason) => AppStrings.validationMessage(reason),
          },
          onNext: state.canAdvance ? _openSetup : null,
        ),
      ),
    ),
  );
}
