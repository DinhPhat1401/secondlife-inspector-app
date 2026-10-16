import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final String inspectorId;
  final String inspectorName;
  final String email;
  final String badgeTitle;
  final double rating;
  final int completedJobs;
  final double monthlyEarnings;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
    this.inspectorId = '',
    this.inspectorName = '',
    this.email = '',
    this.badgeTitle = 'Kỹ Thuật Viên Kiểm Định',
    this.rating = 0.0,
    this.completedJobs = 0,
    this.monthlyEarnings = 0.0,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    String? inspectorId,
    String? inspectorName,
    String? email,
    String? badgeTitle,
    double? rating,
    int? completedJobs,
    double? monthlyEarnings,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      email: email ?? this.email,
      badgeTitle: badgeTitle ?? this.badgeTitle,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final SecureStorageService _storage = SecureStorageService();
  final ApiClient _apiClient = ApiClient();

  @override
  AuthState build() {
    _loadStoredSession();
    return const AuthState();
  }

  Future<void> _loadStoredSession() async {
    final token = await _storage.getAccessToken();
    final user = await _storage.getUser();
    if (token != null) {
      if (user != null) {
        state = state.copyWith(
          isAuthenticated: true,
          email: user['email'] ?? state.email,
          inspectorId: user['id']?.toString() ?? state.inspectorId,
          inspectorName: user['fullName'] ?? user['name'] ?? state.inspectorName,
        );
      } else {
        state = state.copyWith(isAuthenticated: true);
      }
      await fetchProfile();
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.me);
      final raw = response.data;
      final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      if (data is Map<String, dynamic>) {
        state = state.copyWith(
          inspectorId: data['id']?.toString() ?? state.inspectorId,
          inspectorName: data['fullName'] ?? data['name'] ?? state.inspectorName,
          email: data['email'] ?? state.email,
        );
        await _storage.saveUser(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final raw = response.data;
      final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;

      String? token;
      String? refreshToken;
      Map<String, dynamic> userMap = {};

      if (data is Map<String, dynamic>) {
        token = data['accessToken'] ?? data['token'];
        refreshToken = data['refreshToken'];
        if (data['user'] is Map<String, dynamic>) {
          userMap = data['user'] as Map<String, dynamic>;
        } else {
          userMap = data;
        }
      }

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Phản hồi từ máy chủ không hợp lệ: thiếu mã truy cập',
        );
        return false;
      }

      await _storage.saveTokens(
        accessToken: token,
        refreshToken: refreshToken,
      );

      final resolvedName = userMap['fullName'] ?? userMap['name'] ?? email;
      final resolvedId = userMap['id']?.toString() ?? '';

      await _storage.saveUser({
        'id': resolvedId,
        'email': email,
        'fullName': resolvedName,
        'role': 'INSPECTOR',
      });

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        email: email,
        inspectorId: resolvedId,
        inspectorName: resolvedName,
      );

      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email hoặc mật khẩu không chính xác hoặc lỗi kết nối máy chủ.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {}
    await _storage.clearAuth();
    state = const AuthState(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
