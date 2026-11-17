class ApiEndpoints {
  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String me = '/api/v1/users/me';

  // Inspector Execution Station
  static const String myAssignedOrders = '/api/v1/inspector/orders';
  static String orderChecklist(String orderId) => '/api/v1/inspector/orders/$orderId/checklist';
  static String scheduleAppointment(String orderId) => '/api/v1/inspector/orders/$orderId/schedule';
  static String startInspection(String orderId) => '/api/v1/inspector/orders/$orderId/start';
  static String submitResult(String orderId) => '/api/v1/inspector/orders/$orderId/result';
  static String submitReport(String orderId) => '/api/v1/inspector/orders/$orderId/result';
  static String generateSeal(String orderId) => '/api/v1/inspector/orders/$orderId/generate-seal';

  // Media Uploads
  static const String mediaUpload = '/api/v1/media/upload';
  static const String mediaUploadMultiple = '/api/v1/media/upload-multiple';
  static const String mediaUploadVideo = '/api/v1/media/upload-video';
  static const String inspectionProofsFolder = 'secondlife/inspections/proofs';

  // Inspection & Tamper Seal Public / General
  static String orderDetails(String orderId) => '/api/v1/inspection/orders/$orderId';
  static String sealVerification(String tamperSealId) => '/api/v1/inspection/seal/$tamperSealId';
  static const String recordSealScan = '/api/v1/inspection/seal/scan';

  // Notifications, Chats & Wallet
  static const String notifications = '/api/v1/notifications';
  static String markNotificationRead(String id) => '/api/v1/notifications/$id/read';
  static const String markAllNotificationsRead = '/api/v1/notifications/read-all';
  static const String chats = '/api/v1/chats';
  static String chatMessages(String roomId) => '/api/v1/chats/$roomId/messages';
  static const String myWallet = '/api/v1/wallets/me';
  static const String myWalletTransactions = '/api/v1/wallets/me/transactions';
}
