import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inspection/providers/inspector_stats_provider.dart';

class InspectorProfileScreen extends ConsumerWidget {
  const InspectorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final statsState = ref.watch(inspectorStatsProvider);
    final stats = statsState.stats;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    final badgeCode = stats?.badgeCode.isNotEmpty == true
        ? stats!.badgeCode
        : (auth.badgeCode ?? 'SL-TECH-F9B1');

    final certTitle = auth.certificationTitle ??
        stats?.skillLevel ??
        'Kỹ thuật viên Thẩm định Thiết bị Bậc 3';

    final stationHub = auth.stationHubName ?? 'Trung Tâm SecondLife - Trạm Khu CNC Thủ Đức';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ Sơ & Thu Nhập KTV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Lịch sử đối soát',
            onPressed: () => context.push('/payouts'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.failRed),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(authProvider.notifier).fetchProfile(),
            ref.read(inspectorStatsProvider.notifier).refreshAll(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Professional Inspector ID Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber, width: 2.5),
                          ),
                          child: const CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.engineering, size: 36, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      auth.inspectorName.isNotEmpty ? auth.inspectorName : 'Kỹ Thuật Viên',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, color: Colors.amber, size: 20),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                auth.email.isNotEmpty ? auth.email : 'inspector@secondlife.com',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.badge_outlined, size: 12, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          badgeCode,
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30, color: Colors.white24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProfileStat(
                          'Đơn Đã Xử Lý',
                          '${stats?.completedJobs ?? auth.completedJobs}',
                        ),
                        Container(height: 32, width: 1, color: Colors.white24),
                        _buildProfileStat(
                          'Đánh Giá KTV',
                          '${(stats?.averageRating ?? 5.0).toStringAsFixed(1)} ⭐',
                        ),
                        Container(height: 32, width: 1, color: Colors.white24),
                        _buildProfileStat(
                          'Đúng Hẹn',
                          '${(stats?.onTimeRate ?? 100.0).toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Wallet & Earnings Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: AppColors.passGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Thu Nhập Tháng ${statsState.selectedMonth}/${statsState.selectedYear}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.slate900),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Chờ: ${currencyFormatter.format(stats?.pendingSettlementAmount ?? 0.0)}',
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        currencyFormatter.format(stats?.monthlyEarnings ?? 0.0),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.slate900),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tổng thù lao kỹ thuật và phụ cấp di chuyển đã hoàn tất trong tháng.',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Thù lao kỹ thuật theo đơn:', style: TextStyle(color: AppColors.slate600, fontSize: 13)),
                          Text(
                            currencyFormatter.format(stats?.laborFeeEarned ?? 0.0),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Phụ cấp xăng xe & di chuyển:', style: TextStyle(color: AppColors.slate600, fontSize: 13)),
                          Text(
                            currencyFormatter.format(stats?.travelAllowanceEarned ?? 0.0),
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.mapBlue, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/payouts'),
                          icon: const Icon(Icons.receipt_long_outlined, size: 16),
                          label: const Text('Xem Lịch Sử Đối Soát Thù Lao'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Station & Certification Information Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.hub_outlined, color: AppColors.primary),
                      title: const Text('Trạm kỹ thuật điều phối', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        stationHub,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate700),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.verified_outlined, color: Colors.amber),
                      title: const Text('Chứng chỉ chuyên môn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        certTitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate700),
                      ),
                    ),
                    if (auth.phone != null && auth.phone!.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone_iphone_outlined, color: AppColors.primary),
                        title: const Text('Số điện thoại kỹ thuật viên', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          auth.phone!,
                          style: const TextStyle(fontSize: 12, color: AppColors.slate700),
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                      title: const Text('Sổ tay quy chuẩn kiểm định', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Quy trình kiểm tra 20 bước & chuẩn dán tem niêm phong số', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quy chuẩn kỹ thuật đã đồng bộ phiên bản 2026.')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.support_agent_outlined, color: AppColors.primary),
                      title: const Text('Tổng đài hỗ trợ điều phối trạm 24/7', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Hotline điều phối: 1900 8821', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.call, size: 18, color: AppColors.primary),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // End shift / Logout
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.exit_to_app, color: AppColors.failRed),
                label: const Text('KẾT THÚC CA TRỰC (ĐĂNG XUẤT)', style: TextStyle(color: AppColors.failRed, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.failRed),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
