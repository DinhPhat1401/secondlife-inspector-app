import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/checklist_item.dart';
import '../models/inspection_order.dart';
import '../models/tamper_seal.dart';
import 'inspector_stats_provider.dart';

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
      list = list
          .where(
            (o) =>
                o.status == 'SCHEDULED' ||
                o.status == 'CONFIRMED_PENDING_DISPATCH' ||
                o.status == 'DISPATCHED' ||
                o.status == 'RECEIVED_AT_CENTER' ||
                o.status == 'AWAITING_INSPECTION',
          )
          .toList();
    } else if (activeFilter == 'INSPECTING') {
      list = list.where((o) => o.status == 'INSPECTING').toList();
    } else if (activeFilter == 'COMPLETED') {
      list = list
          .where(
            (o) =>
                o.status == 'PASSED' ||
                o.status == 'FAILED' ||
                o.status == 'COMPLETED',
          )
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list
          .where(
            (o) =>
                o.postTitle.toLowerCase().contains(query) ||
                o.sellerName.toLowerCase().contains(query) ||
                o.id.toLowerCase().contains(query) ||
                (o.sellerAddress != null &&
                    o.sellerAddress!.toLowerCase().contains(query)),
          )
          .toList();
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
    Future.microtask(() {
      if (ref.mounted) fetchOrders();
    });
    return const InspectionState();
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  String _extractErrorMessage(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'] ?? data['error'] ?? data['detail'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString().trim();
        }
      } else if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return '$fallback: ${error.message}';
      }
    }
    return '$fallback: $error';
  }

  InspectionOrder? _parseOrderDto(dynamic rawResponseData) {
    if (rawResponseData is Map<String, dynamic>) {
      final payload = rawResponseData['data'] ?? rawResponseData;
      if (payload is Map<String, dynamic> && payload['id'] != null) {
        return InspectionOrder.fromJson(payload);
      }
    }
    return null;
  }

  void _syncOrderInState(
    InspectionOrder updatedOrder, {
    bool? isSubmitting,
    String? errorMessage,
  }) {
    final exists = state.orders.any((o) => o.id == updatedOrder.id);
    final updatedOrders = exists
        ? state.orders
              .map((o) => o.id == updatedOrder.id ? updatedOrder : o)
              .toList()
        : [updatedOrder, ...state.orders];

    final shouldUpdateSelected =
        state.selectedOrder == null ||
        state.selectedOrder?.id == updatedOrder.id;

    state = state.copyWith(
      orders: updatedOrders,
      selectedOrder: shouldUpdateSelected ? updatedOrder : state.selectedOrder,
      isSubmitting: isSubmitting ?? state.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _api.dio.get(ApiEndpoints.myAssignedOrders);
      if (!ref.mounted) return;
      final data = response.data;
      List<dynamic> rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        final payload = data['data'] ?? data['content'] ?? data['items'];
        if (payload is List) {
          rawList = payload;
        }
      }
      final list = rawList
          .map((e) => InspectionOrder.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(orders: list, isLoading: false);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractErrorMessage(
          e,
          'Không thể tải danh sách đơn kiểm định',
        ),
      );
    }
  }

  Future<InspectionOrder?> fetchOrderDetail(String orderId) async {
    try {
      final response = await _api.dio.get(ApiEndpoints.orderDetails(orderId));
      final order = _parseOrderDto(response.data);
      if (order != null) {
        _syncOrderInState(order, errorMessage: state.errorMessage);
        return order;
      }
    } catch (_) {}
    return null;
  }

  Future<void> selectOrder(InspectionOrder order) async {
    state = state.copyWith(selectedOrder: order);
    await fetchChecklistForOrder(order.id);
  }

  Future<void> fetchChecklistForOrder(String orderId) async {
    try {
      final response = await _api.dio.get(ApiEndpoints.orderChecklist(orderId));
      final data = response.data;
      List<dynamic>? itemsList;
      if (data is Map<String, dynamic>) {
        final payload = data['data'] ?? data;
        if (payload is Map<String, dynamic> && payload['items'] is List) {
          itemsList = payload['items'] as List;
        } else if (payload is List) {
          itemsList = payload;
        }
      } else if (data is List) {
        itemsList = data;
      }

      if (itemsList != null) {
        final items = itemsList
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(currentChecklist: items);
        return;
      }
    } catch (_) {}

    state = state.copyWith(currentChecklist: const []);
  }

  void updateChecklistItem(
    String itemId,
    bool passed,
    String note,
    String? photoProofUrl,
  ) {
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

  Future<bool> scheduleAppointment(
    String orderId,
    DateTime time,
    String note,
  ) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final response = await _api.dio.post(
        ApiEndpoints.scheduleAppointment(orderId),
        data: {
          'scheduledAt': time.toIso8601String(),
          'appointmentTime': time.toIso8601String(),
          'note': note,
        },
      );
      final parsed = _parseOrderDto(response.data);
      if (parsed != null) {
        _syncOrderInState(parsed, isSubmitting: false, errorMessage: null);
        return true;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Máy chủ không trả về đơn kiểm định đã cập nhật.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _extractErrorMessage(e, 'Không thể xếp lịch hẹn'),
      );
      return false;
    }
  }

  Future<InspectionOrder?> startInspection(
    String orderId, {
    String? checkInCode,
    String? barcodeInput,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final hasCheckInCode = checkInCode != null && checkInCode.trim().isNotEmpty;
    final hasBarcode = barcodeInput != null && barcodeInput.trim().isNotEmpty;
    final requestData = <String, dynamic>{
      if (hasCheckInCode) 'checkInCode': checkInCode.trim(),
      if (hasBarcode) 'barcodeInput': barcodeInput.trim(),
    };

    try {
      final response = await _api.dio.post(
        ApiEndpoints.startInspection(orderId),
        data: requestData,
      );

      final parsed = _parseOrderDto(response.data);
      if (parsed != null) {
        _syncOrderInState(parsed, isSubmitting: false, errorMessage: null);
        return parsed;
      }
      final latest = await fetchOrderDetail(orderId);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: latest?.status == 'INSPECTING'
            ? null
            : 'Máy chủ không trả về trạng thái kiểm định đã cập nhật.',
      );
      return latest?.status == 'INSPECTING' ? latest : null;
    } catch (e) {
      final errMsg = _extractErrorMessage(
        e,
        'Không thể bắt đầu phiên kiểm định',
      );
      await fetchOrderDetail(orderId);
      state = state.copyWith(isSubmitting: false, errorMessage: errMsg);
      return null;
    }
  }

  Future<InspectionOrder?> acceptCounterAppointment(String orderId) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final response = await _api.dio.post(
        '/api/v1/inspector/orders/$orderId/appointment/accept-counter',
      );
      final parsed = _parseOrderDto(response.data);
      if (parsed != null) {
        _syncOrderInState(parsed, isSubmitting: false, errorMessage: null);
        return parsed;
      }
      state = state.copyWith(isSubmitting: false);
      return null;
    } catch (e) {
      final errMsg = _extractErrorMessage(e, 'Không thể chấp nhận lịch hẹn');
      state = state.copyWith(isSubmitting: false, errorMessage: errMsg);
      return null;
    }
  }

  String? _extractUploadedUrl(dynamic data) {
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    if (data is Map<String, dynamic>) {
      final direct = data['url'] ?? data['secure_url'] ?? data['fileUrl'];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct.trim();
      }
      final nested = data['data'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim();
      }
      if (nested is Map<String, dynamic>) {
        final nestedUrl =
            nested['url'] ?? nested['secure_url'] ?? nested['fileUrl'];
        if (nestedUrl is String && nestedUrl.trim().isNotEmpty) {
          return nestedUrl.trim();
        }
      }
    }
    return null;
  }

  Future<String?> uploadEvidencePhoto(String filePath) async {
    try {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'folder': ApiEndpoints.inspectionProofsFolder,
      });

      final response = await _api.dio.post(
        ApiEndpoints.mediaUpload,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final url = _extractUploadedUrl(response.data);
      if (url != null) {
        return url;
      }
      state = state.copyWith(
        errorMessage: 'Máy chủ không trả về đường dẫn ảnh hợp lệ.',
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractErrorMessage(
          e,
          'Không thể tải ảnh minh chứng lên hệ thống',
        ),
      );
      return null;
    }
  }

  Future<List<String>> uploadMultipleEvidencePhotos(
    List<String> filePaths,
  ) async {
    if (filePaths.isEmpty) return const [];

    try {
      final files = <MultipartFile>[];
      for (final path in filePaths) {
        final fileName = path.split(RegExp(r'[/\\]')).last;
        files.add(await MultipartFile.fromFile(path, filename: fileName));
      }
      final formData = FormData.fromMap({
        'files': files,
        'folder': ApiEndpoints.inspectionProofsFolder,
      });

      final response = await _api.dio.post(
        ApiEndpoints.mediaUploadMultiple,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      List<dynamic>? rawUrls;
      if (data is List) {
        rawUrls = data;
      } else if (data is Map<String, dynamic>) {
        final payload = data['urls'] ?? data['data'] ?? data['files'];
        if (payload is List) {
          rawUrls = payload;
        } else if (payload is Map<String, dynamic> && payload['urls'] is List) {
          rawUrls = payload['urls'] as List;
        }
      }

      if (rawUrls != null) {
        final urls = rawUrls
            .map((item) => _extractUploadedUrl(item) ?? item.toString().trim())
            .where((u) => u.isNotEmpty)
            .toList();
        if (urls.isNotEmpty) {
          return urls;
        }
      }
    } catch (_) {
      // Fallback to sequential single uploads below
    }

    final uploadedUrls = <String>[];
    for (final path in filePaths) {
      final url = await uploadEvidencePhoto(path);
      if (url != null && url.isNotEmpty) {
        uploadedUrls.add(url);
      }
    }
    return uploadedUrls;
  }

  Future<bool> submitInspectionResult({
    required String orderId,
    required String status,
    required int conditionScore,
    required String conditionGrade,
    String? tamperSealId,
    String? barcode,
    String? videoProofUrl,
    String? unboxingVideoUrl,
    List<String>? evidencePhotoUrls,
    String? note,
    bool isAtCenter = false,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final checklistDto = state.currentChecklist
        .map((e) => e.toResultJson())
        .toList();

    final cleanVideoUrl =
        (videoProofUrl != null && videoProofUrl.trim().isNotEmpty)
        ? videoProofUrl.trim()
        : null;
    final cleanUnboxingUrl =
        (unboxingVideoUrl != null && unboxingVideoUrl.trim().isNotEmpty)
        ? unboxingVideoUrl.trim()
        : null;
    final cleanNote = (note != null && note.trim().isNotEmpty)
        ? note.trim()
        : null;
    final cleanSealId = (tamperSealId != null && tamperSealId.trim().isNotEmpty)
        ? tamperSealId.trim()
        : null;
    final cleanBarcode = (barcode != null && barcode.trim().isNotEmpty)
        ? barcode.trim()
        : cleanSealId;
    final cleanPhotos = {
      ...(evidencePhotoUrls ?? const <String>[]),
      ...state.currentChecklist.map((item) => item.photoProofUrl ?? ''),
    }.map((url) => url.trim()).where((url) => url.isNotEmpty).toList();

    if (cleanPhotos.length > 10) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            'Backend chỉ chấp nhận tối đa 10 ảnh minh chứng cho một biên bản.',
      );
      return false;
    }

    final Map<String, dynamic> payload = {
      'status': status,
      'conditionScore': conditionScore,
      'conditionGrade': conditionGrade,
      'note': ?cleanNote,
      'checklistResults': checklistDto,
      if (cleanPhotos.isNotEmpty) 'evidencePhotoUrls': cleanPhotos,
      'videoProofUrl': ?cleanVideoUrl,
      'unboxingVideoUrl': ?cleanUnboxingUrl,
    };

    if (!isAtCenter) {
      if (cleanSealId != null) {
        payload['tamperSealId'] = cleanSealId;
      }
      if (cleanBarcode != null) {
        payload['barcode'] = cleanBarcode;
      }
    }

    try {
      final response = await _api.dio.post(
        ApiEndpoints.submitResult(orderId),
        data: payload,
      );

      final parsed = _parseOrderDto(response.data);
      if (parsed != null) {
        _syncOrderInState(parsed, isSubmitting: false, errorMessage: null);
      } else {
        final latest = await fetchOrderDetail(orderId);
        if (latest == null ||
            (latest.status != status && !latest.isCompleted)) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: 'Máy chủ không xác nhận kết quả kiểm định đã nộp.',
          );
          return false;
        }
        _syncOrderInState(latest, isSubmitting: false, errorMessage: null);
      }

      try {
        ref.read(inspectorStatsProvider.notifier).refreshAll();
      } catch (_) {}

      return true;
    } catch (e) {
      final errMsg = _extractErrorMessage(
        e,
        'Không thể nộp biên bản kiểm định',
      );
      final latest = await fetchOrderDetail(orderId);
      if (latest != null && (latest.status == status || latest.isCompleted)) {
        state = state.copyWith(isSubmitting: false, errorMessage: null);
        try {
          ref.read(inspectorStatsProvider.notifier).refreshAll();
        } catch (_) {}
        return true;
      }

      state = state.copyWith(isSubmitting: false, errorMessage: errMsg);
      return false;
    }
  }

  Future<InspectionSealVerification?> verifySeal(String tamperSealId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.dio.get(
        ApiEndpoints.sealVerification(tamperSealId),
      );
      if (res.data != null) {
        final data = res.data['data'] ?? res.data;
        final cert = InspectionSealVerification.fromJson(
          data as Map<String, dynamic>,
        );
        state = state.copyWith(verifiedSeal: cert, isLoading: false);
        return cert;
      }
    } catch (e) {
      state = state.copyWith(
        verifiedSeal: null,
        isLoading: false,
        errorMessage: _extractErrorMessage(
          e,
          'Không tìm thấy hoặc không thể xác thực mã tem',
        ),
      );
      return null;
    }

    state = state.copyWith(verifiedSeal: null, isLoading: false);
    return null;
  }

  /// KTV yêu cầu hệ thống Backend sinh mã tem niêm phong chuẩn có checksum SHA-256
  Future<String?> generateSeal(String orderId) async {
    final targetOrder = state.selectedOrder?.id == orderId
        ? state.selectedOrder
        : state.orders.where((o) => o.id == orderId).firstOrNull;
    if (state.selectedOrder?.isAtCenter == true ||
        targetOrder?.isAtCenter == true) {
      return null;
    }

    try {
      final res = await _api.dio.post(ApiEndpoints.generateSeal(orderId));
      if (res.data != null) {
        final data = res.data['data'] ?? res.data['message'] ?? res.data;
        if (data is String && data.isNotEmpty) {
          return data;
        }
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractErrorMessage(
          e,
          'Không thể sinh mã tem niêm phong từ máy chủ',
        ),
      );
    }
    return null;
  }

  Future<bool> recordSealScan({
    required String tamperSealId,
    required String scanStage,
    required String sealCondition,
    String? locationText,
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    double? currentLat = latitude;
    double? currentLng = longitude;

    // Tự động lấy tọa độ GPS từ thiết bị nếu chưa có
    if (currentLat == null || currentLng == null) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
          currentLat = position.latitude;
          currentLng = position.longitude;
        }
      } catch (_) {
        // Bỏ qua lỗi định vị để không chặn luồng quét tem
      }
    }

    try {
      final payload = {
        'tamperSealId': tamperSealId,
        'scanStage': scanStage,
        'sealCondition': sealCondition,
        'locationText':
            locationText ??
            (currentLat != null
                ? 'Tọa độ GPS ($currentLat, $currentLng)'
                : 'Vị trí hiện tại KTV'),
        'note': note ?? 'Ghi nhận quét tem niêm phong',
        if (currentLat != null) ...{
          'latitude': currentLat,
          'longitude': currentLng,
        },
      };

      await _api.dio.post(ApiEndpoints.recordSealScan, data: payload);
    } catch (e) {
      state = state.copyWith(
        errorMessage: _extractErrorMessage(
          e,
          'Không thể ghi nhận lần quét tem',
        ),
      );
      return false;
    }

    await verifySeal(tamperSealId);
    return true;
  }
}

final inspectionProvider =
    NotifierProvider<InspectionNotifier, InspectionState>(() {
      return InspectionNotifier();
    });
