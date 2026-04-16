import '../domain/board_column.dart';
import '../domain/board_snapshot.dart';
import '../domain/kanban_task.dart';
import '../domain/server_message.dart';
import 'board_api.dart';
import 'demo_board_data.dart';

class BoardRepository {
  BoardRepository({required BoardApi api}) : _api = api;

  final BoardApi _api;

  Future<BoardSnapshot> loadBoard({bool demo = false}) async {
    if (demo) {
      return _buildSnapshot(
        buildDemoTasks(),
        const <ServerMessage>[
          ServerMessage(
            level: ServerMessageLevel.info,
            text: 'Показан демонстрационный режим без обращения к backend.',
          ),
        ],
        isDemo: true,
      );
    }

    final response = await _api.fetchTasks();
    return _buildSnapshot(
      response.tasks,
      response.messages,
      isDemo: false,
    );
  }

  Future<List<ServerMessage>> moveTask({
    required int taskId,
    required int? parentId,
    required int order,
  }) async {
    final response = await _api.moveTask(
      taskId: taskId,
      parentId: parentId,
      order: order,
    );

    if (response.ok && response.status == 'OK') {
      return response.messages;
    }

    final fallback = response.messages.isEmpty
        ? const [
            ServerMessage(
              level: ServerMessageLevel.error,
              text: 'Сервер не подтвердил перенос задачи.',
            ),
          ]
        : response.messages;

    throw BoardMutationException(fallback);
  }

  BoardSnapshot _buildSnapshot(
    List<KanbanTask> tasks,
    List<ServerMessage> messages, {
    required bool isDemo,
  }) {
    final normalized = normalizeTasks(tasks);
    final columns = buildColumnsFromTasks(normalized);

    return BoardSnapshot(
      columns: columns,
      rawTasks: normalized,
      messages: messages,
      isDemo: isDemo,
    );
  }
}

class BoardMutationException implements Exception {
  const BoardMutationException(this.messages);

  final List<ServerMessage> messages;
}

List<KanbanTask> normalizeTasks(List<KanbanTask> tasks) {
  final grouped = <int?, List<KanbanTask>>{};
  for (final task in tasks) {
    grouped.putIfAbsent(task.parentId, () => <KanbanTask>[]).add(task);
  }

  final normalized = <KanbanTask>[];
  for (final entry in grouped.entries) {
    final items = [...entry.value]..sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) {
          return orderCompare;
        }
        return a.name.compareTo(b.name);
      });

    for (var index = 0; index < items.length; index++) {
      normalized.add(items[index].copyWith(order: index + 1));
    }
  }

  normalized.sort((a, b) {
    final parentCompare = (a.parentId ?? -1).compareTo(b.parentId ?? -1);
    if (parentCompare != 0) {
      return parentCompare;
    }
    return a.order.compareTo(b.order);
  });

  return normalized;
}

List<BoardColumn> buildColumnsFromTasks(List<KanbanTask> tasks) {
  final namesById = <int, String>{
    for (final task in tasks) task.id: task.name,
  };
  final ordersById = <int, int>{
    for (final task in tasks) task.id: task.order,
  };
  final folderIds = tasks.map((task) => task.parentId).whereType<int>().toSet();
  final cardTasks =
      tasks.where((task) => !folderIds.contains(task.id)).toList();
  final grouped = <int?, List<KanbanTask>>{};

  for (final task in cardTasks) {
    grouped.putIfAbsent(task.parentId, () => <KanbanTask>[]).add(task);
  }

  for (final folderId in folderIds) {
    grouped.putIfAbsent(folderId, () => <KanbanTask>[]);
  }

  final columns = grouped.entries.map((entry) {
    final title = switch (entry.key) {
      null => 'Без папки',
      final parentId when namesById.containsKey(parentId) =>
        namesById[parentId]!,
      final parentId => 'Папка #$parentId',
    };

    final tasks = [...entry.value]..sort((a, b) => a.order.compareTo(b.order));
    return BoardColumn(parentId: entry.key, title: title, tasks: tasks);
  }).toList();

  columns.sort((a, b) {
    if (a.parentId == null && b.parentId != null) {
      return -1;
    }
    if (a.parentId != null && b.parentId == null) {
      return 1;
    }

    final leftOrder =
        a.parentId == null ? 0 : (ordersById[a.parentId] ?? 999999);
    final rightOrder =
        b.parentId == null ? 0 : (ordersById[b.parentId] ?? 999999);
    final orderCompare = leftOrder.compareTo(rightOrder);
    if (orderCompare != 0) {
      return orderCompare;
    }

    return a.title.compareTo(b.title);
  });
  return columns;
}
