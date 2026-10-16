import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/inspection_provider.dart';

class SealVerificationScreen extends ConsumerStatefulWidget {
  final String? tamperSealId;
  const SealVerificationScreen({super.key, this.tamperSealId});

  @override
  ConsumerState<SealVerificationScreen> createState() => _SealVerificationScreenState();
}

class _SealVerificationScreenState extends ConsumerState<SealVerificationScreen> {
  late String _sealId;

  @override
  void initState() {
    super.initState();
    _sealId = widget.tamperSealId ?? 'SL-SEAL-8924-A1';
    Future.microtask(() {
      ref.read(inspectionProvider.notifier).verifySeal(_sealId);
    });
  }

  void _showRecordScanModal() {
    String selectedStage = 'CARRIER_HANDOVER';
    String selectedCondition = 'INTACT';
    final locationController = TextEditingController(text: 'Khu Công Nghệ Cao, TP. Thủ Đức, TP.HCM');
    final noteController = TextEditingController(text: 'Tem còn nguyên lớp keo chống bóc vỡ, không có dấu hiệu nạy mở.');
    double? detectedLat;
    double? detectedLng;

    // Tự động lấy tọa độ GPS
    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 3)),
    ).then((pos) {
      detectedLat = pos.latitude;
      detectedLng = pos.longitude;
      locationController.text = 'Tọa độ GPS: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
    }).catchError((_) {});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_task, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Ghi Nhận Lần Quét Tem Mới',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStage,
                decoration: const InputDecoration(labelText: 'Giai đoạn quét tem'),
                items: const [
                  DropdownMenuItem(value: 'INITIAL_SEAL', child: Text('KTV dán tem niêm phong ban đầu')),
                  DropdownMenuItem(value: 'SELLER_TO_CENTER', child: Text('Người bán gửi hàng tới Hub')),
                  DropdownMenuItem(value: 'CENTER_RECEIVE', child: Text('Hub kiểm định nhận hàng & lưu kho')),
                  DropdownMenuItem(value: 'CARRIER_HANDOVER', child: Text('Bàn giao tài xế vận chuyển')),
                  DropdownMenuItem(value: 'DELIVERED_BUYER', child: Text('Đã giao tận tay người mua')),
                  DropdownMenuItem(value: 'RETURN_TO_SELLER', child: Text('Hoàn trả hàng về cho người bán')),
                ],
                onChanged: (val) => setModalState(() => selectedStage = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCondition,
                decoration: const InputDecoration(labelText: 'Tình trạng tem vật lý'),
                items: const [
                  DropdownMenuItem(value: 'INTACT', child: Text('INTACT - Còn nguyên vẹn (Đạt)')),
                  DropdownMenuItem(value: 'TAMPERED', child: Text('TAMPERED - Bị rách / Bong tróc (Cảnh báo)')),
                ],
                onChanged: (val) => setModalState(() => selectedCondition = val!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm quét (GPS / Địa chỉ)',
                  suffixIcon: Icon(Icons.my_location, size: 20, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú kiểm tra'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await ref.read(inspectionProvider.notifier).recordSealScan(
                        tamperSealId: _sealId,
                        scanStage: selectedStage,
                        sealCondition: selectedCondition,
                        locationText: locationController.text,
                        latitude: detectedLat,
                        longitude: detectedLng,
                        note: noteController.text,
                      );
                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã ghi nhận mốc quét tem kèm tọa độ GPS thành công!'),
                        backgroundColor: AppColors.passGreen,
                      ),
                    );
                  }
                },
                child: const Text('LƯU VẾT QUÉT TEM'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionProvider);
    final cert = state.verifiedSeal;
    final dateFormatter = DateFormat('HH:mm - dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chứng Thư Tem Niêm Phong'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cert == null
              ? const Center(child: Text('Không tìm thấy thông tin tem niêm phong'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: cert.isIntact
                                ? [const Color(0xFF065F46), const Color(0xFF0F766E)]
                                : [const Color(0xFF991B1B), const Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (cert.isIntact ? AppColors.passGreen : AppColors.failRed).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.security, color: Colors.amber, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'SECONDLIFE OFFICIAL SEAL',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    cert.isIntact ? 'NGUYÊN VẸN' : 'CÓ DẤU HIỆU CẠY',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (cert.productImageUrl != null && cert.productImageUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: cert.productImageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.white24,
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (_, _, _) => const Icon(Icons.devices, color: Colors.white70, size: 40),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              cert.tamperSealId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cert.productTitle,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildBadgeColumn('Điểm Đánh Giá', '${cert.conditionScore}/100'),
                                Container(height: 28, width: 1, color: Colors.white30),
                                _buildBadgeColumn('Phân Hạng', cert.conditionGrade),
                                Container(height: 28, width: 1, color: Colors.white30),
                                _buildBadgeColumn('Kết Quả', cert.inspectionStatus),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thông tin Kỹ thuật viên & Trạm kiểm định',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.engineering_outlined, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  const Text('KTV chịu trách nhiệm: ', style: TextStyle(fontSize: 13, color: AppColors.slate600)),
                                  Text(cert.inspectorName ?? 'KTV SecondLife',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.corporate_fare, size: 20, color: AppColors.slate600),
                                  const SizedBox(width: 8),
                                  const Text('Đơn vị cấp: ', style: TextStyle(fontSize: 13, color: AppColors.slate600)),
                                  Expanded(
                                    child: Text(cert.inspectionCenterName ?? 'Trung tâm Kỹ thuật SecondLife',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              if (cert.inspectedAt != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 20, color: AppColors.amber),
                                    const SizedBox(width: 8),
                                    const Text('Thời điểm kiểm định: ', style: TextStyle(fontSize: 13, color: AppColors.slate600)),
                                    Text(dateFormatter.format(cert.inspectedAt!),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Lịch Sử Quét & Lưu Vết',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate900),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showRecordScanModal,
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('Ghi nhận quét'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (cert.scanHistory.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Chưa có lịch sử quét tem bổ sung.',
                              style: TextStyle(color: AppColors.slate500, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ...cert.scanHistory.map((log) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        log.isIntact ? Icons.check_circle : Icons.warning,
                                        size: 18,
                                        color: log.isIntact ? AppColors.passGreen : AppColors.failRed,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          log.scanStageLabel,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        dateFormatter.format(log.scannedAt),
                                        style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (log.locationText != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.place_outlined, size: 14, color: AppColors.slate400),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            log.locationText!,
                                            style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (log.hasCoordinates) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.gps_fixed, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'GPS: ${log.latitude!.toStringAsFixed(5)}, ${log.longitude!.toStringAsFixed(5)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (log.note != null && log.note!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ghi chú: ${log.note}',
                                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.slate700),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showRecordScanModal,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('GHI NHẬN LẦN QUÉT MỚI'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBadgeColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
