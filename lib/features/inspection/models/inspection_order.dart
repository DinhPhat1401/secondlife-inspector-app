class InspectionOrder {
  final String id;
  final String? postId;
  final String postTitle;
  final List<String> postImageUrls;
  final double postPrice;

  final String? sellerId;
  final String sellerName;
  final String? sellerPhone;
  final String? sellerAddress;

  final String? buyerId;
  final String buyerName;
  final String? buyerPhone;

  final String? inspectorId;
  final String? inspectorName;

  final String orderType; // AT_HOME, AT_CENTER
  final String feePayer;
  final String status;
  final String? note;

  final double inspectionFee;
  final double travelDistanceKm;
  final double travelFee;

  final DateTime? appointmentScheduledAt;
  final String? tamperSealId;
  final String? barcode;
  final String? videoProofUrl;
  final int? conditionScore;
  final String? conditionGrade;

  final double latitude;
  final double longitude;

  InspectionOrder({
    required this.id,
    this.postId,
    required this.postTitle,
    this.postImageUrls = const [],
    required this.postPrice,
    this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    this.sellerAddress,
    this.buyerId,
    required this.buyerName,
    this.buyerPhone,
    this.inspectorId,
    this.inspectorName,
    required this.orderType,
    required this.feePayer,
    required this.status,
    this.note,
    this.inspectionFee = 0.0,
    this.travelDistanceKm = 0.0,
    this.travelFee = 0.0,
    this.appointmentScheduledAt,
    this.tamperSealId,
    this.barcode,
    this.videoProofUrl,
    this.conditionScore,
    this.conditionGrade,
    this.latitude = 10.7769,
    this.longitude = 106.7009,
  });

  factory InspectionOrder.fromJson(Map<String, dynamic> json) {
    final images = (json['postImageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return InspectionOrder(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString(),
      postTitle: json['postTitle'] ?? 'Sản phẩm kiểm định',
      postImageUrls: images,
      postPrice: (json['postPrice'] is num) ? (json['postPrice'] as num).toDouble() : 0.0,
      sellerId: json['sellerId']?.toString(),
      sellerName: json['sellerName'] ?? 'Người bán SecondLife',
      sellerPhone: json['sellerPhone'] ?? '0912 345 678',
      sellerAddress: json['sellerAddress'] ?? 'Khu Công Nghệ Cao, TP. Thủ Đức, TP. Hồ Chí Minh',
      buyerId: json['buyerId']?.toString(),
      buyerName: json['buyerName'] ?? 'Người mua SecondLife',
      buyerPhone: json['buyerPhone'] ?? '0988 765 432',
      inspectorId: json['inspectorId']?.toString(),
      inspectorName: json['inspectorName'] ?? 'KTV SecondLife',
      orderType: json['orderType']?.toString() ?? 'AT_HOME',
      feePayer: json['feePayer']?.toString() ?? 'SPLIT_50_50',
      status: json['status']?.toString() ?? 'SCHEDULED',
      note: json['note'],
      inspectionFee: (json['inspectionFee'] is num) ? (json['inspectionFee'] as num).toDouble() : 150000.0,
      travelDistanceKm: (json['travelDistanceKm'] is num) ? (json['travelDistanceKm'] as num).toDouble() : 4.5,
      travelFee: (json['travelFee'] is num) ? (json['travelFee'] as num).toDouble() : 45000.0,
      appointmentScheduledAt: json['appointmentScheduledAt'] != null
          ? DateTime.tryParse(json['appointmentScheduledAt'].toString())
          : DateTime.now().add(const Duration(hours: 2)),
      tamperSealId: json['tamperSealId'],
      barcode: json['barcode'],
      videoProofUrl: json['videoProofUrl'],
      conditionScore: json['conditionScore'] is int ? json['conditionScore'] : null,
      conditionGrade: json['conditionGrade'],
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 10.8412,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 106.8098,
    );
  }

  bool get isAtHome => orderType == 'AT_HOME';

  String get statusLabel {
    switch (status) {
      case 'WAITING_SELLER_APPROVAL':
        return 'Chờ người bán duyệt';
      case 'WAITING_FEE_PAYMENT':
        return 'Chờ ký quỹ phí';
      case 'CONFIRMED_PENDING_DISPATCH':
        return 'Chờ điều phối';
      case 'SCHEDULED':
        return 'Đã lên lịch hẹn';
      case 'SHIPPING_TO_CENTER':
        return 'Đang chuyển về TT';
      case 'INSPECTING':
        return 'Đang kiểm định';
      case 'PASSED':
        return 'Đạt chuẩn (PASSED)';
      case 'FAILED':
        return 'Không đạt (FAILED)';
      case 'COMPLETED':
        return 'Hoàn tất';
      default:
        return status;
    }
  }

  InspectionOrder copyWith({
    String? status,
    DateTime? appointmentScheduledAt,
    String? tamperSealId,
    String? barcode,
    String? videoProofUrl,
    int? conditionScore,
    String? conditionGrade,
    String? note,
  }) {
    return InspectionOrder(
      id: id,
      postId: postId,
      postTitle: postTitle,
      postImageUrls: postImageUrls,
      postPrice: postPrice,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      sellerAddress: sellerAddress,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      inspectorId: inspectorId,
      inspectorName: inspectorName,
      orderType: orderType,
      feePayer: feePayer,
      status: status ?? this.status,
      note: note ?? this.note,
      inspectionFee: inspectionFee,
      travelDistanceKm: travelDistanceKm,
      travelFee: travelFee,
      appointmentScheduledAt: appointmentScheduledAt ?? this.appointmentScheduledAt,
      tamperSealId: tamperSealId ?? this.tamperSealId,
      barcode: barcode ?? this.barcode,
      videoProofUrl: videoProofUrl ?? this.videoProofUrl,
      conditionScore: conditionScore ?? this.conditionScore,
      conditionGrade: conditionGrade ?? this.conditionGrade,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
