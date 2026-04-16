import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _defaultPort = 8080;
const _defaultToken = '5c3964b8e3ee4755f2cc0febb851e2f8';
const _defaultRequestedMoId = 42;
const _defaultAuthUserId = 40;
const _defaultPeriodStart = '2026-04-01';
const _defaultPeriodEnd = '2026-04-30';
const _defaultPeriodKey = 'month';
const _upstreamBaseUrl = 'https://api.dev.kpi-drive.ru';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? _defaultPort;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  stdout.writeln('Serving KPI Drive board at http://localhost:$port');

  await for (final request in server) {
    unawaited(_handleRequest(request));
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  try {
    final path = request.uri.path;
    if (request.method == 'GET' && path == '/api/tasks') {
      await _handleGetTasks(request);
      return;
    }

    if (request.method == 'POST' && path == '/api/tasks/move') {
      await _handleMoveTask(request);
      return;
    }

    if (request.method == 'GET') {
      await _serveStatic(request);
      return;
    }

    await _writeJson(
      request.response,
      HttpStatus.methodNotAllowed,
      {
        'status': 'METHOD_NOT_ALLOWED',
        'messages': {
          'error': ['Метод ${request.method} не поддерживается.'],
          'warning': <String>[],
          'info': <String>[],
        },
        'data': null,
      },
    );
  } catch (error, stackTrace) {
    stderr.writeln('$error\n$stackTrace');
    await _writeJson(
      request.response,
      HttpStatus.internalServerError,
      {
        'status': 'INTERNAL_ERROR',
        'messages': {
          'error': ['Локальный proxy завершился с ошибкой.'],
          'warning': <String>[],
          'info': <String>[],
        },
        'data': null,
      },
    );
  }
}

Future<void> _handleGetTasks(HttpRequest request) async {
  final proxy = _KpiDriveProxy();
  final upstream = await proxy.fetchTasks();

  final rawData = upstream.data;
  final data = switch (rawData) {
    List<dynamic> value => value,
    Map<String, dynamic> value when value['rows'] is List =>
      value['rows'] as List<dynamic>,
    _ => const <Object?>[],
  };
  final rows = data.whereType<Map<String, dynamic>>().toList(growable: false);

  await _writeJson(
    request.response,
    upstream.httpStatus,
    {
      'status': upstream.status,
      'messages': upstream.messages,
      'data': rows,
    },
  );
}

Future<void> _handleMoveTask(HttpRequest request) async {
  final payload =
      jsonDecode(await utf8.decodeStream(request)) as Map<String, dynamic>;
  final taskId = _asInt(payload['taskId']);
  final parentId = _asInt(payload['parentId']);
  final order = _asInt(payload['order']);

  if (taskId == null || order == null || order < 1) {
    await _writeJson(
      request.response,
      HttpStatus.badRequest,
      {
        'status': 'VALIDATION_ERROR',
        'messages': {
          'error': ['Нужны корректные taskId и order.'],
          'warning': <String>[],
          'info': <String>[],
        },
        'data': null,
      },
    );
    return;
  }

  final proxy = _KpiDriveProxy();
  final upstream = await proxy.moveTask(
    taskId: taskId,
    parentId: parentId,
    order: order,
  );

  await _writeJson(
    request.response,
    upstream.httpStatus,
    {
      'status': upstream.status,
      'messages': upstream.messages,
      'data': null,
    },
  );
}

