import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/colors/app_colors.dart';
import '../data/board_repository.dart';
import 'board_bloc.dart';
import 'board_event.dart';
import 'board_state.dart';
import 'widgets/kanban_board.dart';

class BoardPage extends StatelessWidget {
  const BoardPage({required this.repository, super.key});

  final BoardRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BoardBloc(repository: repository)..add(const BoardLoadRequested()),
      child: const _BoardView(),
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView();

  static const _pagePadding = EdgeInsets.fromLTRB(16, 16, 16, 16);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.pageGradientStart,
                  AppColors.pageGradientEnd
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: _pagePadding,
                child: state.isLoading && state.columns.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : KanbanBoard(
                        columns: state.columns,
                        busyTaskIds: state.busyTaskIds,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
