import 'package:equatable/equatable.dart';

import '../domain/kanban_task.dart';

sealed class BoardEvent extends Equatable {
  const BoardEvent();

  @override
  List<Object?> get props => const [];
}

class BoardLoadRequested extends BoardEvent {
  const BoardLoadRequested({this.demo = false});

  final bool demo;

  @override
  List<Object?> get props => [demo];
}

class BoardTaskMoved extends BoardEvent {
  const BoardTaskMoved({
    required this.task,
    required this.targetParentId,
    required this.targetIndex,
  });

  final KanbanTask task;
  final int? targetParentId;
  final int targetIndex;

  @override
  List<Object?> get props => [task, targetParentId, targetIndex];
}