Future<void> _serveStatic(HttpRequest request) async {
  final baseDir = Directory('build/web');
  if (!baseDir.existsSync()) {
    request.response.statusCode = HttpStatus.serviceUnavailable;
    request.response.headers.contentType = ContentType(
      'text',
      'html',
      charset: 'utf-8',
    );
    request.response.write('''
<!doctype html>
<html lang="ru">
  <body style="font-family: sans-serif; padding: 24px">
    <h1>Web build не найден</h1>
    <p>Сначала выполните <code>flutter build web</code>, затем снова запустите <code>dart run tool/web_server.dart</code>.</p>
  </body>
</html>
''');
    await request.response.close();
    return;
  }

  final requestedPath =
      request.uri.path == '/' ? '/index.html' : request.uri.path;
  final sanitized = requestedPath.startsWith('/')
      ? requestedPath.substring(1)
      : requestedPath;
  var file = File('${baseDir.path}/$sanitized');

  if (!file.existsSync()) {
    if (!requestedPath.contains('.')) {
      file = File('${baseDir.path}/index.html');
    } else {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
  }

  request.response.headers.contentType = _contentTypeFor(file.path);
  await request.response.addStream(file.openRead());
  await request.response.close();
}

ContentType _contentTypeFor(String path) {
  if (path.endsWith('.html')) {
    return ContentType('text', 'html', charset: 'utf-8');
  }
  if (path.endsWith('.js')) {
    return ContentType('application', 'javascript', charset: 'utf-8');
  }
  if (path.endsWith('.css')) {
    return ContentType('text', 'css', charset: 'utf-8');
  }
  if (path.endsWith('.json')) {
    return ContentType('application', 'json', charset: 'utf-8');
  }
  if (path.endsWith('.png')) {
    return ContentType('image', 'png');
  }
  if (path.endsWith('.svg')) {
    return ContentType('image', 'svg+xml');
  }
  if (path.endsWith('.wasm')) {
    return ContentType('application', 'wasm');
  }

  return ContentType.binary;
}

Future<void> _writeJson(
  HttpResponse response,
  int statusCode,
  Map<String, Object?> payload,
) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType(
    'application',
    'json',
    charset: 'utf-8',
  );
  response.write(jsonEncode(payload));
  await response.close();
}

int? _asInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
}

class _KpiDriveProxy {
  final HttpClient _httpClient = HttpClient();

  Future<_UpstreamResponse> fetchTasks() async {
    return _postMultipart(
      endpoint: '/_api/indicators/get_mo_indicators',
      fields: [
        MapEntry('period_start', _periodStart),
        MapEntry('period_end', _periodEnd),
        MapEntry('period_key', _periodKey),
        MapEntry('requested_mo_id', '$_requestedMoId'),
        const MapEntry<String, String>('behaviour_with_key', 'task,kpi'),
        const MapEntry<String, String>('result', 'false'),
        MapEntry('auth_user_id', '$_authUserId'),
      ],
    );
  }

  Future<_UpstreamResponse> moveTask({
    required int taskId,
    required int? parentId,
    required int order,
  }) async {
    final attempts = <Future<_UpstreamResponse> Function()>[
      () => _moveWithRepeatedFieldPairs(taskId, parentId, order),
      () => _moveWithFieldArray(taskId, parentId, order),
      () => _moveWithSeparateCalls(taskId, parentId, order),
    ];

    late _UpstreamResponse lastResponse;
    for (final attempt in attempts) {
      lastResponse = await attempt();
      if (lastResponse.status == 'OK') {
        return lastResponse;
      }
    }

    return lastResponse;
  }

  Future<_UpstreamResponse> _moveWithRepeatedFieldPairs(
    int taskId,
    int? parentId,
    int order,
  ) {
    return _postMultipart(
      endpoint: '/_api/indicators/save_indicator_instance_field',
      fields: [
        MapEntry('period_start', _periodStart),
        MapEntry('period_end', _periodEnd),
        MapEntry('period_key', _periodKey),
        MapEntry('indicator_to_mo_id', '$taskId'),
        const MapEntry('field_name', 'parent_id'),
        MapEntry('field_value', '${parentId ?? ''}'),
        const MapEntry('field_name', 'order'),
        MapEntry('field_value', '$order'),
        MapEntry('auth_user_id', '$_authUserId'),
      ],
    );
  }

  Future<_UpstreamResponse> _moveWithFieldArray(
    int taskId,
    int? parentId,
    int order,
  ) {
    return _postMultipart(
      endpoint: '/_api/indicators/save_indicator_instance_field',
      fields: [
        MapEntry('period_start', _periodStart),
        MapEntry('period_end', _periodEnd),
        MapEntry('period_key', _periodKey),
        MapEntry('indicator_to_mo_id', '$taskId'),
        const MapEntry('field[0][name]', 'parent_id'),
        MapEntry('field[0][value]', '${parentId ?? ''}'),
        const MapEntry('field[1][name]', 'order'),
        MapEntry('field[1][value]', '$order'),
        MapEntry('auth_user_id', '$_authUserId'),
      ],
    );
  }

