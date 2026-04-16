import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/board_repository.dart';
import '../domain/board_column.dart';
import '../domain/board_snapshot.dart';
import '../domain/kanban_task.dart';
import '../domain/server_message.dart';

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

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  BoardBloc({required BoardRepository repository})
      : _repository = repository,
        super(const BoardState.initial()) {
    on<BoardLoadRequested>(_onLoadRequested);
    on<BoardTaskMoved>(_onTaskMoved);
  }

  final BoardRepository _repository;

  Future<void> _onLoadRequested(
    BoardLoadRequested event,
    Emitter<BoardState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearFatalError: true,
      ),
    );

    try {
      final snapshot = await _repository.loadBoard(demo: event.demo);
      final fatalError = !event.demo && snapshot.columns.isEmpty
          ? _buildLoadErrorMessage(snapshot.messages)
          : null;
      emit(
        _stateFromSnapshot(snapshot).copyWith(
          isLoading: false,
          fatalError: fatalError,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          isDemo: event.demo,
          columns: const [],
          tasks: const [],
          messages: const [],
          busyTaskIds: const {},
          fatalError:
              'Не удалось загрузить доску. Проверьте локальный proxy и backend.',
        ),
      );
    }
  }

  Future<void> _onTaskMoved(
    BoardTaskMoved event,
    Emitter<BoardState> emit,
  ) async {
    if (state.busyTaskIds.contains(event.task.id)) {
      emit(
        state.copyWith(
          messages: const [
            ServerMessage(
              level: ServerMessageLevel.warning,
              text: 'Эта задача уже сохраняется. Дождитесь ответа сервера.',
            ),
          ],
        ),
      );
      return;
    }

    final currentColumn = state.columns.firstWhere(
      (column) => column.tasks.any((item) => item.id == event.task.id),
      orElse: () => const BoardColumn(parentId: null, title: '', tasks: []),
    );
    final currentIndex =
        currentColumn.tasks.indexWhere((item) => item.id == event.task.id);
    final rawTargetIndex = event.targetIndex.clamp(
      0,
      _taskCountForParent(state.tasks, event.targetParentId),
    );
    final normalizedTargetIndex =
        currentColumn.parentId == event.targetParentId &&
                currentIndex != -1 &&
                rawTargetIndex > currentIndex
            ? rawTargetIndex - 1
            : rawTargetIndex;

    if (currentColumn.parentId == event.targetParentId &&
        currentIndex == normalizedTargetIndex) {
      return;
    }

    final previousState = state;
    final busyIds = {...state.busyTaskIds, event.task.id};
    final updatedTasks = _reorderTasks(
      tasks: state.tasks,
      taskId: event.task.id,
      targetParentId: event.targetParentId,
      targetIndex: normalizedTargetIndex,
    );

    emit(
      state.copyWith(
        tasks: updatedTasks,
        columns: buildColumnsFromTasks(updatedTasks),
        messages: const [],
        busyTaskIds: busyIds,
      ),
    );

    if (state.isDemo) {
      emit(
        state.copyWith(
          busyTaskIds: {...state.busyTaskIds}..remove(event.task.id),
          messages: const [
            ServerMessage(
              level: ServerMessageLevel.info,
              text:
                  'Демо-режим: задача перемещена локально без сохранения на backend.',
            ),
          ],
        ),
      );
      return;
    }

    try {
      final movedTask =
          updatedTasks.firstWhere((item) => item.id == event.task.id);
      final serverMessages = await _repository.moveTask(
        taskId: event.task.id,
        parentId: movedTask.parentId,
        order: movedTask.order,
      );
      emit(
        state.copyWith(
          busyTaskIds: {...state.busyTaskIds}..remove(event.task.id),
          messages: serverMessages,
        ),
      );
    } on BoardMutationException catch (error) {
      emit(
        previousState.copyWith(
          messages: error.messages,
          busyTaskIds: {...previousState.busyTaskIds}..remove(event.task.id),
        ),
      );
    }
  }

  BoardState _stateFromSnapshot(BoardSnapshot snapshot) {
    return BoardState(
      isLoading: false,
      isDemo: snapshot.isDemo,
      columns: snapshot.columns,
      tasks: snapshot.rawTasks,
      messages: snapshot.messages,
      busyTaskIds: const {},
    );
  }
}

String _buildLoadErrorMessage(List<ServerMessage> messages) {
  final rawText = messages
      .map((message) => message.text.trim())
      .where((text) => text.isNotEmpty)
      .join('\n');

  if (rawText.isNotEmpty) {
    return rawText;
  }

  return 'Сервер не вернул ни одной задачи за выбранный период.';
}

int _taskCountForParent(List<KanbanTask> tasks, int? parentId) {
  return tasks.where((task) => task.parentId == parentId).length;
}

List<KanbanTask> _reorderTasks({
  required List<KanbanTask> tasks,
  required int taskId,
  required int? targetParentId,
  required int targetIndex,
}) {
  final mutable = [...tasks];
  final movingIndex = mutable.indexWhere((task) => task.id == taskId);
  if (movingIndex == -1) {
    return tasks;
  }

  final movingTask = mutable.removeAt(movingIndex);
  final regrouped = <int?, List<KanbanTask>>{};
  for (final task in mutable) {
    regrouped.putIfAbsent(task.parentId, () => <KanbanTask>[]).add(task);
  }

  final destination = regrouped.putIfAbsent(
    targetParentId,
    () => <KanbanTask>[],
  );
  final insertIndex = targetIndex.clamp(0, destination.length);
  destination.insert(
    insertIndex,
    movingTask.copyWith(
      parentId: targetParentId,
      clearParentId: targetParentId == null,
    ),
  );

  final rebuilt = <KanbanTask>[];
  for (final entry in regrouped.entries) {
    for (var index = 0; index < entry.value.length; index++) {
      rebuilt.add(entry.value[index].copyWith(order: index + 1));
    }
  }

  rebuilt.sort((a, b) {
    final parentCompare = (a.parentId ?? -1).compareTo(b.parentId ?? -1);
    if (parentCompare != 0) {
      return parentCompare;
    }
    return a.order.compareTo(b.order);
  });

  return rebuilt;
}
