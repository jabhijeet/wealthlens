import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

class DioClient {
  static Dio create({
    String? baseUrl,
    Map<String, dynamic>? headers,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
    int retryAttempts = 3,
    List<Duration> retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        headers: headers,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );

    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        retries: retryAttempts,
        retryDelays: retryDelays,
      ),
    );

    return dio;
  }
}
