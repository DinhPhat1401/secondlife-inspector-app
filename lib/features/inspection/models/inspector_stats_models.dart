class InspectorStats {
  final String inspectorId;
  final String inspectorName;
  final String badgeCode;
  final String skillLevel;
  final int completedJobs;
  final int passedJobs;
  final int failedJobs;
  final double averageRating;
  final double onTimeRate;
  final double monthlyEarnings;
  final double laborFeeEarned;
  final double travelAllowanceEarned;
  final double pendingSettlementAmount;

  const InspectorStats({
    required this.inspectorId,
    required this.inspectorName,
    required this.badgeCode,
    required this.skillLevel,
    required this.completedJobs,
    required this.passedJobs,
    required this.failedJobs,
    required this.averageRating,
    required this.onTimeRate,
    required this.monthlyEarnings,
    required this.laborFeeEarned,
    required this.travelAllowanceEarned,
    required this.pendingSettlementAmount,
  });

  factory InspectorStats.fromJson(Map<String, dynamic> json) {
    return InspectorStats(
      inspectorId: json['inspectorId']?.toString() ?? '',
      inspectorName: json['inspectorName']?.toString() ?? '',
      badgeCode: json['badgeCode']?.toString() ?? '',
      skillLevel: json['skillLevel']?.toString() ?? 'Kỹ thuật viên Thẩm định Bậc 3',
      completedJobs: (json['completedJobs'] as num?)?.toInt() ?? 0,
      passedJobs: (json['passedJobs'] as num?)?.toInt() ?? 0,
      failedJobs: (json['failedJobs'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 5.0,
      onTimeRate: (json['onTimeRate'] as num?)?.toDouble() ?? 100.0,
      monthlyEarnings: (json['monthlyEarnings'] as num?)?.toDouble() ?? 0.0,
      laborFeeEarned: (json['laborFeeEarned'] as num?)?.toDouble() ?? 0.0,
      travelAllowanceEarned: (json['travelAllowanceEarned'] as num?)?.toDouble() ?? 0.0,
      pendingSettlementAmount: (json['pendingSettlementAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InspectorPayout {
  final String payoutId;
  final String orderId;
  final String postTitle;
  final String orderType; // AT_HOME, AT_CENTER
  final DateTime? completedAt;
  final double laborFee;
  final double travelFee;
  final double totalPayout;
  final String status; // SETTLED, PENDING

  const InspectorPayout({
    required this.payoutId,
    required this.orderId,
    required this.postTitle,
    required this.orderType,
    this.completedAt,
    required this.laborFee,
    required this.travelFee,
    required this.totalPayout,
    required this.status,
  });

  bool get isAtHome => orderType == 'AT_HOME';
  bool get isSettled => status == 'SETTLED';

  factory InspectorPayout.fromJson(Map<String, dynamic> json) {
    return InspectorPayout(
      payoutId: json['payoutId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      postTitle: json['postTitle']?.toString() ?? 'Đơn kiểm định thiết bị',
      orderType: json['orderType']?.toString() ?? 'AT_CENTER',
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
      laborFee: (json['laborFee'] as num?)?.toDouble() ?? 0.0,
      travelFee: (json['travelFee'] as num?)?.toDouble() ?? 0.0,
      totalPayout: (json['totalPayout'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'SETTLED',
    );
  }
}

class InspectorPayoutsPage {
  final List<InspectorPayout> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool isLast;
  final bool isFirst;

  const InspectorPayoutsPage({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
    required this.isFirst,
  });

  factory InspectorPayoutsPage.fromJson(Map<String, dynamic> json) {
    final list = (json['content'] as List<dynamic>?)
            ?.map((e) => InspectorPayout.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final pageable = json['pageable'] as Map<String, dynamic>?;
    return InspectorPayoutsPage(
      content: list,
      pageNumber: (pageable?['pageNumber'] as num?)?.toInt() ?? (json['number'] as num?)?.toInt() ?? 0,
      pageSize: (pageable?['pageSize'] as num?)?.toInt() ?? (json['size'] as num?)?.toInt() ?? 10,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? list.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      isLast: json['last'] as bool? ?? true,
      isFirst: json['first'] as bool? ?? true,
    );
  }
}
