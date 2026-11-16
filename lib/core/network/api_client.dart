import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient({SecureStorageService? storageService}) => _instance;

  late final Dio dio;
  late final SecureStorageService storage;

  final _sessionExpiredController = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  ApiClient._internal() {
    storage = SecureStorageService();
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    dio.interceptors.add(_createAuthInterceptor());
  }

  QueuedInterceptor _createAuthInterceptor() {
    return QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        options.baseUrl = AppConfig.baseUrl;
        options.headers['ngrok-skip-browser-warning'] = 'true';

        final path = options.path;
        if (!path.startsWith('/api/auth/')) {
          final token = await storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/api/auth/')) {
          if (error.requestOptions.extra['authRetry'] == true) {
            await storage.clearAuth();
            _sessionExpiredController.add(null);
            return handler.next(error);
          }

          final refreshToken = await storage.getRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            await storage.clearAuth();
            _sessionExpiredController.add(null);
            return handler.next(error);
          }

          try {
            final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
            final refreshResponse = await refreshDio.post(
              '/api/auth/refresh',
              data: {'refreshToken': refreshToken},
            );
            final data = refreshResponse.data;
            final payload = data is Map ? (data['data'] ?? data) : null;
            final newAccessToken = payload is Map
                ? payload['accessToken']
                : null;
            final newRefreshToken = payload is Map
                ? (payload['refreshToken'] ?? refreshToken)
                : refreshToken;
            if (newAccessToken == null || newAccessToken.toString().isEmpty) {
              throw StateError(
                'Refresh response did not include an access token',
              );
            }

            await storage.saveTokens(
              accessToken: newAccessToken.toString(),
              refreshToken: newRefreshToken.toString(),
            );
            final retryOptions = error.requestOptions.copyWith(
              headers: {
                ...error.requestOptions.headers,
                'Authorization': 'Bearer $newAccessToken',
              },
              extra: {...error.requestOptions.extra, 'authRetry': true},
            );
            return handler.resolve(await dio.fetch(retryOptions));
          } catch (_) {
            await storage.clearAuth();
            _sessionExpiredController.add(null);
          }
        } else if (error.response?.statusCode == 429) {
          // Xử lý Rate Limiting khi tra cứu / quét tem quá 30 req / phút
          final customError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error:
                'Bạn đang thao tác quá nhanh trên hệ thống tem niêm phong. Vui lòng thử lại sau 1 phút.',
            message:
                'Bạn đang thao tác quá nhanh trên hệ thống tem niêm phong. Vui lòng thử lại sau 1 phút.',
          );
          return handler.next(customError);
        }
        return handler.next(error);
      },
    );
  }

  void dispose() {
    // Keep open for app lifecycle singleton
  }
}
