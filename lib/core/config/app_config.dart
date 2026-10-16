import 'dart:io';

class AppConfig {
  static const String appName = 'SecondLife Expert';
  static const String appVersion = '1.0.0';

  static String? _customBaseUrl;
  static set customBaseUrl(String? url) => _customBaseUrl = url;

  /// Default API Origin (can be overridden with --dart-define=API_BASE_URL=...)
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    const definedUrl = String.fromEnvironment('API_BASE_URL');
    if (definedUrl.isNotEmpty) {
      return definedUrl;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS || Platform.isMacOS) {
      return 'http://localhost:8080';
    }
    return 'http://localhost:8080';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
