import 'package:equatable/equatable.dart';

import 'kanban_task.dart';

class BoardColumn extends Equatable {
  const BoardColumn({
    required this.parentId,
    required this.title,
    required this.tasks,
  });

  final int? parentId;
  final String title;
  final List<KanbanTask> tasks;

  @override
  List<Object?> get props => [parentId, title, tasks];
}
