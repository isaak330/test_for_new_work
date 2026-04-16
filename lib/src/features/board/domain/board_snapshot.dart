import 'package:equatable/equatable.dart';

import 'board_column.dart';
import 'kanban_task.dart';
import 'server_message.dart';

class BoardSnapshot extends Equatable {
  const BoardSnapshot({
    required this.columns,
    required this.rawTasks,
    required this.messages,
    required this.isDemo,
  });

  final List<BoardColumn> columns;
  final List<KanbanTask> rawTasks;
  final List<ServerMessage> messages;
  final bool isDemo;

  @override
  List<Object?> get props => [columns, rawTasks, messages, isDemo];
}
