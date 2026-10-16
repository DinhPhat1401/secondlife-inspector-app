import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/inspection_order.dart';
import '../models/inspector_stats_models.dart';
import '../providers/inspection_provider.dart';
import '../providers/inspector_stats_provider.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final dateFormatter = DateFormat('HH:mm - dd/MM/yyyy');
  bool _isStatsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final inspectionState = ref.watch(inspectionProvider);
    final statsState = ref.watch(inspectorStatsProvider);
    final stats = statsState.stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    auth.inspectorName.isNotEmpty ? auth.inspectorName : 'Kỹ Thuật Viên',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                    overflow: TextOverflow.ellipsis,
                  ),
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
            Text(
              auth.stationHubName ?? 'Trạm Điều Phối & Nhiệm Vụ Kiểm Định',
              style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Đối soát thù lao',
            onPressed: () => context.push('/payouts'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () async {
              await Future.wait([
                ref.read(inspectionProvider.notifier).fetchOrders(),
                ref.read(inspectorStatsProvider.notifier).refreshAll(),
              ]);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(inspectionProvider.notifier).fetchOrders(),
            ref.read(inspectorStatsProvider.notifier).refreshAll(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // Dashboard KPI & Earnings Header Section
            SliverToBoxAdapter(
              child: _buildDashboardSection(auth, statsState, stats),
            ),

            // Search Box and Filter Chips Sticky Header
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Danh Sách Nhiệm Vụ',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate900),
                        ),
                        Text(
                          '${inspectionState.filteredOrders.length} đơn',
                          style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Orders List
            if (inspectionState.filteredOrders.isEmpty)
              const SliverFillRemaining(
                child: Center(
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
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = inspectionState.filteredOrders[index];
                      return _buildOrderCard(context, ref, order);
                    },
                    childCount: inspectionState.filteredOrders.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSection(
    AuthState auth,
    InspectorStatsState statsState,
    InspectorStats? stats,
  ) {
    final badgeCode = stats?.badgeCode.isNotEmpty == true
        ? stats!.badgeCode
        : (auth.badgeCode ?? 'SL-TECH-F9B1');

    final skillLevel = stats?.skillLevel.isNotEmpty == true
        ? stats!.skillLevel
        : (auth.certificationTitle ?? 'Kỹ thuật viên Thẩm định Bậc 3');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Inspector Header with Badge & Month Picker
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.engineering, size: 22, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            stats?.inspectorName.isNotEmpty == true
                                ? stats!.inspectorName
                                : auth.inspectorName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.passGreen.withValues(alpha: 0.12),
                            border: Border.all(color: AppColors.passGreen, width: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeCode,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.passGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      skillLevel,
                      style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Month Selector Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Tháng trước',
                    onPressed: () {
                      int newMonth = statsState.selectedMonth - 1;
                      int newYear = statsState.selectedYear;
                      if (newMonth < 1) {
                        newMonth = 12;
                        newYear--;
                      }
                      ref.read(inspectorStatsProvider.notifier).changeMonthYear(newMonth, newYear);
                    },
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'T${statsState.selectedMonth}/${statsState.selectedYear}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate800),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Tháng sau',
                    onPressed: () {
                      int newMonth = statsState.selectedMonth + 1;
                      int newYear = statsState.selectedYear;
                      if (newMonth > 12) {
                        newMonth = 1;
                        newYear++;
                      }
                      ref.read(inspectorStatsProvider.notifier).changeMonthYear(newMonth, newYear);
                    },
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => setState(() => _isStatsExpanded = !_isStatsExpanded),
                    child: Icon(
                      _isStatsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 22,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_isStatsExpanded) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // KPI Cards Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Đã Hoàn Thành', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats?.completedJobs ?? 0} đơn',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${stats?.passedJobs ?? 0} Đạt • ${stats?.failedJobs ?? 0} Hỏng',
                          style: const TextStyle(fontSize: 10, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text('Đánh Giá & Lịch', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${(stats?.averageRating ?? 5.0).toStringAsFixed(1)} ★',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đúng giờ: ${(stats?.onTimeRate ?? 100.0).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 10, color: AppColors.passGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Wallet & Earnings Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // light green bg
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.passGreen),
                          SizedBox(width: 6),
                          Text(
                            'Thu Nhập Tháng Này',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.passGreen),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => context.push('/payouts'),
                        child: const Row(
                          children: [
                            Text(
                              'Đối soát thù lao',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormatter.format(stats?.monthlyEarnings ?? 0.0),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.slate900),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFBBF7D0)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🔧 Tiền công: ${currencyFormatter.format(stats?.laborFeeEarned ?? 0.0)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.slate700),
                      ),
                      Text(
                        '🛵 Phụ cấp: ${currencyFormatter.format(stats?.travelAllowanceEarned ?? 0.0)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.mapBlue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '⏳ Đang chờ quyết toán: ${currencyFormatter.format(stats?.pendingSettlementAmount ?? 0.0)}',
                    style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      elevation: 0,
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
                      errorBuilder: (context, url, error) => Container(
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
