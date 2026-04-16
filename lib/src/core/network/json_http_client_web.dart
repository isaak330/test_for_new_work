// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:convert';

import 'json_http_client.dart';

JsonHttpClient createPlatformJsonHttpClient() => _WebJsonHttpClient();

class _WebJsonHttpClient implements JsonHttpClient {
  @override
  Future<JsonHttpResponse> getJson(Uri uri) async {
    final request = await html.HttpRequest.request(
      uri.toString(),
      method: 'GET',
      requestHeaders: const {
        'Accept': 'application/json',
      },
    );

    return JsonHttpResponse(
      statusCode: request.status ?? 0,
      body: request.responseText ?? '',
    );
  }

  @override
  Future<JsonHttpResponse> postJson(Uri uri, Map<String, Object?> body) async {
    final request = await html.HttpRequest.request(
      uri.toString(),
      method: 'POST',
      sendData: jsonEncode(body),
      requestHeaders: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    return JsonHttpResponse(
      statusCode: request.status ?? 0,
      body: request.responseText ?? '',
    );
  }
}
