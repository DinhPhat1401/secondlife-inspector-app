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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Nhập Trạm / Check-in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: () => _showHubCheckInDialog(context),
      ),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                height: 36,
                width: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.engineering, color: AppColors.primaryDark, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          auth.inspectorName.isNotEmpty ? auth.inspectorName : 'Kỹ Thuật Viên',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Trực Ca',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    auth.stationHubName ?? 'Trung tâm kiểm định',
                    style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.normal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 23),
            tooltip: 'Tin nhắn điều phối',
            onPressed: () => context.push('/chats'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 26),
            tooltip: 'Thông báo nhiệm vụ',
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 6),
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
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 60, color: AppColors.slate400),
                        SizedBox(height: 10),
                        Text(
                          'Không có đơn kiểm định phù hợp',
                          style: TextStyle(color: AppColors.slate600, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
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
    final defaultBadge = auth.inspectorId.isNotEmpty
        ? 'INS-${auth.inspectorId.substring(0, auth.inspectorId.length > 8 ? 8 : auth.inspectorId.length).toUpperCase()}'
        : 'INSPECTOR';

    final badgeCode = stats?.badgeCode.isNotEmpty == true
        ? stats!.badgeCode
        : (auth.badgeCode ?? defaultBadge);

    final skillLevel = stats?.skillLevel.isNotEmpty == true
        ? stats!.skillLevel
        : (auth.certificationTitle ?? auth.badgeTitle);

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
          // Row 1: Inspector Identity (Avatar, Name, Skill, Badge)
          Row(
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
                    Text(
                      stats?.inspectorName.isNotEmpty == true
                          ? stats!.inspectorName
                          : auth.inspectorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate900),
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 8),
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
          const SizedBox(height: 10),

          // Row 2: Month Filter & Expand/Collapse Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.slate600),
                const SizedBox(width: 6),
                const Text(
                  'Tháng:',
                  style: TextStyle(fontSize: 12, color: AppColors.slate600, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    int newMonth = statsState.selectedMonth - 1;
                    int newYear = statsState.selectedYear;
                    if (newMonth < 1) {
                      newMonth = 12;
                      newYear--;
                    }
                    ref.read(inspectorStatsProvider.notifier).changeMonthYear(newMonth, newYear);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_left, size: 18, color: AppColors.slate700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    'T${statsState.selectedMonth}/${statsState.selectedYear}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate800),
                  ),
                ),
                InkWell(
                  onTap: () {
                    int newMonth = statsState.selectedMonth + 1;
                    int newYear = statsState.selectedYear;
                    if (newMonth > 12) {
                      newMonth = 1;
                      newYear++;
                    }
                    ref.read(inspectorStatsProvider.notifier).changeMonthYear(newMonth, newYear);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_right, size: 18, color: AppColors.slate700),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _isStatsExpanded = !_isStatsExpanded),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isStatsExpanded ? 'Thu gọn' : 'Chi tiết',
                          style: const TextStyle(fontSize: 11, color: AppColors.slate600, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isStatsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.slate600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                              (stats?.completedJobs ?? 0) > 0 && (stats?.averageRating ?? 0.0) > 0
                                  ? (stats!.averageRating).toStringAsFixed(1)
                                  : '--',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: (stats?.completedJobs ?? 0) > 0 && (stats?.averageRating ?? 0.0) > 0
                                    ? Colors.amber
                                    : AppColors.slate400,
                              ),
                            ),
                            if ((stats?.completedJobs ?? 0) > 0 && (stats?.averageRating ?? 0.0) > 0) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (stats?.completedJobs ?? 0) > 0
                              ? 'Đúng giờ: ${(stats?.onTimeRate ?? 0.0).toStringAsFixed(1)}%'
                              : 'Chưa có lượt đánh giá',
                          style: TextStyle(
                            fontSize: 10,
                            color: (stats?.completedJobs ?? 0) > 0 ? AppColors.passGreen : AppColors.slate500,
                            fontWeight: FontWeight.w500,
                          ),
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
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.handyman_outlined, size: 14, color: AppColors.slate600),
                          const SizedBox(width: 4),
                          Text(
                            'Tiền công: ${currencyFormatter.format(stats?.laborFeeEarned ?? 0.0)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.slate700),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.two_wheeler_outlined, size: 14, color: AppColors.mapBlue),
                          const SizedBox(width: 4),
                          Text(
                            'Phụ cấp: ${currencyFormatter.format(stats?.travelAllowanceEarned ?? 0.0)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.mapBlue, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hourglass_empty_rounded, size: 13, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            'Đang chờ quyết toán: ${currencyFormatter.format(stats?.pendingSettlementAmount ?? 0.0)}',
                            style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
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
                    '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate900),
                  ),
                  const SizedBox(width: 6),
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
                    child: order.postImageUrls.isNotEmpty && order.postImageUrls.first.trim().isNotEmpty
                        ? Image.network(
                            order.postImageUrls.first,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, url, error) => Container(
                              width: 72,
                              height: 72,
                              color: AppColors.slate100,
                              child: const Icon(Icons.devices, color: AppColors.slate400),
                            ),
                          )
                        : Container(
                            width: 72,
                            height: 72,
                            color: AppColors.slate100,
                            child: const Icon(Icons.devices, color: AppColors.slate400),
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
                        Expanded(
                          child: Text(
                            'Người bán: ${order.sellerName}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.slate800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (order.sellerPhone != null && order.sellerPhone!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            order.sellerPhone!,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
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
                  Expanded(
                    child: Text(
                      order.appointmentScheduledAt != null
                          ? dateFormatter.format(order.appointmentScheduledAt!)
                          : 'Chưa xếp lịch',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order.isAtHome) ...[
                    const SizedBox(width: 8),
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

  void _showHubCheckInDialog(BuildContext context) {
    final barcodeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Check-in Nhập Trạm / Hub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập mã Barcode hoặc mã kiện hàng trên bưu phẩm shipper bàn giao tới Trạm để xác nhận tiếp nhận:',
              style: TextStyle(fontSize: 12, color: AppColors.slate600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: barcodeCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Mã Barcode / Check-in',
                hintText: 'VD: INSP-2026-..., hoặc mã bưu gửi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.barcode_reader),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final code = barcodeCtrl.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);

              final orders = ref.read(inspectionProvider).orders;
              final matched = orders.where((o) =>
                  o.id.toLowerCase().contains(code.toLowerCase()) ||
                  (o.barcode != null && o.barcode!.toLowerCase().contains(code.toLowerCase()))
              ).firstOrNull;

              if (matched != null) {
                ref.read(inspectionProvider.notifier).selectOrder(matched);
                context.push('/order-detail', extra: matched);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã tìm thấy đơn #${matched.id.substring(0, 8)} tương ứng mã $code'),
                    backgroundColor: AppColors.passGreen,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Không tìm thấy đơn kiểm định nào khớp mã $code'),
                    backgroundColor: AppColors.failRed,
                  ),
                );
              }
            },
            child: const Text('Tra Cứu & Tiếp Nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
