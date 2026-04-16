import 'dart:convert';
import 'dart:io';

import 'json_http_client.dart';

JsonHttpClient createPlatformJsonHttpClient() => _IoJsonHttpClient();

class _IoJsonHttpClient implements JsonHttpClient {
  final HttpClient _client = HttpClient();

  @override
  Future<JsonHttpResponse> getJson(Uri uri) async {
    final request = await _client.getUrl(uri);
    request.headers.contentType = ContentType.json;
    final response = await request.close();
    final body = await utf8.decodeStream(response);

    return JsonHttpResponse(statusCode: response.statusCode, body: body);
  }

  @override
  Future<JsonHttpResponse> postJson(Uri uri, Map<String, Object?> body) async {
    final request = await _client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));

    final response = await request.close();
    final responseBody = await utf8.decodeStream(response);

    return JsonHttpResponse(
      statusCode: response.statusCode,
      body: responseBody,
    );
  }
}
