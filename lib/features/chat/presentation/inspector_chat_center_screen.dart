import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class InspectorChatCenterScreen extends StatefulWidget {
  const InspectorChatCenterScreen({super.key});

  @override
  State<InspectorChatCenterScreen> createState() => _InspectorChatCenterScreenState();
}

class _InspectorChatCenterScreenState extends State<InspectorChatCenterScreen> {
  final List<Map<String, dynamic>> _mockConversations = [
    {
      'id': 'chat-1',
      'name': 'Điều Phối Viên Trạm Thủ Đức',
      'role': 'Điều phối viên ca trực',
      'lastMessage': 'Anh kiểm tra xong đơn #ORD-8821 thì gửi biên bản niêm phong nhé.',
      'time': '12:30',
      'unread': 1,
      'isOnline': true,
      'icon': Icons.hub_outlined,
    },
    {
      'id': 'chat-2',
      'name': 'Hỗ Trợ Kỹ Thuật Nghiệp Vụ 24/7',
      'role': 'Bộ phận thẩm định kỹ thuật',
      'lastMessage': 'Quy trình đo áp suất block tủ lạnh Inverter đã gửi qua tài liệu hướng dẫn.',
      'time': 'Hôm qua',
      'unread': 0,
      'isOnline': true,
      'icon': Icons.support_agent_outlined,
    },
    {
      'id': 'chat-3',
      'name': 'Khách hàng: Nguyễn Văn An (#ORD-8821)',
      'role': 'Người bán - Hẹn kiểm định tận nơi',
      'lastMessage': 'Em đang ở nhà, anh tới lúc 14:00 đúng giờ nhé.',
      'time': '09:15',
      'unread': 0,
      'isOnline': false,
      'icon': Icons.person_outline_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tin Nhắn & Hỗ Trợ Điều Phối', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        elevation: 0.5,
        backgroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _mockConversations.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72, color: AppColors.cardBorder),
        itemBuilder: (context, index) {
          final conv = _mockConversations[index];
          final unread = conv['unread'] as int;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(conv['icon'] as IconData, color: AppColors.primaryDark, size: 24),
                ),
                if (conv['isOnline'] == true)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.passGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    conv['name'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  conv['time'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: unread > 0 ? AppColors.primary : AppColors.slate400,
                    fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  conv['role'] as String,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  conv['lastMessage'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: unread > 0 ? AppColors.slate900 : AppColors.slate600,
                    fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            trailing: unread > 0
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang kết nối hội thoại: ${conv['name']}')),
              );
            },
          );
        },
      ),
    );
  }
}
