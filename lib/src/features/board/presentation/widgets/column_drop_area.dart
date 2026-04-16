import 'package:flutter/material.dart';

import '../../../../shared/colors/app_colors.dart';
import '../../domain/kanban_task.dart';

class ColumnDropArea extends StatelessWidget {
  const ColumnDropArea({
    required this.onAccept,
    this.child,
    super.key,
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