  Future<_UpstreamResponse> _moveWithSeparateCalls(
    int taskId,
    int? parentId,
    int order,
  ) async {
    final parentResponse = await _postMultipart(
      endpoint: '/_api/indicators/save_indicator_instance_field',
      fields: [
        MapEntry('period_start', _periodStart),
        MapEntry('period_end', _periodEnd),
        MapEntry('period_key', _periodKey),
        MapEntry('indicator_to_mo_id', '$taskId'),
        const MapEntry('field_name', 'parent_id'),
        MapEntry('field_value', '${parentId ?? ''}'),
        MapEntry('auth_user_id', '$_authUserId'),
      ],
    );

    if (parentResponse.status != 'OK') {
      return parentResponse;
    }

    return _postMultipart(
      endpoint: '/_api/indicators/save_indicator_instance_field',
      fields: [
        MapEntry('period_start', _periodStart),
        MapEntry('period_end', _periodEnd),
        MapEntry('period_key', _periodKey),
        MapEntry('indicator_to_mo_id', '$taskId'),
        const MapEntry('field_name', 'order'),
        MapEntry('field_value', '$order'),
        MapEntry('auth_user_id', '$_authUserId'),
      ],
    );
  }

  Future<_UpstreamResponse> _postMultipart({
    required String endpoint,
    required List<MapEntry<String, String>> fields,
  }) async {
    final boundary =
        '----dartFormBoundary${DateTime.now().microsecondsSinceEpoch}';
    final request =
        await _httpClient.postUrl(Uri.parse('$_upstreamBaseUrl$endpoint'));
    request.headers
        .set(HttpHeaders.authorizationHeader, 'Bearer $_bearerToken');
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );
    request.write(_encodeMultipart(fields, boundary));

    final response = await request.close();
    final rawBody = await utf8.decodeStream(response);
    final decoded = rawBody.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(rawBody) as Map<String, dynamic>;

    return _UpstreamResponse(
      httpStatus: response.statusCode,
      status: decoded['STATUS'] as String? ?? 'UNKNOWN',
      messages: _normalizeMessages(decoded['MESSAGES']),
      data: decoded['DATA'],
    );
  }

  String _encodeMultipart(
    List<MapEntry<String, String>> fields,
    String boundary,
  ) {
    final buffer = StringBuffer();
    for (final field in fields) {
      buffer
        ..write('--$boundary\r\n')
        ..write(
          'Content-Disposition: form-data; name="${field.key}"\r\n\r\n',
        )
        ..write(field.value)
        ..write('\r\n');
    }
    buffer.write('--$boundary--\r\n');
    return buffer.toString();
  }

  String get _bearerToken =>
      Platform.environment['KPI_BEARER_TOKEN'] ?? _defaultToken;

  int get _requestedMoId =>
      int.tryParse(Platform.environment['KPI_REQUESTED_MO_ID'] ?? '') ??
      _defaultRequestedMoId;

  int get _authUserId =>
      int.tryParse(Platform.environment['KPI_AUTH_USER_ID'] ?? '') ??
      _defaultAuthUserId;

  String get _periodStart =>
      Platform.environment['KPI_PERIOD_START'] ?? _defaultPeriodStart;

  String get _periodEnd =>
      Platform.environment['KPI_PERIOD_END'] ?? _defaultPeriodEnd;

  String get _periodKey =>
      Platform.environment['KPI_PERIOD_KEY'] ?? _defaultPeriodKey;
}

Map<String, List<String>> _normalizeMessages(Object? rawMessages) {
  final normalized = <String, List<String>>{
    'error': <String>[],
    'warning': <String>[],
    'info': <String>[],
  };

  if (rawMessages is! Map<String, dynamic>) {
    return normalized;
  }

  for (final key in normalized.keys) {
    final rawList = rawMessages[key];
    if (rawList is! List) {
      continue;
    }

    normalized[key] = rawList
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  return normalized;
}

class _UpstreamResponse {
  const _UpstreamResponse({
    required this.httpStatus,
    required this.status,
    required this.messages,
    required this.data,
  });

  final int httpStatus;
  final String status;
  final Map<String, List<String>> messages;
  final Object? data;
}
