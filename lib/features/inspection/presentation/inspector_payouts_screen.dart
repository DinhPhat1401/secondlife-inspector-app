import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/inspector_stats_models.dart';
import '../providers/inspection_provider.dart';
import '../providers/inspector_stats_provider.dart';

class InspectorPayoutsScreen extends ConsumerStatefulWidget {
  const InspectorPayoutsScreen({super.key});

  @override
  ConsumerState<InspectorPayoutsScreen> createState() => _InspectorPayoutsScreenState();
}

class _InspectorPayoutsScreenState extends ConsumerState<InspectorPayoutsScreen> {
  final ScrollController _scrollController = ScrollController();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final dateFormatter = DateFormat('HH:mm - dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(inspectorStatsProvider.notifier).loadMorePayouts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(inspectorStatsProvider);
    final filteredList = statsState.filteredPayouts;

    double totalSettledAmount = 0.0;
    for (final p in statsState.payouts) {
      if (p.isSettled) {
        totalSettledAmount += p.totalPayout;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch Sử Đối Soát Thù Lao'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () => ref.read(inspectorStatsProvider.notifier).fetchPayouts(page: 0, refresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(inspectorStatsProvider.notifier).fetchPayouts(page: 0, refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Top Summary Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified_outlined, color: Colors.amber, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Quyết Toán Thù Lao KTV',
                                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${statsState.payoutsTotalElements} giao dịch',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currencyFormatter.format(totalSettledAmount),
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tổng thù lao & phụ cấp đã quyết toán',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Filter Chips Bar
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'Tất cả (${statsState.payouts.length})', statsState.payoutsFilterStatus),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'SETTLED',
                      'Đã quyết toán (${statsState.payouts.where((p) => p.isSettled).length})',
                      statsState.payoutsFilterStatus,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'PENDING',
                      'Chờ quyết toán (${statsState.payouts.where((p) => !p.isSettled).length})',
                      statsState.payoutsFilterStatus,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Content List
            if (statsState.isLoadingPayouts)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (statsState.payoutsError != null && filteredList.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.failRed),
                        const SizedBox(height: 12),
                        Text(
                          statsState.payoutsError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.slate600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(inspectorStatsProvider.notifier).fetchPayouts(page: 0, refresh: true),
                          child: const Text('Thử Lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (filteredList.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.slate400),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có dữ liệu đối soát thù lao nào.',
                        style: TextStyle(color: AppColors.slate600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == filteredList.length) {
                        return statsState.isLoadingMorePayouts
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox(height: 40);
                      }
                      final item = filteredList[index];
                      return _buildPayoutCard(item);
                    },
                    childCount: filteredList.length + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String status, String label, String activeStatus) {
    final isSelected = status == activeStatus;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryDark : AppColors.slate600,
      ),
      onSelected: (_) {
        ref.read(inspectorStatsProvider.notifier).setPayoutsFilter(status);
      },
    );
  }

  Widget _buildPayoutCard(InspectorPayout item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Navigate to order detail
          final orders = ref.read(inspectionProvider).orders;
          final match = orders.where((o) => o.id == item.orderId).firstOrNull;
          if (match != null) {
            context.push('/order-detail', extra: match);
          } else {
            // Push with orderId
            context.push('/order-detail', extra: item.orderId);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Badges & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isAtHome ? AppColors.mapBlue.withValues(alpha: 0.12) : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isAtHome ? '📍 Tận nơi' : '🏢 Tại trạm',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.isAtHome ? AppColors.mapBlue : Colors.purple.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.payoutId,
                        style: const TextStyle(fontSize: 11, color: AppColors.slate400, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isSettled ? AppColors.passGreen.withValues(alpha: 0.12) : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isSettled ? 'Đã quyết toán' : 'Chờ quyết toán',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.isSettled ? AppColors.passGreen : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title & Total payout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.postTitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${currencyFormatter.format(item.totalPayout)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.passGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Sub fees and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Tiền công: ${currencyFormatter.format(item.laborFee)}'
                      '${item.travelFee > 0 ? " + Phụ cấp: ${currencyFormatter.format(item.travelFee)}" : ""}',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                    ),
                  ),
                  if (item.completedAt != null)
                    Text(
                      dateFormatter.format(item.completedAt!.toLocal()),
                      style: const TextStyle(fontSize: 11, color: AppColors.slate400),
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
