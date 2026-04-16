import 'package:flutter_test/flutter_test.dart';
import 'package:test_for_new_work/src/features/board/data/board_repository.dart';
import 'package:test_for_new_work/src/features/board/domain/kanban_task.dart';

void main() {
  test('buildColumnsFromTasks uses folder task names as column titles', () {
    final tasks = normalizeTasks(const [
      KanbanTask(id: 1, parentId: null, name: 'Новые', order: 1),
      KanbanTask(id: 2, parentId: null, name: 'В работе', order: 2),
      KanbanTask(id: 101, parentId: 1, name: 'Проверить отчёт', order: 2),
      KanbanTask(id: 102, parentId: 1, name: 'Подтвердить встречу', order: 1),
      KanbanTask(id: 103, parentId: 2, name: 'Собрать данные', order: 1),
    ]);

    final columns = buildColumnsFromTasks(tasks);

    expect(columns.map((column) => column.title), ['Новые', 'В работе']);
    expect(columns.first.tasks.map((task) => task.name), [
      'Подтвердить встречу',
      'Проверить отчёт',
    ]);
    expect(columns[1].tasks.single.name, 'Собрать данные');
  });
}
