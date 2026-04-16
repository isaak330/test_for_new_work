import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/colors/app_colors.dart';
import '../../domain/board_column.dart';
import '../../domain/kanban_task.dart';
import '../board_bloc.dart';
import '../board_event.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.busy,
    required this.currentParentId,
    required this.allColumns,
    super.key,
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
                    MetaChip(label: _orderLabel, value: '${task.order}'),
                    MetaChip(label: _idLabel, value: '${task.id}'),
                    if (_detailText(task.details['author']) case final value?)
                      MetaChip(label: _authorLabel, value: value),
                    if (_detailText(task.details['type']) case final value?)
                      MetaChip(label: _typeLabel, value: value),
                    if (_detailText(task.details['plan']) case final value?)
                      MetaChip(label: _planLabel, value: value),
                    if (_detailText(task.details['fact']) case final value?)
                      MetaChip(label: _factLabel, value: value),
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

class MetaChip extends StatelessWidget {
  const MetaChip({
    required this.label,
    required this.value,
    super.key,
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
