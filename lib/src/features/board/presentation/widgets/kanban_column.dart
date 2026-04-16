import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/colors/app_colors.dart';
import '../../domain/board_column.dart';
import '../../domain/kanban_task.dart';
import '../board_bloc.dart';
import '../board_event.dart';
import 'column_drop_area.dart';
import 'task_card.dart';

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    required this.column,
    required this.allColumns,
    required this.busyTaskIds,
    super.key,
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
                      ? ColumnDropArea(
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
                            ColumnDropArea(
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
                              TaskCard(
                                task: column.tasks[index],
                                busy: busyTaskIds.contains(
                                  column.tasks[index].id,
                                ),
                                currentParentId: column.parentId,
                                allColumns: allColumns,
                              ),
                              ColumnDropArea(
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
