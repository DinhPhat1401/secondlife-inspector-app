import 'dart:convert';

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
  final String? buyerAddress;

  final String? inspectorId;
  final String? inspectorName;

  final String? inspectionCenterId;
  final String? inspectionCenterName;

  final String orderType; // AT_HOME, AT_CENTER
  final String feePayer;
  final String status;
  final String? note;

  final double inspectionFee;
  final double travelDistanceKm;
  final double travelFee;
  final double shippingFee;
  final double? returnShippingReserveFee;
  final double? buyerFeeShare;
  final double? sellerFeeShare;
  final double? buyerCommitmentDeposit;

  final DateTime? feeSettledAt;
  final DateTime? finalPaymentDeadline;
  final DateTime? finalPaymentPaidAt;

  final DateTime? appointmentScheduledAt;
  final String? appointmentStatus;
  final DateTime? counterScheduledAt;
  final String? counterShift;
  final String? counterNote;
  final String? homeCheckInCode;
  final DateTime? homeCheckedInAt;

  final String? tamperSealId;
  final String? barcode;
  final String? videoProofUrl;
  final String? unboxingVideoUrl;
  final List<String> evidencePhotoUrls;
  final String? checklistResultJson;
  final int? conditionScore;
  final String? conditionGrade;

  final String? appealStatus;
  final DateTime? appealDeadline;

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
    this.buyerAddress,
    this.inspectorId,
    this.inspectorName,
    this.inspectionCenterId,
    this.inspectionCenterName,
    required this.orderType,
    required this.feePayer,
    required this.status,
    this.note,
    this.inspectionFee = 0.0,
    this.travelDistanceKm = 0.0,
    this.travelFee = 0.0,
    this.shippingFee = 0.0,
    this.returnShippingReserveFee,
    this.buyerFeeShare,
    this.sellerFeeShare,
    this.buyerCommitmentDeposit,
    this.feeSettledAt,
    this.finalPaymentDeadline,
    this.finalPaymentPaidAt,
    this.appointmentScheduledAt,
    this.appointmentStatus,
    this.counterScheduledAt,
    this.counterShift,
    this.counterNote,
    this.homeCheckInCode,
    this.homeCheckedInAt,
    this.tamperSealId,
    this.barcode,
    this.videoProofUrl,
    this.unboxingVideoUrl,
    this.evidencePhotoUrls = const [],
    this.checklistResultJson,
    this.conditionScore,
    this.conditionGrade,
    this.appealStatus,
    this.appealDeadline,
    this.latitude = 10.7769,
    this.longitude = 106.7009,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value != null) return double.tryParse(value.toString());
    return null;
  }

  static double _parseDouble(dynamic value, [double fallback = 0.0]) {
    return _parseNullableDouble(value) ?? fallback;
  }

  factory InspectionOrder.fromJson(Map<String, dynamic> json) {
    final images = (json['postImageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    String? rawNote = json['note']?.toString();
    final rawEvidence = json['evidencePhotoUrls'] ?? json['proofPhotos'] ?? json['inspectorPhotos'];
    List<String> parsedEvidencePhotos = [];
    if (rawEvidence is List) {
      parsedEvidencePhotos = rawEvidence
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (rawNote != null && rawNote.isNotEmpty) {
      final photosRegex = RegExp(r'\s*\[Photos:\s*(\[.*?\]|.*?)\]\s*$', dotAll: true);
      final match = photosRegex.firstMatch(rawNote);
      if (match != null) {
        if (parsedEvidencePhotos.isEmpty) {
          final groupContent = match.group(1)?.trim() ?? '';
          if (groupContent.startsWith('[') && groupContent.endsWith(']')) {
            try {
              final decoded = jsonDecode(groupContent);
              if (decoded is List) {
                parsedEvidencePhotos = decoded
                    .map((e) => e.toString().trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
            } catch (_) {
              final inner = groupContent.substring(1, groupContent.length - 1);
              parsedEvidencePhotos = inner
                  .split(',')
                  .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
          } else if (groupContent.isNotEmpty) {
            parsedEvidencePhotos = groupContent
                .split(',')
                .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
                .where((s) => s.isNotEmpty)
                .toList();
          }
        }
        rawNote = rawNote.replaceFirst(photosRegex, '').trim();
      }
    }

    return InspectionOrder(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString(),
      postTitle: json['postTitle']?.toString() ?? '',
      postImageUrls: images,
      postPrice: _parseDouble(json['postPrice'], 0.0),
      sellerId: json['sellerId']?.toString(),
      sellerName: json['sellerName']?.toString() ?? '',
      sellerPhone: json['sellerPhone']?.toString(),
      sellerAddress: json['sellerAddress']?.toString(),
      buyerId: json['buyerId']?.toString(),
      buyerName: json['buyerName']?.toString() ?? '',
      buyerPhone: json['buyerPhone']?.toString(),
      buyerAddress: json['buyerAddress']?.toString(),
      inspectorId: json['inspectorId']?.toString(),
      inspectorName: json['inspectorName']?.toString() ?? '',
      inspectionCenterId: json['inspectionCenterId']?.toString(),
      inspectionCenterName: json['inspectionCenterName']?.toString(),
      orderType: json['orderType']?.toString() ?? 'AT_HOME',
      feePayer: json['feePayer']?.toString() ?? 'SPLIT_50_50',
      status: json['status']?.toString() ?? 'SCHEDULED',
      note: rawNote,
      inspectionFee: _parseDouble(json['inspectionFee'], 0.0),
      travelDistanceKm: _parseDouble(json['travelDistanceKm'], 0.0),
      travelFee: _parseDouble(json['travelFee'], 0.0),
      shippingFee: _parseDouble(json['shippingFee'], 0.0),
      returnShippingReserveFee: _parseNullableDouble(json['returnShippingReserveFee']),
      buyerFeeShare: _parseNullableDouble(json['buyerFeeShare']),
      sellerFeeShare: _parseNullableDouble(json['sellerFeeShare']),
      buyerCommitmentDeposit: _parseNullableDouble(json['buyerCommitmentDeposit']),
      feeSettledAt: _parseDate(json['feeSettledAt']),
      finalPaymentDeadline: _parseDate(json['finalPaymentDeadline']),
      finalPaymentPaidAt: _parseDate(json['finalPaymentPaidAt']),
      appointmentScheduledAt: _parseDate(json['appointmentScheduledAt']),
      appointmentStatus: json['appointmentStatus']?.toString(),
      counterScheduledAt: _parseDate(json['counterScheduledAt']),
      counterShift: json['counterShift']?.toString(),
      counterNote: json['counterNote']?.toString(),
      homeCheckInCode: json['homeCheckInCode']?.toString(),
      homeCheckedInAt: _parseDate(json['homeCheckedInAt']),
      tamperSealId: json['tamperSealId']?.toString(),
      barcode: json['barcode']?.toString(),
      videoProofUrl: json['videoProofUrl']?.toString(),
      unboxingVideoUrl: json['unboxingVideoUrl']?.toString(),
      evidencePhotoUrls: parsedEvidencePhotos,
      checklistResultJson: json['checklistResultJson']?.toString(),
      conditionScore: json['conditionScore'] is num ? (json['conditionScore'] as num).toInt() : null,
      conditionGrade: json['conditionGrade']?.toString(),
      appealStatus: json['appealStatus']?.toString(),
      appealDeadline: _parseDate(json['appealDeadline']),
      latitude: _parseDouble(json['latitude'], 0.0),
      longitude: _parseDouble(json['longitude'], 0.0),
    );
  }

  bool get isAtHome => orderType == 'AT_HOME';
  bool get isAtCenter => orderType == 'AT_CENTER';
  bool get isCompleted => status == 'PASSED' || status == 'FAILED' || status == 'COMPLETED';

  String get statusLabel {
    switch (status) {
      case 'WAITING_SELLER_APPROVAL':
        return 'Chờ người bán duyệt';
      case 'WAITING_FEE_PAYMENT':
        return 'Chờ ký quỹ phí';
      case 'CONFIRMED_PENDING_DISPATCH':
        return 'Chờ điều phối';
      case 'DISPATCHED':
        return 'Đã phân công KTV';
      case 'SCHEDULED':
        return 'Đã lên lịch hẹn';
      case 'SHIPPING_TO_CENTER':
        return 'Đang chuyển về TT';
      case 'RECEIVED_AT_CENTER':
        return 'Đã nhận tại Trung tâm';
      case 'AWAITING_INSPECTION':
        return 'Chờ kiểm định';
      case 'INSPECTING':
        return 'Đang kiểm định';
      case 'PASSED':
        return 'Đạt chuẩn (PASSED)';
      case 'FAILED':
        return 'Không đạt (FAILED)';
      case 'DELIVERING_TO_BUYER':
        return 'Đang giao người mua';
      case 'COMPLETED':
        return 'Hoàn tất';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  InspectionOrder copyWith({
    String? id,
    String? postId,
    String? postTitle,
    List<String>? postImageUrls,
    double? postPrice,
    String? sellerId,
    String? sellerName,
    String? sellerPhone,
    String? sellerAddress,
    String? buyerId,
    String? buyerName,
    String? buyerPhone,
    String? buyerAddress,
    String? inspectorId,
    String? inspectorName,
    String? inspectionCenterId,
    String? inspectionCenterName,
    String? orderType,
    String? feePayer,
    String? status,
    String? note,
    double? inspectionFee,
    double? travelDistanceKm,
    double? travelFee,
    double? shippingFee,
    double? returnShippingReserveFee,
    double? buyerFeeShare,
    double? sellerFeeShare,
    double? buyerCommitmentDeposit,
    DateTime? feeSettledAt,
    DateTime? finalPaymentDeadline,
    DateTime? finalPaymentPaidAt,
    DateTime? appointmentScheduledAt,
    String? appointmentStatus,
    DateTime? counterScheduledAt,
    String? counterShift,
    String? counterNote,
    String? homeCheckInCode,
    DateTime? homeCheckedInAt,
    String? tamperSealId,
    String? barcode,
    String? videoProofUrl,
    String? unboxingVideoUrl,
    List<String>? evidencePhotoUrls,
    String? checklistResultJson,
    int? conditionScore,
    String? conditionGrade,
    String? appealStatus,
    DateTime? appealDeadline,
    double? latitude,
    double? longitude,
  }) {
    return InspectionOrder(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      postImageUrls: postImageUrls ?? this.postImageUrls,
      postPrice: postPrice ?? this.postPrice,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectionCenterId: inspectionCenterId ?? this.inspectionCenterId,
      inspectionCenterName: inspectionCenterName ?? this.inspectionCenterName,
      orderType: orderType ?? this.orderType,
      feePayer: feePayer ?? this.feePayer,
      status: status ?? this.status,
      note: note ?? this.note,
      inspectionFee: inspectionFee ?? this.inspectionFee,
      travelDistanceKm: travelDistanceKm ?? this.travelDistanceKm,
      travelFee: travelFee ?? this.travelFee,
      shippingFee: shippingFee ?? this.shippingFee,
      returnShippingReserveFee: returnShippingReserveFee ?? this.returnShippingReserveFee,
      buyerFeeShare: buyerFeeShare ?? this.buyerFeeShare,
      sellerFeeShare: sellerFeeShare ?? this.sellerFeeShare,
      buyerCommitmentDeposit: buyerCommitmentDeposit ?? this.buyerCommitmentDeposit,
      feeSettledAt: feeSettledAt ?? this.feeSettledAt,
      finalPaymentDeadline: finalPaymentDeadline ?? this.finalPaymentDeadline,
      finalPaymentPaidAt: finalPaymentPaidAt ?? this.finalPaymentPaidAt,
      appointmentScheduledAt: appointmentScheduledAt ?? this.appointmentScheduledAt,
      appointmentStatus: appointmentStatus ?? this.appointmentStatus,
      counterScheduledAt: counterScheduledAt ?? this.counterScheduledAt,
      counterShift: counterShift ?? this.counterShift,
      counterNote: counterNote ?? this.counterNote,
      homeCheckInCode: homeCheckInCode ?? this.homeCheckInCode,
      homeCheckedInAt: homeCheckedInAt ?? this.homeCheckedInAt,
      tamperSealId: tamperSealId ?? this.tamperSealId,
      barcode: barcode ?? this.barcode,
      videoProofUrl: videoProofUrl ?? this.videoProofUrl,
      unboxingVideoUrl: unboxingVideoUrl ?? this.unboxingVideoUrl,
      evidencePhotoUrls: evidencePhotoUrls ?? this.evidencePhotoUrls,
      checklistResultJson: checklistResultJson ?? this.checklistResultJson,
      conditionScore: conditionScore ?? this.conditionScore,
      conditionGrade: conditionGrade ?? this.conditionGrade,
      appealStatus: appealStatus ?? this.appealStatus,
      appealDeadline: appealDeadline ?? this.appealDeadline,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
