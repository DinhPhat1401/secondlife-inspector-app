import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/checklist_item.dart';
import '../models/inspection_order.dart';
import '../models/tamper_seal.dart';

class InspectionState {
  final List<InspectionOrder> orders;
  final String activeFilter; // ALL, SCHEDULED, INSPECTING, COMPLETED
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final InspectionOrder? selectedOrder;
  final List<ChecklistItem> currentChecklist;
  final InspectionSealVerification? verifiedSeal;
  final bool isSubmitting;

  const InspectionState({
    this.orders = const [],
    this.activeFilter = 'ALL',
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.selectedOrder,
    this.currentChecklist = const [],
    this.verifiedSeal,
    this.isSubmitting = false,
  });

  List<InspectionOrder> get filteredOrders {
    var list = orders;
    if (activeFilter == 'SCHEDULED') {
      list = list.where((o) => o.status == 'SCHEDULED' || o.status == 'CONFIRMED_PENDING_DISPATCH').toList();
    } else if (activeFilter == 'INSPECTING') {
      list = list.where((o) => o.status == 'INSPECTING').toList();
    } else if (activeFilter == 'COMPLETED') {
      list = list.where((o) => o.status == 'PASSED' || o.status == 'FAILED' || o.status == 'COMPLETED').toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((o) =>
          o.postTitle.toLowerCase().contains(query) ||
          o.sellerName.toLowerCase().contains(query) ||
          o.id.toLowerCase().contains(query) ||
          (o.sellerAddress != null && o.sellerAddress!.toLowerCase().contains(query))).toList();
    }
    return list;
  }

