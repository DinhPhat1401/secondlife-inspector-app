class InspectionSealLog {
  final String id;
  final String tamperSealId;
  final String? scannedBy;
  final String? scannedByName;
  final String scanStage; // INITIAL_SEAL, CARRIER_HANDOVER, DELIVERED_BUYER
  final String sealCondition; // INTACT, TAMPERED
  final String? locationText;
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
    this.note,
    required this.scannedAt,
  });

  factory InspectionSealLog.fromJson(Map<String, dynamic> json) {
    return InspectionSealLog(
      id: json['id']?.toString() ?? '',
      tamperSealId: json['tamperSealId'] ?? '',
      scannedBy: json['scannedBy']?.toString(),
      scannedByName: json['scannedByName'],
      scanStage: json['scanStage'] ?? 'INITIAL_SEAL',
      sealCondition: json['sealCondition'] ?? 'INTACT',
      locationText: json['locationText'],
      note: json['note'],
      scannedAt: json['scannedAt'] != null
          ? DateTime.tryParse(json['scannedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get scanStageLabel {
    switch (scanStage) {
      case 'INITIAL_SEAL':
        return 'Dán tem niêm phong ban đầu (KTV)';
      case 'CARRIER_HANDOVER':
        return 'Bàn giao đơn vị vận chuyển';
      case 'DELIVERED_BUYER':
        return 'Người mua nhận hàng & kiểm tra tem';
      default:
        return scanStage;
    }
  }

  bool get isIntact => sealCondition == 'INTACT';
}

class InspectionSealVerification {
  final String tamperSealId;
  final String? inspectionOrderId;
  final String? postId;
  final String productTitle;
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
  final List<InspectionSealLog> scanHistory;

  InspectionSealVerification({
    required this.tamperSealId,
    this.inspectionOrderId,
    this.postId,
    required this.productTitle,
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
    this.scanHistory = const [],
  });

  factory InspectionSealVerification.fromJson(Map<String, dynamic> json) {
    final historyList = (json['scanHistory'] as List<dynamic>?)
            ?.map((e) => InspectionSealLog.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return InspectionSealVerification(
      tamperSealId: json['tamperSealId'] ?? '',
      inspectionOrderId: json['inspectionOrderId']?.toString(),
      postId: json['postId']?.toString(),
      productTitle: json['productTitle'] ?? 'Sản phẩm kiểm định',
      productModel: json['productModel'],
      productBrand: json['productBrand'],
      conditionScore: json['conditionScore'] is int ? json['conditionScore'] : 90,
      conditionGrade: json['conditionGrade'] ?? 'A',
      inspectionStatus: json['inspectionStatus'] ?? 'PASSED',
      inspectionCenterName: json['inspectionCenterName'] ?? 'Trung tâm Kỹ thuật SecondLife HCM',
      inspectorName: json['inspectorName'] ?? 'KTV Chuyên nghiệp',
      inspectedAt: json['inspectedAt'] != null
          ? DateTime.tryParse(json['inspectedAt'].toString())
          : null,
      currentSealStatus: json['currentSealStatus'] ?? 'INTACT',
      isOfficialSecondLifeSeal: json['isOfficialSecondLifeSeal'] ?? true,
      scanHistory: historyList,
    );
  }

  bool get isIntact => currentSealStatus == 'INTACT';
}
