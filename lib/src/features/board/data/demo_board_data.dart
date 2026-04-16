import '../domain/kanban_task.dart';

List<KanbanTask> buildDemoTasks() {
  return const [
    KanbanTask(id: 101, parentId: null, name: 'Новые задачи', order: 1),
    KanbanTask(id: 102, parentId: null, name: 'В работе', order: 2),
    KanbanTask(id: 103, parentId: null, name: 'Готово', order: 3),
    KanbanTask(
        id: 201, parentId: 101, name: 'Согласовать план продаж', order: 1),
    KanbanTask(
        id: 202, parentId: 101, name: 'Проверить входящие KPI', order: 2),
    KanbanTask(
        id: 203,
        parentId: 102,
        name: 'Подготовить презентацию для команды',
        order: 1),
    KanbanTask(
        id: 204,
        parentId: 102,
        name: 'Уточнить статусы задач у руководителей',
        order: 2),
    KanbanTask(
        id: 205,
        parentId: 103,
        name: 'Закрыть отчёт по результатам месяца',
        order: 1),
  ];
}