  InspectionState copyWith({
    List<InspectionOrder>? orders,
    String? activeFilter,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    InspectionOrder? selectedOrder,
    List<ChecklistItem>? currentChecklist,
    InspectionSealVerification? verifiedSeal,
    bool? isSubmitting,
  }) {
    return InspectionState(
      orders: orders ?? this.orders,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      currentChecklist: currentChecklist ?? this.currentChecklist,
      verifiedSeal: verifiedSeal ?? this.verifiedSeal,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class InspectionNotifier extends Notifier<InspectionState> {
  final ApiClient _api = ApiClient();

  @override
  InspectionState build() {
    final initialList = _buildDefaultMockOrders();
    return InspectionState(
      orders: initialList,
      currentChecklist: _generateDefaultChecklist(),
    );
  }

  static List<InspectionOrder> _buildDefaultMockOrders() {
    return [
      InspectionOrder(
        id: 'INS-8921',
        postId: 'post-101',
        postTitle: 'Máy Lạnh Inverter Daikin 1.5 HP Tiết Kiệm Điện (FTKB35WAVMV)',
        postImageUrls: ['https://images.unsplash.com/photo-1614633833026-0820552978b6?w=600'],
        postPrice: 6850000,
        sellerName: 'Nguyễn Văn Hùng',
        sellerPhone: '0903 124 567',
        sellerAddress: '15 Lê Văn Việt, Tăng Nhơn Phú B, TP. Thủ Đức, TP.HCM',
        buyerName: 'Trần Thị Thu Hà',
        buyerPhone: '0978 991 234',
        orderType: 'AT_HOME',
        feePayer: 'SPLIT_50_50',
        status: 'SCHEDULED',
        inspectionFee: 200000,
        travelDistanceKm: 3.8,
        travelFee: 40000,
        appointmentScheduledAt: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
        latitude: 10.8465,
        longitude: 106.7725,
      ),
      InspectionOrder(
        id: 'INS-8922',
        postId: 'post-102',
        postTitle: 'Tủ Lạnh 4 Cánh Panasonic Inverter 540L Prime Fresh+',
        postImageUrls: ['https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?w=600'],
        postPrice: 15200000,
        sellerName: 'Phạm Quang Minh',
        sellerPhone: '0918 882 119',
        sellerAddress: '120 Võ Văn Ngân, Linh Chiểu, TP. Thủ Đức, TP.HCM',
        buyerName: 'Lê Hoàng Nam',
        buyerPhone: '0933 445 566',
        orderType: 'AT_HOME',
        feePayer: 'BUYER_PAYS_ALL',
        status: 'INSPECTING',
        inspectionFee: 250000,
        travelDistanceKm: 5.2,
        travelFee: 55000,
        appointmentScheduledAt: DateTime.now().subtract(const Duration(minutes: 20)),
        latitude: 10.8510,
        longitude: 106.7645,
      ),
      InspectionOrder(
        id: 'INS-8923',
        postId: 'post-103',
        postTitle: 'Máy Pha Cà Phê DeLonghi Dedica EC685.M Inox Cao Cấp',
        postImageUrls: ['https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?w=600'],
        postPrice: 3400000,
        sellerName: 'Đặng Ngọc Mai',
        sellerPhone: '0982 334 112',
        sellerAddress: 'Trung tâm SecondLife - 54 Nguyễn Huệ, Quận 1, TP.HCM',
        buyerName: 'Vũ Đức Thành',
        buyerPhone: '0908 678 901',
        orderType: 'AT_CENTER',
        feePayer: 'SELLER_PAYS_ALL',
        status: 'CONFIRMED_PENDING_DISPATCH',
        inspectionFee: 150000,
        travelDistanceKm: 0.0,
        travelFee: 0.0,
        appointmentScheduledAt: DateTime.now().add(const Duration(hours: 4)),
        latitude: 10.7735,
        longitude: 106.7032,
      ),
      InspectionOrder(
        id: 'INS-8924',
        postId: 'post-104',
        postTitle: 'Máy Hút Bụi Cầm Tay Không Dây Dyson V11 Torque Drive',
        postImageUrls: ['https://images.unsplash.com/photo-1558317374-067fb5f30001?w=600'],
        postPrice: 8900000,
        sellerName: 'Hoàng Quốc Việt',
        sellerPhone: '0909 555 432',
        sellerAddress: '24 Đường D1, Phường Tân Phú, Quận 7, TP.HCM',
        buyerName: 'Ngô Thanh Vân',
        buyerPhone: '0912 999 888',
        orderType: 'AT_HOME',
        feePayer: 'SPLIT_50_50',
        status: 'PASSED',
        inspectionFee: 180000,
        travelDistanceKm: 8.4,
        travelFee: 85000,
        tamperSealId: 'SL-SEAL-8924-A1',
        barcode: 'SL89242026',
        conditionScore: 94,
        conditionGrade: 'A - Như Mới',
        videoProofUrl: 'https://cloudinary.com/secondlife/inspection/v11_test_run.mp4',
        appointmentScheduledAt: DateTime.now().subtract(const Duration(days: 1)),
        latitude: 10.7325,
        longitude: 106.7210,
      ),
    ];
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _api.dio.get(ApiEndpoints.myAssignedOrders);
      if (response.data is List) {
        final list = (response.data as List)
            .map((e) => InspectionOrder.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(orders: list, isLoading: false);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  Future<void> selectOrder(InspectionOrder order) async {
    state = state.copyWith(selectedOrder: order);
    await fetchChecklistForOrder(order.id);
  }

  Future<void> fetchChecklistForOrder(String orderId) async {
    try {
      final response = await _api.dio.get(ApiEndpoints.orderChecklist(orderId));
      if (response.data != null && response.data['items'] is List) {
        final items = (response.data['items'] as List)
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(currentChecklist: items);
        return;
      }
    } catch (_) {}

    state = state.copyWith(currentChecklist: _generateDefaultChecklist());
  }

  static List<ChecklistItem> _generateDefaultChecklist() {
    return [
      ChecklistItem(
        id: 'chk-01',
        itemTitle: 'Ngoại quan & Thân vỏ máy',
        criteriaDescription: 'Kiểm tra vết nứt vỡ, trầy xước sâu, móp méo, han gỉ thân vỏ và ốc vít còn nguyên seal gốc.',
        mandatory: true,
        orderIndex: 1,
      ),
      ChecklistItem(
        id: 'chk-02',
        itemTitle: 'Nguồn điện & An toàn rò rỉ',
        criteriaDescription: 'Đo điện áp tiếp địa, kiểm tra dây cắm, chống rò điện ra vỏ và tiếp xúc phích cắm.',
        mandatory: true,
        orderIndex: 2,
      ),
      ChecklistItem(
        id: 'chk-03',
        itemTitle: 'Động cơ & Độ ồn vận hành',
        criteriaDescription: 'Khởi động máy tải thật, kiểm tra độ êm lốc lạnh/mô tơ, không có tiếng rít cơ khí bất thường.',
        mandatory: true,
        orderIndex: 3,
      ),
      ChecklistItem(
        id: 'chk-04',
        itemTitle: 'Hiệu suất nhiệt & Công suất thực tế',
        criteriaDescription: 'Đo nhiệt độ làm lạnh/làm nóng thực tế bằng súng nhiệt, đối chiếu đúng thông số công bố của hãng.',
        mandatory: true,
        orderIndex: 4,
      ),
      ChecklistItem(
        id: 'chk-05',
        itemTitle: 'Bo mạch & Bảng điều khiển điện tử',
        criteriaDescription: 'Màn hình hiển thị, các phím bấm/cảm ứng, các chế độ tự động hoạt động chuẩn xác.',
        mandatory: true,
        orderIndex: 5,
      ),
      ChecklistItem(
        id: 'chk-06',
        itemTitle: 'Phụ kiện kèm theo máy',
        criteriaDescription: 'Đầy đủ ống đồng, remote zin, dây cấp thoát nước hoặc đầu hút theo bộ của hãng.',
        mandatory: false,
        orderIndex: 6,
      ),
      ChecklistItem(
        id: 'chk-07',
        itemTitle: 'Dán Tem Niêm Phong Chống Tráo SecondLife',
        criteriaDescription: 'Dán tem vỡ bảo mật SecondLife có mã QR & số Serial duy nhất lên vị trí ốc máy chính.',
        mandatory: true,
        orderIndex: 7,
      ),
    ];
  }

  void updateChecklistItem(String itemId, bool passed, String note, String? photoProofUrl) {
    final updated = state.currentChecklist.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          passed: passed,
          inspectorNote: note,
          photoProofUrl: photoProofUrl,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(currentChecklist: updated);
  }

  Future<bool> scheduleAppointment(String orderId, DateTime time, String note) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _api.dio.post(
        ApiEndpoints.scheduleAppointment(orderId),
        data: {
          'appointmentTime': time.toIso8601String(),
          'note': note,
        },
      );
    } catch (_) {}

    final updatedOrders = state.orders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(
          status: 'SCHEDULED',
          appointmentScheduledAt: time,
          note: note,
        );
      }
      return o;
    }).toList();

    state = state.copyWith(
      orders: updatedOrders,
      selectedOrder: state.selectedOrder?.copyWith(
        status: 'SCHEDULED',
        appointmentScheduledAt: time,
        note: note,
      ),
      isSubmitting: false,
    );
    return true;
  }

  Future<bool> startInspection(String orderId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _api.dio.post(ApiEndpoints.startInspection(orderId));
    } catch (_) {}

    final updatedOrders = state.orders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(status: 'INSPECTING');
      }
      return o;
    }).toList();

    state = state.copyWith(
      orders: updatedOrders,
      selectedOrder: state.selectedOrder?.copyWith(status: 'INSPECTING'),
      isSubmitting: false,
    );
    return true;
  }

  Future<bool> submitInspectionResult({
    required String orderId,
    required String status,
    required int conditionScore,
    required String conditionGrade,
    required String tamperSealId,
    String? barcode,
    String? videoProofUrl,
    String? note,
  }) async {
    state = state.copyWith(isSubmitting: true);
    final checklistDto = state.currentChecklist.map((e) => e.toResultJson()).toList();

    final payload = {
      'status': status,
      'conditionScore': conditionScore,
      'conditionGrade': conditionGrade,
      'tamperSealId': tamperSealId,
      'barcode': barcode ?? tamperSealId,
      'videoProofUrl': videoProofUrl ?? 'https://cloudinary.com/secondlife/inspection/video_proof_$orderId.mp4',
      'note': note ?? 'KTV đã hoàn tất kiểm tra quy chuẩn.',
      'checklistResults': checklistDto,
    };

    try {
      await _api.dio.post(
        ApiEndpoints.submitResult(orderId),
        data: payload,
      );
    } catch (_) {}

    final updatedOrders = state.orders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(
          status: status,
          conditionScore: conditionScore,
          conditionGrade: conditionGrade,
          tamperSealId: tamperSealId,
          barcode: barcode ?? tamperSealId,
          videoProofUrl: videoProofUrl,
          note: note,
        );
      }
      return o;
    }).toList();

    state = state.copyWith(
      orders: updatedOrders,
      selectedOrder: state.selectedOrder?.copyWith(
        status: status,
        conditionScore: conditionScore,
        conditionGrade: conditionGrade,
        tamperSealId: tamperSealId,
        barcode: barcode ?? tamperSealId,
        videoProofUrl: videoProofUrl,
        note: note,
      ),
      isSubmitting: false,
    );
    return true;
  }

  Future<InspectionSealVerification?> verifySeal(String tamperSealId) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.dio.get(ApiEndpoints.sealVerification(tamperSealId));
      if (res.data != null) {
        final data = res.data['data'] ?? res.data;
        final cert = InspectionSealVerification.fromJson(data as Map<String, dynamic>);
        state = state.copyWith(verifiedSeal: cert, isLoading: false);
        return cert;
      }
    } catch (_) {}

    final mockCert = InspectionSealVerification(
      tamperSealId: tamperSealId.toUpperCase(),
      productTitle: 'Máy Lạnh Inverter Daikin 1.5 HP Tiết Kiệm Điện (FTKB35WAVMV)',
      productBrand: 'Daikin Japan',
      productModel: 'FTKB35WAVMV',
      conditionScore: 92,
      conditionGrade: 'A - Rất Tốt',
      inspectionStatus: 'PASSED',
      currentSealStatus: 'INTACT',
      isOfficialSecondLifeSeal: true,
      inspectorName: 'KTV. Trần Minh Long',
      inspectedAt: DateTime.now().subtract(const Duration(hours: 3)),
      scanHistory: [
        InspectionSealLog(
          id: 'log-1',
          tamperSealId: tamperSealId,
          scannedByName: 'KTV. Trần Minh Long',
          scanStage: 'INITIAL_SEAL',
          sealCondition: 'INTACT',
          locationText: '15 Lê Văn Việt, TP. Thủ Đức, TP.HCM',
          note: 'Dán tem niêm phong sau khi đạt toàn bộ 7 tiêu chí kiểm định',
          scannedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
    );

    state = state.copyWith(verifiedSeal: mockCert, isLoading: false);
    return mockCert;
  }

  Future<bool> recordSealScan({
    required String tamperSealId,
    required String scanStage,
    required String sealCondition,
    String? locationText,
    String? note,
  }) async {
    try {
      await _api.dio.post(
        ApiEndpoints.recordSealScan,
        data: {
          'tamperSealId': tamperSealId,
          'scanStage': scanStage,
          'sealCondition': sealCondition,
          'locationText': locationText ?? 'Vị trí hiện tại KTV',
          'note': note ?? 'Ghi nhận quét tem niêm phong',
        },
      );
    } catch (_) {}

    if (state.verifiedSeal != null && state.verifiedSeal!.tamperSealId.toLowerCase() == tamperSealId.toLowerCase()) {
      final newLog = InspectionSealLog(
        id: 'log-${DateTime.now().millisecondsSinceEpoch}',
        tamperSealId: tamperSealId,
        scannedByName: 'KTV. Trần Minh Long',
        scanStage: scanStage,
        sealCondition: sealCondition,
        locationText: locationText ?? 'Vị trí hiện tại KTV',
        note: note,
        scannedAt: DateTime.now(),
      );

      final updatedHistory = [newLog, ...state.verifiedSeal!.scanHistory];
      final updatedCert = InspectionSealVerification(
        tamperSealId: state.verifiedSeal!.tamperSealId,
        inspectionOrderId: state.verifiedSeal!.inspectionOrderId,
        postId: state.verifiedSeal!.postId,
        productTitle: state.verifiedSeal!.productTitle,
        productModel: state.verifiedSeal!.productModel,
        productBrand: state.verifiedSeal!.productBrand,
        conditionScore: state.verifiedSeal!.conditionScore,
        conditionGrade: state.verifiedSeal!.conditionGrade,
        inspectionStatus: state.verifiedSeal!.inspectionStatus,
        inspectionCenterName: state.verifiedSeal!.inspectionCenterName,
        inspectorName: state.verifiedSeal!.inspectorName,
        inspectedAt: state.verifiedSeal!.inspectedAt,
        currentSealStatus: sealCondition,
        isOfficialSecondLifeSeal: state.verifiedSeal!.isOfficialSecondLifeSeal,
        scanHistory: updatedHistory,
      );

      state = state.copyWith(verifiedSeal: updatedCert);
    }
    return true;
  }
}

final inspectionProvider = NotifierProvider<InspectionNotifier, InspectionState>(() {
  return InspectionNotifier();
});
