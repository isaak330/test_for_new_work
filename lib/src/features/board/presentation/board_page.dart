import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/colors/app_colors.dart';
import '../data/board_repository.dart';
import '../domain/board_column.dart';
import '../domain/kanban_task.dart';
import 'board_bloc.dart';

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
                    : _KanbanBoard(
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

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({
    required this.columns,
    required this.busyTaskIds,
  });

  final List<BoardColumn> columns;
  final Set<int> busyTaskIds;

  static const _emptyText = 'Нет задач для отображения.';

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) {
      return Center(
        child: Text(
          _emptyText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.mutedText,
              ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final column in columns) ...[
              _KanbanColumn(
                column: column,
                allColumns: columns,
                busyTaskIds: busyTaskIds,
              ),
              const SizedBox(width: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.column,
    required this.allColumns,
    required this.busyTaskIds,
  });

  final BoardColumn column;
  final List<BoardColumn> allColumns;
  final Set<int> busyTaskIds;

  static const _emptyColumnText = 'Перетащите задачу сюда';

  @override
  Widget build(BuildContext context) {
    return DragTarget<KanbanTask>(
      onWillAccept: (task) => task != null,
      onAccept: (task) => _moveTask(
        context,
        task: task,
        targetParentId: column.parentId,
        targetIndex: column.tasks.length,
      ),
      builder: (context, candidates, rejected) {
        final isHighlighted = candidates.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 340,
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.dropZoneActive : AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHighlighted ? AppColors.primary : AppColors.cardBorder,
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              _ColumnHeader(column: column),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: column.tasks.isEmpty
                      ? _ColumnDropArea(
                          onAccept: (task) => _moveTask(
                            context,
                            task: task,
                            targetParentId: column.parentId,
                            targetIndex: 0,
                          ),
                          child: Center(
                            child: Text(
                              _emptyColumnText,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.mutedText,
                                  ),
                            ),
                          ),
                        )
                      : ListView(
                          children: [
                            _ColumnDropArea(
                              onAccept: (task) => _moveTask(
                                context,
                                task: task,
                                targetParentId: column.parentId,
                                targetIndex: 0,
                              ),
                            ),
                            for (var index = 0;
                                index < column.tasks.length;
                                index++) ...[
                              _TaskCard(
                                task: column.tasks[index],
                                busy: busyTaskIds.contains(
                                  column.tasks[index].id,
                                ),
                                currentParentId: column.parentId,
                                allColumns: allColumns,
                              ),
                              _ColumnDropArea(
                                onAccept: (task) => _moveTask(
                                  context,
                                  task: task,
                                  targetParentId: column.parentId,
                                  targetIndex: index + 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _moveTask(
    BuildContext context, {
    required KanbanTask task,
    required int? targetParentId,
    required int targetIndex,
  }) {
    context.read<BoardBloc>().add(
          BoardTaskMoved(
            task: task,
            targetParentId: targetParentId,
            targetIndex: targetIndex,
          ),
        );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.column});

  final BoardColumn column;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.headerPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              column.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.chipBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${column.tasks.length}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnDropArea extends StatelessWidget {
  const _ColumnDropArea({
    required this.onAccept,
    this.child,
  });

  final ValueChanged<KanbanTask> onAccept;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<KanbanTask>(
      onWillAccept: (task) => task != null,
      onAccept: onAccept,
      builder: (context, candidates, rejected) {
        final isHighlighted = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: child == null ? (isHighlighted ? 26 : 14) : 72,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.dropZoneActive
                : (child == null ? Colors.transparent : AppColors.taskSurface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? AppColors.primary
                  : (child == null ? Colors.transparent : AppColors.cardBorder),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.busy,
    required this.currentParentId,
    required this.allColumns,
  });

  final KanbanTask task;
  final bool busy;
  final int? currentParentId;
  final List<BoardColumn> allColumns;

  static const _orderLabel = 'Порядок';
  static const _idLabel = 'ID';
  static const _moveTooltip = 'В папку...';
  static const _authorLabel = 'Автор';
  static const _typeLabel = 'Тип';
  static const _planLabel = 'План';
  static const _factLabel = 'Факт';

  @override
  Widget build(BuildContext context) {
    final destinationFolders = allColumns
        .where((folder) => folder.parentId != currentParentId)
        .toList(growable: false);

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: busy ? AppColors.taskBusyBackground : AppColors.taskSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.taskCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 54,
            decoration: BoxDecoration(
              color: busy ? AppColors.muted : AppColors.accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(label: _orderLabel, value: '${task.order}'),
                    _MetaChip(label: _idLabel, value: '${task.id}'),
                    if (_detailText(task.details['author']) case final value?)
                      _MetaChip(label: _authorLabel, value: value),
                    if (_detailText(task.details['type']) case final value?)
                      _MetaChip(label: _typeLabel, value: value),
                    if (_detailText(task.details['plan']) case final value?)
                      _MetaChip(label: _planLabel, value: value),
                    if (_detailText(task.details['fact']) case final value?)
                      _MetaChip(label: _factLabel, value: value),
                    if (busy)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<int?>(
            tooltip: _moveTooltip,
            enabled: !busy && destinationFolders.isNotEmpty,
            onSelected: (parentId) {
              final destination = destinationFolders.firstWhere(
                (folder) => folder.parentId == parentId,
              );
              context.read<BoardBloc>().add(
                    BoardTaskMoved(
                      task: task,
                      targetParentId: destination.parentId,
                      targetIndex: destination.tasks.length,
                    ),
                  );
            },
            itemBuilder: (context) => [
              for (final folder in destinationFolders)
                PopupMenuItem<int?>(
                  value: folder.parentId,
                  child: Text(folder.title),
                ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(4),
              child:
                  Icon(Icons.drive_file_move_outline, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: busy ? 0.72 : 1,
      child: busy
          ? card
          : Draggable<KanbanTask>(
              data: task,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(width: 320, child: card),
              ),
              childWhenDragging: Opacity(opacity: 0.28, child: card),
              child: card,
            ),
    );
  }
}

String? _detailText(Object? value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') {
    return null;
  }

  return text;
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.white,
            ),
      ),
    );
  }
}
