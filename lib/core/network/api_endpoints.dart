class ApiEndpoints {
  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String me = '/api/v1/users/me';

  // Inspector Execution Station
  static const String myAssignedOrders = '/api/v1/inspector/orders';
  static const String inspectorStats = '/api/v1/inspector/stats';
  static const String inspectorPayouts = '/api/v1/inspector/payouts';
  static String orderChecklist(String orderId) => '/api/v1/inspector/orders/$orderId/checklist';
  static String scheduleAppointment(String orderId) => '/api/v1/inspector/orders/$orderId/schedule';
  static String startInspection(String orderId) => '/api/v1/inspector/orders/$orderId/start';
  static String submitResult(String orderId) => '/api/v1/inspector/orders/$orderId/submit-report';
  static String submitReport(String orderId) => '/api/v1/inspector/orders/$orderId/submit-report';
  static String generateSeal(String orderId) => '/api/v1/inspector/orders/$orderId/generate-seal';

  // Inspection & Tamper Seal Public / General
  static String orderDetails(String orderId) => '/api/v1/inspection/orders/$orderId';
  static String sealVerification(String tamperSealId) => '/api/v1/inspection/seal/$tamperSealId';
  static const String recordSealScan = '/api/v1/inspection/seal/scan';
}
