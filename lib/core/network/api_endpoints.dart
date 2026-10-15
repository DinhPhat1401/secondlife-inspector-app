class ApiEndpoints {
  // Auth
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String me = '/api/v1/auth/me';

  // Inspector Execution Station
  static const String myAssignedOrders = '/api/v1/inspector/orders';
  static String orderChecklist(String orderId) => '/api/v1/inspector/orders/$orderId/checklist';
  static String scheduleAppointment(String orderId) => '/api/v1/inspector/orders/$orderId/schedule';
  static String startInspection(String orderId) => '/api/v1/inspector/orders/$orderId/start';
  static String submitResult(String orderId) => '/api/v1/inspector/orders/$orderId/result';

  // Inspection & Tamper Seal Public / General
  static String orderDetails(String orderId) => '/api/v1/inspection/orders/$orderId';
  static String sealVerification(String tamperSealId) => '/api/v1/inspection/seal/$tamperSealId';
  static const String recordSealScan = '/api/v1/inspection/seal/scan';
}
