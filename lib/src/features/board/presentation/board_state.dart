import 'package:equatable/equatable.dart';

import '../domain/board_column.dart';
import '../domain/kanban_task.dart';
import '../domain/server_message.dart';

class BoardState extends Equatable {
  const BoardState({
    required this.isLoading,
    required this.isDemo,
    required this.columns,
    required this.tasks,
    required this.messages,
    required this.busyTaskIds,
    this.fatalError,
  });

  const BoardState.initial()
      : isLoading = false,
        isDemo = false,
        columns = const [],
        tasks = const [],
        messages = const [],
        busyTaskIds = const {},
        fatalError = null;

  final bool isLoading;
  final bool isDemo;
  final String? fatalError;
  final List<BoardColumn> columns;
  final List<KanbanTask> tasks;
  final List<ServerMessage> messages;
  final Set<int> busyTaskIds;

  BoardState copyWith({
    bool? isLoading,
    bool? isDemo,
    String? fatalError,
    bool clearFatalError = false,
    List<BoardColumn>? columns,
    List<KanbanTask>? tasks,
    List<ServerMessage>? messages,
    Set<int>? busyTaskIds,
  }) {
    return BoardState(
      isLoading: isLoading ?? this.isLoading,
      isDemo: isDemo ?? this.isDemo,
      fatalError: clearFatalError ? null : (fatalError ?? this.fatalError),
      columns: columns ?? this.columns,
      tasks: tasks ?? this.tasks,
      messages: messages ?? this.messages,
      busyTaskIds: busyTaskIds ?? this.busyTaskIds,
    );
  }

  bool isTaskBusy(int taskId) => busyTaskIds.contains(taskId);

  @override
  List<Object?> get props => [
        isLoading,
        isDemo,
        fatalError,
        columns,
        tasks,
        messages,
        busyTaskIds.toList()..sort(),
      ];
}
