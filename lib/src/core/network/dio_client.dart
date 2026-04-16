import 'package:dio/dio.dart';

class DioClient {
  DioClient()
      : dio = Dio(
          BaseOptions(
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            responseType: ResponseType.plain,
            validateStatus: (_) => true,
          ),
        );

  final Dio dio;
}
