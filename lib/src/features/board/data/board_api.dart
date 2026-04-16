import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/kanban_task.dart';
import '../domain/server_message.dart';

class BoardApi {
  BoardApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Uri get _tasksUri => Uri.parse('/api/tasks');
  Uri get _moveUri => Uri.parse('/api/tasks/move');

  Future<BoardApiFetchResponse> fetchTasks() async {
    final response = await _dio.getUri<String>(_tasksUri);
    final json = _decodeBody(response.data ?? '');

    return BoardApiFetchResponse(
      ok: (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300,
      status: json['status'] as String? ?? 'UNKNOWN',
      messages: _parseMessages(json['messages']),
      tasks: _parseTasks(json['data']),
    );
  }

  Future<BoardApiMutationResponse> moveTask({
    required int taskId,
    required int? parentId,
    required int order,
  }) async {
    final response = await _dio.postUri<String>(
      _moveUri,
      data: {
        'taskId': taskId,
        'parentId': parentId,
        'order': order,
      },
    );
    final json = _decodeBody(response.data ?? '');

    return BoardApiMutationResponse(
      ok: (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300,
      status: json['status'] as String? ?? 'UNKNOWN',
      messages: _parseMessages(json['messages']),
    );
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return const <String, dynamic>{};
  }

  List<KanbanTask> _parseTasks(Object? data) {
    final rows = switch (data) {
      List<dynamic> value => value,
      Map<String, dynamic> value when value['rows'] is List =>
        value['rows'] as List<dynamic>,
      _ => null,
    };

    if (rows == null) {
      return const <KanbanTask>[];
    }

    return rows
        .whereType<Map<String, dynamic>>()
        .map(KanbanTask.fromJson)
        .where((task) => task.id != 0 && task.name.isNotEmpty)
        .toList(growable: false);
  }

  List<ServerMessage> _parseMessages(Object? rawMessages) {
    if (rawMessages is! Map<String, dynamic>) {
      return const <ServerMessage>[];
    }

    final messages = <ServerMessage>[];
    const levels = ['error', 'warning', 'info'];

    for (final level in levels) {
      final rawList = rawMessages[level];
      if (rawList is! List) {
        continue;
      }

      for (final item in rawList) {
        final text = item?.toString().trim() ?? '';
        if (text.isEmpty) {
          continue;
        }
        messages.add(
          ServerMessage.fromJson({
            'level': level,
            'text': text,
          }),
        );
      }
    }

    return messages;
  }
}

class BoardApiFetchResponse {
  const BoardApiFetchResponse({
    required this.ok,
    required this.status,
    required this.messages,
    required this.tasks,
  });

  final bool ok;
  final String status;
  final List<ServerMessage> messages;
  final List<KanbanTask> tasks;
}

class BoardApiMutationResponse {
  const BoardApiMutationResponse({
    required this.ok,
    required this.status,
    required this.messages,
  });

  final bool ok;
  final String status;
  final List<ServerMessage> messages;
}
