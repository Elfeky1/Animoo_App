import 'package:flutter/material.dart';

import '../core/theme/app_style.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  List conversations = [];
  List filteredConversations = [];

  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchConversations() async {
    final data = await ApiService.getConversations();

    if (!mounted) return;

    setState(() {
      conversations = data;
      filteredConversations = _applySearch(data, searchController.text);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.scaffold,
      appBar: AppStyle.primaryAppBar(context, title: 'Chats'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  filteredConversations = _applySearch(conversations, value);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search chats',
                prefixIcon: const Icon(Icons.search, color: AppStyle.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredConversations.isEmpty
                    ? const Center(
                        child: Text(
                          'No chats yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchConversations,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredConversations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _conversationTile(filteredConversations[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _conversationTile(Map conversation) {
    final ad = conversation['ad'] ?? {};
    final otherUser = conversation['otherUser'] ?? {};
    final images = ad['images'] ?? [];
    final lastMessage = conversation['lastMessage']?.toString() ?? '';
    final unreadCount = conversation['unreadCount'] ?? 0;
    final blockedByCurrent = conversation['blockedByCurrent'] == true;
    final lastMessagePrefix =
        conversation['lastMessageIsMine'] == true && lastMessage.isNotEmpty
            ? 'You: '
            : '';

    return Dismissible(
      key: ValueKey(conversation['_id']),
      direction: blockedByCurrent
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(conversation),
      child: Container(
        decoration: AppStyle.cardDecoration(radius: 16),
        child: ListTile(
          tileColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: images.isNotEmpty
                ? Image.network(
                    '${ApiService.baseUrl}/uploads/${images.first}',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 52,
                    height: 52,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.pets),
                  ),
          ),
          title: Text(
            otherUser['name'] ?? 'Chat',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppStyle.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About ${ad['name'] ?? 'this ad'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppStyle.textMuted),
              ),
              if (blockedByCurrent)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'This user is blocked',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                lastMessage.isNotEmpty
                    ? '$lastMessagePrefix$lastMessage'
                    : 'Start chatting',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppStyle.textMuted,
                  fontWeight:
                      unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatChatTime(conversation['updatedAt']),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(height: 6),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppStyle.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else if (blockedByCurrent) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _unblockConversation(conversation),
                  child: const Text(
                    'Unblock',
                    style: TextStyle(
                      color: AppStyle.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversation: conversation),
              ),
            ).then((_) => fetchConversations());
          },
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Map conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete conversation'),
        content: const Text('This will remove the chat history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    final success = await ApiService.deleteConversation(conversation['_id']);
    if (success) {
      fetchConversations();
    }

    return success;
  }

  Future<void> _unblockConversation(Map conversation) async {
    final success =
        await ApiService.unblockUserInConversation(conversation['_id']);
    if (!mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User unblocked')),
    );
    fetchConversations();
  }

  List _applySearch(List source, String query) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return List.from(source);

    return source.where((item) {
      final otherUser = item['otherUser'] ?? {};
      final ad = item['ad'] ?? {};
      final name = (otherUser['name'] ?? '').toString().toLowerCase();
      final adName = (ad['name'] ?? '').toString().toLowerCase();
      final lastMessage = (item['lastMessage'] ?? '').toString().toLowerCase();
      return name.contains(text) ||
          adName.contains(text) ||
          lastMessage.contains(text);
    }).toList();
  }

  String _formatChatTime(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return '';

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      return _formatClock(date);
    }

    return '${date.day}/${date.month}';
  }

  String _formatClock(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
