class InspectionSealLog {
  final String id;
  final String tamperSealId;
  final String? scannedBy;
  final String? scannedByName;
  final String scanStage; // INITIAL_SEAL, CARRIER_HANDOVER, DELIVERED_BUYER, SELLER_TO_CENTER, CENTER_RECEIVE, RETURN_TO_SELLER
  final String sealCondition; // INTACT, TAMPERED
  final String? locationText;
  final double? latitude;
  final double? longitude;
  final String? note;
  final DateTime scannedAt;

  InspectionSealLog({
    required this.id,
    required this.tamperSealId,
    this.scannedBy,
    this.scannedByName,
    required this.scanStage,
    required this.sealCondition,
    this.locationText,
    this.latitude,
    this.longitude,
    this.note,
    required this.scannedAt,
  });

  factory InspectionSealLog.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả key stage (BE docs) và scanStage (DTO response)
    final stageRaw = json['stage'] ?? json['scanStage'] ?? 'INITIAL_SEAL';
    final noteRaw = json['notes'] ?? json['note'];

    double? parseCoord(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return InspectionSealLog(
      id: json['id']?.toString() ?? '',
      tamperSealId: json['tamperSealId'] ?? '',
      scannedBy: json['scannedBy']?.toString(),
      scannedByName: json['scannedByName'],
      scanStage: stageRaw.toString(),
      sealCondition: json['sealCondition'] ?? 'INTACT',
      locationText: json['locationText'],
      latitude: parseCoord(json['latitude']),
      longitude: parseCoord(json['longitude']),
      note: noteRaw?.toString(),
      scannedAt: json['scannedAt'] != null
          ? DateTime.tryParse(json['scannedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get scanStageLabel {
    switch (scanStage) {
      case 'INITIAL_SEAL':
        return 'Dán tem niêm phong ban đầu (KTV)';
      case 'SELLER_TO_CENTER':
        return 'Người bán bàn giao gửi tới Hub';
      case 'CENTER_RECEIVE':
        return 'Hub tiếp nhận niêm phong & lưu kho';
      case 'CARRIER_HANDOVER':
        return 'Bàn giao tài xế vận chuyển';
      case 'DELIVERED_BUYER':
        return 'Giao tận tay người mua & kiểm tra tem';
      case 'RETURN_TO_SELLER':
        return 'Hoàn trả hàng về cho người bán';
      default:
        return scanStage;
    }
  }

  bool get isIntact => sealCondition.toUpperCase() == 'INTACT';
  bool get hasCoordinates => latitude != null && longitude != null;
}

class InspectionSealVerification {
  final String tamperSealId;
  final String? inspectionOrderId;
  final String? postId;
  final String productTitle;
  final String? productImageUrl; // [MỚI] Ảnh sản phẩm từ BE
  final String? productModel;
  final String? productBrand;
  final int conditionScore;
  final String conditionGrade;
  final String inspectionStatus;
  final String? inspectionCenterName;
  final String? inspectorName;
  final DateTime? inspectedAt;
  final String currentSealStatus; // INTACT, TAMPERED
  final bool isOfficialSecondLifeSeal;
  final String? reportSummary;
  final List<InspectionSealLog> scanHistory;

  InspectionSealVerification({
    required this.tamperSealId,
    this.inspectionOrderId,
    this.postId,
    required this.productTitle,
    this.productImageUrl,
    this.productModel,
    this.productBrand,
    required this.conditionScore,
    required this.conditionGrade,
    required this.inspectionStatus,
    this.inspectionCenterName,
    this.inspectorName,
    this.inspectedAt,
    required this.currentSealStatus,
    required this.isOfficialSecondLifeSeal,
    this.reportSummary,
    this.scanHistory = const [],
  });

  factory InspectionSealVerification.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ scanLogs và scanHistory
    final rawLogs = json['scanLogs'] ?? json['scanHistory'];
    final historyList = (rawLogs as List<dynamic>?)
            ?.map((e) => InspectionSealLog.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final orderId = json['orderId'] ?? json['inspectionOrderId'];
    final center = json['centerName'] ?? json['inspectionCenterName'];
    final inspector = json['sealedByName'] ?? json['inspectorName'];
    final inspectedTimeRaw = json['sealedAt'] ?? json['inspectedAt'];
    final statusRaw = json['status'] ?? json['inspectionStatus'] ?? 'PASSED';

    return InspectionSealVerification(
      tamperSealId: json['tamperSealId'] ?? '',
      inspectionOrderId: orderId?.toString(),
      postId: json['postId']?.toString(),
      productTitle: json['productTitle'] ?? 'Sản phẩm kiểm định SecondLife',
      productImageUrl: json['productImageUrl']?.toString(),
      productModel: json['productModel'],
      productBrand: json['productBrand'],
      conditionScore: (json['conditionScore'] as num?)?.toInt() ?? 90,
      conditionGrade: json['conditionGrade'] ?? 'A',
      inspectionStatus: statusRaw.toString(),
      inspectionCenterName: center?.toString() ?? 'Trung tâm Kỹ thuật SecondLife HCM',
      inspectorName: inspector?.toString() ?? 'KTV Chuyên nghiệp',
      inspectedAt: inspectedTimeRaw != null
          ? DateTime.tryParse(inspectedTimeRaw.toString())
          : null,
      currentSealStatus: json['currentSealStatus'] ?? 'INTACT',
      isOfficialSecondLifeSeal: json['isOfficialSecondLifeSeal'] ?? true,
      reportSummary: json['reportSummary']?.toString(),
      scanHistory: historyList,
    );
  }

  bool get isIntact => currentSealStatus.toUpperCase() == 'INTACT';
}
