import 'json_http_client.dart';

JsonHttpClient createPlatformJsonHttpClient() => _UnsupportedJsonHttpClient();

class _UnsupportedJsonHttpClient implements JsonHttpClient {
  @override
  Future<JsonHttpResponse> getJson(Uri uri) {
    throw UnsupportedError('HTTP client is not supported on this platform.');
  }

  @override
  Future<JsonHttpResponse> postJson(Uri uri, Map<String, Object?> body) {
    throw UnsupportedError('HTTP client is not supported on this platform.');
  }
}
