import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class InspectorProfileScreen extends ConsumerWidget {
  const InspectorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ & Thu Nhập KTV'),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                                    auth.inspectorName,
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
                              auth.badgeTitle,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Mã thẻ: SL-TECH-8821',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
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
                      _buildProfileStat('Đơn Đã Xử Lý', '${auth.completedJobs}'),
                      Container(height: 32, width: 1, color: Colors.white24),
                      _buildProfileStat('Đánh Giá KTV', '${auth.rating} ⭐'),
                      Container(height: 32, width: 1, color: Colors.white24),
                      _buildProfileStat('Đúng Hẹn', '98.6%'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppColors.passGreen),
                        const SizedBox(width: 8),
                        const Text(
                          'Thu Nhập & Phụ Cấp Tháng Này',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.slate900),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.passGreenLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Đã duyệt',
                            style: TextStyle(color: AppColors.passGreen, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currencyFormatter.format(auth.monthlyEarnings),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.slate900),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Thù lao kỹ thuật theo đơn:', style: TextStyle(color: AppColors.slate600, fontSize: 13)),
                        Text(currencyFormatter.format(14200000), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phụ cấp xăng xe & di chuyển:', style: TextStyle(color: AppColors.slate600, fontSize: 13)),
                        Text(currencyFormatter.format(4250000),
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.mapBlue, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.hub_outlined, color: AppColors.primary),
                    title: const Text('Trạm kỹ thuật điều phối', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Trung Tâm SecondLife - Khu CNC Thủ Đức', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                    title: const Text('Sổ tay quy chuẩn kiểm định', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tài liệu hướng dẫn an toàn & quy trình dán tem', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.verified_outlined, color: AppColors.amber),
                    title: const Text('Chứng chỉ hành nghề', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Kỹ thuật viên Thiết bị Gia dụng & Cơ điện Bậc 4', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined, color: AppColors.primary),
                    title: const Text('Hỗ trợ kỹ thuật tổng đài 24/7', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Hotline điều phối: 1900 8821', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.call, size: 18, color: AppColors.primary),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.exit_to_app, color: AppColors.failRed),
              label: const Text('KẾT THÚC CA TRỰC (ĐĂNG XUẤT)', style: TextStyle(color: AppColors.failRed)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.failRed),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
          ],
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
