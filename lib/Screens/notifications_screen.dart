import 'package:flutter/material.dart';

import '../core/theme/app_style.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import 'public_user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool isLoading = true;
  bool soundAlerts = true;
  List notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final data = await ApiService.getNotifications();

    if (!mounted) return;

    setState(() {
      notifications = data;
      isLoading = false;
    });

    await ApiService.markNotificationsRead();
  }

  Future<void> clearAll() async {
    await ApiService.clearNotifications();
    if (!mounted) return;
    setState(() => notifications = []);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        notifications.where((item) => item['isRead'] == false).length;

    return Scaffold(
      backgroundColor: AppStyle.scaffold,
      appBar: AppStyle.primaryAppBar(
        context,
        title: 'Notifications ($unreadCount)',
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppStyle.surfaceTint),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Mode: Active | Sound Alerts',
                  style: TextStyle(color: AppStyle.textMuted, fontSize: 13),
                ),
                const Spacer(),
                Switch(
                  value: soundAlerts,
                  activeColor: AppStyle.primary,
                  onChanged: (value) {
                    setState(() => soundAlerts = value);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? const Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchNotifications,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _notificationCard(notifications[index]);
                          },
                        ),
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppStyle.surfaceTint)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: notifications.isEmpty ? null : clearAll,
                    child: Text('Clear All (${notifications.length})'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyle.primary,
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Allow Notifications',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(Map notification) {
    final type = notification['type'] ?? 'message';
    final accent = _accentColor(type);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openNotification(notification),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppStyle.cardDecoration(radius: 16).copyWith(
          border: Border.all(color: AppStyle.surfaceTint),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: accent.withOpacity(0.14),
            child: Icon(_iconFor(type), color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? 'Notification',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppStyle.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  notification['body'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppStyle.textMuted),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      type == 'message'
                          ? Icons.phone_in_talk_outlined
                          : Icons.access_time,
                      size: 14,
                      color: type == 'message' ? Colors.blue : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      type == 'message'
                          ? 'Tap for instant reply'
                          : _formatDate(notification['createdAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: type == 'message' ? Colors.blue : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _openNotification(Map notification) async {
    if (notification['type'] == 'rating') {
      final meta = notification['meta'];
      final raterId = meta is Map ? meta['raterId']?.toString() : null;
      if (!mounted || raterId == null || raterId.isEmpty) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicUserProfileScreen(userId: raterId),
        ),
      );
      return;
    }

    if (notification['type'] != 'message') return;

    final meta = notification['meta'];
    final conversationId =
        meta is Map ? meta['conversationId']?.toString() : null;

    if (conversationId == null) return;

    final conversations = await ApiService.getConversations();
    final conversation = conversations.cast<Map?>().firstWhere(
          (item) => item?['_id'] == conversationId,
          orElse: () => null,
        );

    if (!mounted || conversation == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conversation),
      ),
    );
  }

  Color _accentColor(String type) {
    switch (type) {
      case 'offer':
        return Colors.green;
      case 'approval':
        return const Color(0xff10b981);
      case 'reminder':
        return Colors.blue;
      case 'rating':
        return Colors.amber;
      default:
        return Colors.purple;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'offer':
        return Icons.shopping_cart_outlined;
      case 'approval':
        return Icons.check_circle_outline;
      case 'reminder':
        return Icons.pets;
      case 'rating':
        return Icons.star;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
