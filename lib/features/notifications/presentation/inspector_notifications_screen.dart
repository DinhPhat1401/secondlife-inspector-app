import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';

class InspectorNotificationsScreen extends StatefulWidget {
  const InspectorNotificationsScreen({super.key});

  @override
  State<InspectorNotificationsScreen> createState() => _InspectorNotificationsScreenState();
}

class _InspectorNotificationsScreenState extends State<InspectorNotificationsScreen> {
  final ApiClient _api = ApiClient();
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _api.dio.get(ApiEndpoints.notifications);
      final raw = response.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final inner = raw['data'] ?? raw['items'] ?? raw['content'];
        if (inner is List) {
          list = inner;
        }
      }
      if (mounted) {
        setState(() {
          _notifications = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
          _errorMessage = 'Không thể tải danh sách thông báo';
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.dio.put(ApiEndpoints.markAllNotificationsRead);
      setState(() {
        for (final n in _notifications) {
          n['isRead'] = true;
          n['read'] = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu đọc tất cả thông báo')),
        );
      }
    } catch (_) {}
  }

  Future<void> _markOneAsRead(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString();
    if (id.isEmpty) return;
    try {
      await _api.dio.put(ApiEndpoints.markNotificationRead(id));
      if (mounted) {
        setState(() {
          item['isRead'] = true;
          item['read'] = true;
        });
      }
    } catch (_) {}
  }

  String _resolveType(Map<String, dynamic> item) {
    final rawType = (item['type'] ?? item['category'] ?? '').toString().toLowerCase();
    if (rawType.contains('order') || rawType.contains('inspect') || rawType.contains('dispatch')) {
      return 'order';
    }
    if (rawType.contains('wallet') || rawType.contains('payout') || rawType.contains('fee')) {
      return 'payout';
    }
    if (rawType.contains('hub') || rawType.contains('system')) {
      return 'hub';
    }
    return 'other';
  }

  String _formatTime(dynamic rawTime) {
    if (rawTime == null) return '';
    final parsed = DateTime.tryParse(rawTime.toString());
    if (parsed == null) return rawTime.toString();
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'all'
        ? _notifications
        : _notifications.where((n) => _resolveType(n) == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông Báo Kỹ Thuật Viên', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        elevation: 0.5,
        backgroundColor: Colors.white,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Đọc tất cả', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          IconButton(
            onPressed: _fetchNotifications,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.slate400),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, style: const TextStyle(color: AppColors.slate600, fontSize: 14)),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _fetchNotifications,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 140),
                                Icon(Icons.notifications_off_outlined, size: 54, color: AppColors.slate400),
                                SizedBox(height: 12),
                                Center(
                                  child: Text('Không có thông báo nào', style: TextStyle(color: AppColors.slate600, fontSize: 14)),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final isRead = (item['isRead'] as bool?) ?? (item['read'] as bool?) ?? false;
                                final type = _resolveType(item);
                                final title = (item['title'] ?? 'Thông báo hệ thống').toString();
                                final message = (item['message'] ?? item['content'] ?? '').toString();
                                final timeText = _formatTime(item['createdAt'] ?? item['time']);
                                final orderId = (item['orderId'] ?? item['referenceId'])?.toString();

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
                                    icon = Icons.notifications_outlined;
                                    iconColor = Colors.amber.shade800;
                                    iconBg = Colors.amber.shade50;
                                }

                                return InkWell(
                                  onTap: () => _markOneAsRead(item),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
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
                                                      title,
                                                      style: TextStyle(
                                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                        fontSize: 14,
                                                        color: AppColors.slate900,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    timeText,
                                                    style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                message,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isRead ? AppColors.slate600 : AppColors.slate800,
                                                  height: 1.4,
                                                ),
                                              ),
                                              if (orderId != null && orderId.isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                SizedBox(
                                                  height: 32,
                                                  child: OutlinedButton.icon(
                                                    onPressed: () {
                                                      _markOneAsRead(item);
                                                      context.push('/order-detail', extra: orderId);
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
                                  ),
                                );
                              },
                            ),
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
