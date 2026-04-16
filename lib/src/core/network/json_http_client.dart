import 'json_http_client_stub.dart'
    if (dart.library.io) 'json_http_client_io.dart'
    if (dart.library.html) 'json_http_client_web.dart';

abstract class JsonHttpClient {
  Future<JsonHttpResponse> getJson(Uri uri);

  Future<JsonHttpResponse> postJson(Uri uri, Map<String, Object?> body);
}

class JsonHttpResponse {
  const JsonHttpResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

JsonHttpClient createJsonHttpClient() => createPlatformJsonHttpClient();
