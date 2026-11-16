import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';

class InspectorChatCenterScreen extends StatefulWidget {
  const InspectorChatCenterScreen({super.key});

  @override
  State<InspectorChatCenterScreen> createState() => _InspectorChatCenterScreenState();
}

class _InspectorChatCenterScreenState extends State<InspectorChatCenterScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _api.dio.get(ApiEndpoints.chats);
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
          _conversations = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _conversations = [];
          _isLoading = false;
          _errorMessage = 'Không thể tải danh sách hội thoại';
        });
      }
    }
  }

  String _formatTime(dynamic rawTime) {
    if (rawTime == null) return '';
    final parsed = DateTime.tryParse(rawTime.toString());
    if (parsed == null) return rawTime.toString();
    final local = parsed.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return DateFormat('HH:mm').format(local);
    }
    return DateFormat('dd/MM').format(local);
  }

  void _openConversationSheet(Map<String, dynamic> conv) {
    final roomId = (conv['id'] ?? conv['roomId'] ?? '').toString();
    final title = (conv['partnerName'] ?? conv['otherParticipantName'] ?? conv['postTitle'] ?? conv['name'] ?? 'Hội thoại').toString();
    if (roomId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ChatRoomSheet(
        api: _api,
        roomId: roomId,
        title: title,
      ),
    ).then((_) => _fetchConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tin Nhắn & Hỗ Trợ Điều Phối', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        elevation: 0.5,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _fetchConversations,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchConversations,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.slate400),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, style: const TextStyle(color: AppColors.slate600, fontSize: 14)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _fetchConversations,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _conversations.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 140),
                          Icon(Icons.chat_bubble_outline_rounded, size: 54, color: AppColors.slate400),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Chưa có cuộc hội thoại nào',
                              style: TextStyle(color: AppColors.slate600, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _conversations.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72, color: AppColors.cardBorder),
                        itemBuilder: (context, index) {
                          final conv = _conversations[index];
                          final name = (conv['partnerName'] ?? conv['otherParticipantName'] ?? conv['name'] ?? 'Người dùng SecondLife').toString();
                          final subtitle = (conv['postTitle'] ?? conv['role'] ?? 'Trao đổi đơn kiểm định').toString();
                          final lastMessage = (conv['lastMessage'] ?? conv['lastMessageContent'] ?? 'Chưa có tin nhắn').toString();
                          final timeText = _formatTime(conv['lastMessageAt'] ?? conv['updatedAt'] ?? conv['time']);
                          final unread = (conv['unreadCount'] as num?)?.toInt() ?? (conv['unread'] as num?)?.toInt() ?? 0;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: const CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryContainer,
                              child: Icon(Icons.person_outline_rounded, color: AppColors.primaryDark, size: 24),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                                      color: AppColors.slate900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  timeText,
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
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  lastMessage,
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
                            onTap: () => _openConversationSheet(conv),
                          );
                        },
                      ),
      ),
    );
  }
}

class _ChatRoomSheet extends StatefulWidget {
  final ApiClient api;
  final String roomId;
  final String title;

  const _ChatRoomSheet({
    required this.api,
    required this.roomId,
    required this.title,
  });

  @override
  State<_ChatRoomSheet> createState() => _ChatRoomSheetState();
}

class _ChatRoomSheetState extends State<_ChatRoomSheet> {
  final TextEditingController _msgController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final res = await widget.api.dio.get(ApiEndpoints.chatMessages(widget.roomId));
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final inner = raw['data'] ?? raw['items'] ?? raw['content'];
        if (inner is List) list = inner;
      }
      if (mounted) {
        setState(() {
          _messages = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await widget.api.dio.post(
        ApiEndpoints.chatMessages(widget.roomId),
        data: {'content': text, 'type': 'TEXT'},
      );
      _msgController.clear();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi tin nhắn: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              ListTile(
                title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? const Center(
                            child: Text('Chưa có tin nhắn trong cuộc trò chuyện này', style: TextStyle(color: AppColors.slate500)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (ctx, i) {
                              final m = _messages[i];
                              final content = (m['content'] ?? m['message'] ?? '').toString();
                              final sender = (m['senderName'] ?? '').toString();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sender.isNotEmpty)
                                      Text(
                                        sender,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    Text(content, style: const TextStyle(fontSize: 13, color: AppColors.slate900)),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
