import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class InspectorNotificationsScreen extends StatefulWidget {
  const InspectorNotificationsScreen({super.key});

  @override
  State<InspectorNotificationsScreen> createState() => _InspectorNotificationsScreenState();
}

class _InspectorNotificationsScreenState extends State<InspectorNotificationsScreen> {
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': 'notif-1',
      'title': 'Phân công nhiệm vụ mới',
      'message': 'Đơn kiểm định #ORD-8821 đã được gán cho bạn tại Quận 9 (Tận nơi). Vui lòng xác nhận lộ trình.',
      'time': '10 phút trước',
      'type': 'order',
      'isRead': false,
      'orderId': 'ORD-8821',
    },
    {
      'id': 'notif-2',
      'title': 'Đối soát thù lao tuần thành công',
      'message': 'Khoản thù lao 2.450.000 ₫ cho 6 ca kiểm định hoàn tất đã được chuyển vào tài khoản định danh.',
      'time': '2 giờ trước',
      'type': 'payout',
      'isRead': false,
    },
    {
      'id': 'notif-3',
      'title': 'Thông báo từ Trạm Điều Phối Thủ Đức',
      'message': 'Quy chuẩn kiểm tra tem niêm phong số 2026 đã được cập nhật vào cẩm nang kỹ thuật của bạn.',
      'time': '1 ngày trước',
      'type': 'hub',
      'isRead': true,
    },
    {
      'id': 'notif-4',
      'title': 'Khách hàng đánh giá 5 sao',
      'message': 'Người mua tại đơn #ORD-7712 đã đánh giá tác phong kiểm định kỹ lưỡng, đúng hẹn và minh bạch.',
      'time': '2 ngày trước',
      'type': 'rating',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'all'
        ? _mockNotifications
        : _mockNotifications.where((n) => n['type'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông Báo Kỹ Thuật Viên', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        elevation: 0.5,
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _mockNotifications) {
                  n['isRead'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu đọc tất cả thông báo')),
              );
            },
            child: const Text('Đọc tất cả', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Phân công đơn', 'order'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Thù lao', 'payout'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Trạm điều phối', 'hub'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Notification List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 54, color: AppColors.slate400),
                        SizedBox(height: 12),
                        Text('Không có thông báo nào', style: TextStyle(color: AppColors.slate600, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isRead = item['isRead'] as bool;
                      final type = item['type'] as String;

                      IconData icon;
                      Color iconColor;
                      Color iconBg;

                      switch (type) {
                        case 'order':
                          icon = Icons.assignment_turned_in_outlined;
                          iconColor = AppColors.primary;
                          iconBg = AppColors.primaryContainer;
                          break;
                        case 'payout':
                          icon = Icons.account_balance_wallet_outlined;
                          iconColor = AppColors.passGreen;
                          iconBg = const Color(0xFFDCFCE7);
                          break;
                        case 'hub':
                          icon = Icons.hub_outlined;
                          iconColor = AppColors.mapBlue;
                          iconBg = const Color(0xFFDBEAFE);
                          break;
                        default:
                          icon = Icons.star_outline_rounded;
                          iconColor = Colors.amber.shade800;
                          iconBg = Colors.amber.shade50;
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRead ? AppColors.cardBorder : Colors.amber.shade200,
                            width: isRead ? 1 : 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: iconColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title'] as String,
                                          style: TextStyle(
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.slate900,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        item['time'] as String,
                                        style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['message'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isRead ? AppColors.slate600 : AppColors.slate800,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (item['orderId'] != null) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 32,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() => item['isRead'] = true);
                                          context.push('/order-detail', extra: item['orderId']);
                                        },
                                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                        label: const Text('Xem chi tiết đơn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.slate700,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.slate200),
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }
}
