import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  static const String appName = 'SecondLife Expert';
  static const String appVersion = '1.0.0';

  static const String _storageKey = 'sl_custom_base_url';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static String? _customBaseUrl;

  /// Tự động load URL máy chủ đã lưu từ bộ nhớ an toàn khi khởi chạy app
  static Future<void> init() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null && saved.trim().isNotEmpty) {
        if (saved.contains('127.0.0.1') || saved.contains('10.0.2.2')) {
          await _storage.delete(key: _storageKey);
          _customBaseUrl = null;
        } else {
          _customBaseUrl = _cleanUrl(saved.trim());
        }
      }
    } catch (_) {}
  }

  /// Cập nhật và lưu bền vững URL máy chủ (hỗ trợ Ngrok HTTPS, IP nội bộ, USB)
  static Future<void> setCustomBaseUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      _customBaseUrl = null;
      try {
        await _storage.delete(key: _storageKey);
      } catch (_) {}
      return;
    }

    final cleaned = _cleanUrl(url.trim());
    _customBaseUrl = cleaned;
    try {
      await _storage.write(key: _storageKey, value: cleaned);
    } catch (_) {}
  }

  static String _cleanUrl(String raw) {
    var url = raw.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  /// Default API Origin (can be overridden with --dart-define=API_BASE_URL=...)
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    const definedUrl = String.fromEnvironment('API_BASE_URL');
    if (definedUrl.isNotEmpty) {
      return _cleanUrl(definedUrl);
    }

    // Default to active Ngrok tunnel for remote & mobile testing
    return 'https://clinking-slicing-visibly.ngrok-free.dev';
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
