import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService storage;

  final _sessionExpiredController = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  ApiClient({SecureStorageService? storageService})
      : storage = storageService ?? SecureStorageService() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_createAuthInterceptor());
  }

  QueuedInterceptor _createAuthInterceptor() {
    return QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        options.baseUrl = AppConfig.baseUrl;

        final path = options.path;
        if (!path.startsWith('/api/v1/auth/login') &&
            !path.startsWith('/api/v1/auth/register')) {
          final token = await storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          _sessionExpiredController.add(null);
        } else if (error.response?.statusCode == 429) {
          // Xử lý Rate Limiting khi tra cứu / quét tem quá 30 req / phút
          final customError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: 'Bạn đang thao tác quá nhanh trên hệ thống tem niêm phong. Vui lòng thử lại sau 1 phút.',
            message: 'Bạn đang thao tác quá nhanh trên hệ thống tem niêm phong. Vui lòng thử lại sau 1 phút.',
          );
          return handler.next(customError);
        }
        return handler.next(error);
      },
    );
  }

  void dispose() {
    _sessionExpiredController.close();
  }
}
