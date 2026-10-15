import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/inspection_order.dart';
import '../providers/inspection_provider.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final inspectionState = ref.watch(inspectionProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormatter = DateFormat('HH:mm - dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  auth.inspectorName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Đang Trực Ca',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
            const Text(
              'Trạm Điều Phối & Nhiệm Vụ Kiểm Định',
              style: TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => ref.read(inspectionProvider.notifier).fetchOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => ref.read(inspectionProvider.notifier).setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm thiết bị, người bán, mã đơn...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.slate400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    fillColor: AppColors.slate50,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(ref, 'ALL', 'Tất cả (${inspectionState.orders.length})', inspectionState.activeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip(ref, 'SCHEDULED', 'Cần đi kiểm định', inspectionState.activeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip(ref, 'INSPECTING', 'Đang thực hiện', inspectionState.activeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip(ref, 'COMPLETED', 'Đã hoàn tất', inspectionState.activeFilter),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: inspectionState.filteredOrders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: AppColors.slate400),
                        SizedBox(height: 12),
                        Text(
                          'Không có đơn kiểm định phù hợp',
                          style: TextStyle(color: AppColors.slate600, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: inspectionState.filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = inspectionState.filteredOrders[index];
                      return _buildOrderCard(context, ref, order, currencyFormatter, dateFormatter);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String key, String label, String currentFilter) {
    final isSelected = currentFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(inspectionProvider.notifier).setFilter(key),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.slate700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      backgroundColor: AppColors.slate50,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    WidgetRef ref,
    InspectionOrder order,
    NumberFormat currencyFormatter,
    DateFormat dateFormatter,
  ) {
    Color statusBg;
    Color statusText;
    switch (order.status) {
      case 'INSPECTING':
        statusBg = AppColors.amberLight;
        statusText = AppColors.secondary;
        break;
      case 'PASSED':
        statusBg = AppColors.passGreenLight;
        statusText = AppColors.passGreen;
        break;
      case 'FAILED':
        statusBg = AppColors.failRedLight;
        statusText = AppColors.failRed;
        break;
      default:
        statusBg = AppColors.primaryContainer;
        statusText = AppColors.primaryDark;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ref.read(inspectionProvider.notifier).selectOrder(order);
          context.push('/order-detail', extra: order);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate900),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.isAtHome ? Colors.blue.shade50 : Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: order.isAtHome ? Colors.blue.shade200 : Colors.purple.shade200,
                      ),
                    ),
                    child: Text(
                      order.isAtHome ? 'TẠI NHÀ' : 'TẠI TRUNG TÂM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: order.isAtHome ? Colors.blue.shade800 : Colors.purple.shade800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusText),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: AppColors.slate200),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.postImageUrls.isNotEmpty
                          ? order.postImageUrls.first
                          : 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=300',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 72,
                        height: 72,
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
                          order.postTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(order.postPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_pin, size: 16, color: AppColors.slate600),
                        const SizedBox(width: 6),
                        Text(
                          'Người bán: ${order.sellerName}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.slate800),
                        ),
                        const Spacer(),
                        Text(
                          order.sellerPhone ?? '',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.slate500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.sellerAddress ?? 'Địa chỉ chưa cập nhật',
                            style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Text(
                    order.appointmentScheduledAt != null
                        ? dateFormatter.format(order.appointmentScheduledAt!)
                        : 'Chưa xếp lịch',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate800),
                  ),
                  const Spacer(),
                  if (order.isAtHome) ...[
                    const Icon(Icons.directions_bike_rounded, size: 16, color: AppColors.mapBlue),
                    const SizedBox(width: 4),
                    Text(
                      '${order.travelDistanceKm} km (+${currencyFormatter.format(order.travelFee)})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mapBlue),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(inspectionProvider.notifier).selectOrder(order);
                        context.push('/order-detail', extra: order);
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Chi Tiết'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(inspectionProvider.notifier).selectOrder(order);
                        context.push('/checklist-execution', extra: order);
                      },
                      icon: const Icon(Icons.fact_check_outlined, size: 16),
                      label: Text(order.status == 'INSPECTING' ? 'Tiếp Tục Chấm' : 'Chấm Checklist'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: order.status == 'INSPECTING' ? AppColors.secondary : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
