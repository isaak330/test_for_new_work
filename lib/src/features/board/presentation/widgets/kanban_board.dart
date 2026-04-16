import 'package:flutter/material.dart';

import '../../../../shared/colors/app_colors.dart';
import '../../domain/board_column.dart';
import 'kanban_column.dart';

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({
    required this.columns,
    required this.busyTaskIds,
    super.key,
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
              KanbanColumn(
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
