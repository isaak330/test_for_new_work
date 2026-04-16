import 'package:flutter_test/flutter_test.dart';
import 'package:test_for_new_work/src/core/network/json_http_client.dart';
import 'package:test_for_new_work/src/features/board/data/board_api.dart';
import 'package:test_for_new_work/src/features/board/data/board_repository.dart';
import 'package:test_for_new_work/src/features/board/presentation/board_bloc.dart';

void main() {
  test('bloc moves task locally in demo mode', () async {
    final repository = BoardRepository(
      api: BoardApi(client: _FakeJsonHttpClient()),
    );
    final bloc = BoardBloc(repository: repository);

    bloc.add(const BoardLoadRequested(demo: true));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final sourceTask = bloc.state.columns
        .firstWhere((column) => column.title == 'Новые задачи')
        .tasks
        .first;
    final targetColumn =
        bloc.state.columns.firstWhere((column) => column.title == 'Готово');

    bloc.add(
      BoardTaskMoved(
        task: sourceTask,
        targetParentId: targetColumn.parentId,
        targetIndex: targetColumn.tasks.length,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(bloc.state.messages.single.text, contains('Демо-режим'));
    expect(
      bloc.state.columns
          .firstWhere((column) => column.title == 'Готово')
          .tasks
          .any((task) => task.id == sourceTask.id),
      isTrue,
    );
    expect(
      bloc.state.columns
          .firstWhere((column) => column.title == 'Новые задачи')
          .tasks
          .any((task) => task.id == sourceTask.id),
      isFalse,
    );
  });
}

class _FakeJsonHttpClient implements JsonHttpClient {
  @override
  Future<JsonHttpResponse> getJson(Uri uri) {
    throw UnimplementedError();
  }

  @override
  Future<JsonHttpResponse> postJson(Uri uri, Map<String, Object?> body) {
    throw UnimplementedError();
  }
}
