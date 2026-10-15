import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/inspection_order.dart';
import '../providers/inspection_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final InspectionOrder? order;
  const OrderDetailScreen({super.key, this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late InspectionOrder _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order ??
        ref.read(inspectionProvider).selectedOrder ??
        ref.read(inspectionProvider).orders.first;
  }

  void _showScheduleModal() async {
    DateTime selectedDate = _currentOrder.appointmentScheduledAt ?? DateTime.now().add(const Duration(hours: 2));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    final noteController = TextEditingController(text: _currentOrder.note ?? '');

    await showModalBottomSheet(
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
                  Icon(Icons.calendar_month, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Xếp Lịch Hẹn Đến Kiểm Định',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range, color: AppColors.slate600),
                title: const Text('Ngày hẹn'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setModalState(() {
                      selectedDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                    });
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, color: AppColors.slate600),
                title: const Text('Giờ hẹn'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setModalState(() {
                      selectedTime = picked;
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        picked.hour,
                        picked.minute,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú cho Người bán (VD: Mang dụng cụ test áp suất)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await ref.read(inspectionProvider.notifier).scheduleAppointment(
                        _currentOrder.id,
                        selectedDate,
                        noteController.text,
                      );
                  if (success && mounted) {
                    setState(() {
                      _currentOrder = _currentOrder.copyWith(
                        status: 'SCHEDULED',
                        appointmentScheduledAt: selectedDate,
                        note: noteController.text,
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật lịch hẹn kiểm định thành công!'),
                        backgroundColor: AppColors.passGreen,
                      ),
                    );
                  }
                },
                child: const Text('XÁC NHẬN LỊCH HẸN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startInspection() async {
    final success = await ref.read(inspectionProvider.notifier).startInspection(_currentOrder.id);
    if (success && mounted) {
      setState(() {
        _currentOrder = _currentOrder.copyWith(status: 'INSPECTING');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bắt đầu quy trình kiểm định! Trạng thái: INSPECTING'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormatter = DateFormat('HH:mm - dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn kiểm định #${_currentOrder.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primaryDark, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentOrder.statusLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentOrder.isAtHome
                                ? 'Gói kiểm định TẠI NHÀ NGƯỜI BÁN'
                                : 'Gói kiểm định TẠI TRUNG TÂM SECONDLIFE',
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sản phẩm kiểm định', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _currentOrder.postImageUrls.isNotEmpty
                                ? _currentOrder.postImageUrls.first
                                : 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=300',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 80,
                              height: 80,
                              color: AppColors.slate100,
                              child: const Icon(Icons.devices, color: AppColors.slate400),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentOrder.postTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(_currentOrder.postPrice),
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin các bên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.slate100,
                          child: Icon(Icons.store, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Người bán: ${_currentOrder.sellerName}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                _currentOrder.sellerAddress ?? '',
                                style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                              ),
                              Text(
                                'SĐT: ${_currentOrder.sellerPhone ?? "N/A"}',
                                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.slate100,
                          child: Icon(Icons.person, size: 16, color: AppColors.slate600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Người mua: ${_currentOrder.buyerName}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                'SĐT: ${_currentOrder.buyerPhone ?? "N/A"}',
                                style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phí kiểm định & Phụ cấp di chuyển', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phí dịch vụ kỹ thuật:', style: TextStyle(color: AppColors.slate600, fontSize: 13)),
                        Text(currencyFormatter.format(_currentOrder.inspectionFee), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Quãng đường di chuyển (${_currentOrder.travelDistanceKm} km):', style: const TextStyle(color: AppColors.slate600, fontSize: 13)),
                        Text(currencyFormatter.format(_currentOrder.travelFee), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mapBlue, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phụ cấp KTV nhận được:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate900)),
                        Text(
                          currencyFormatter.format(_currentOrder.inspectionFee * 0.7 + _currentOrder.travelFee),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.passGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: AppColors.amber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thời gian lịch hẹn', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
                          Text(
                            _currentOrder.appointmentScheduledAt != null
                                ? dateFormatter.format(_currentOrder.appointmentScheduledAt!)
                                : 'Chưa xếp lịch',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate900),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _showScheduleModal,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Đổi Lịch'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_currentOrder.status == 'SCHEDULED' || _currentOrder.status == 'CONFIRMED_PENDING_DISPATCH')
              ElevatedButton.icon(
                onPressed: _startInspection,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('BẮT ĐẦU KIỂM ĐỊNH (TẠI CHỖ)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else if (_currentOrder.status == 'INSPECTING')
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(inspectionProvider.notifier).selectOrder(_currentOrder);
                  context.push('/checklist-execution', extra: _currentOrder);
                },
                icon: const Icon(Icons.fact_check),
                label: const Text('TIẾP TỤC CHẤM CHECKLIST & CẤP TEM'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(inspectionProvider.notifier).selectOrder(_currentOrder);
                  context.push('/checklist-execution', extra: _currentOrder);
                },
                icon: const Icon(Icons.assessment_outlined),
                label: const Text('XEM BIÊN BẢN KIỂM ĐỊNH'),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
