import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_style.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'image_viewer_screen.dart';
import 'public_user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final Map conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ImagePicker picker = ImagePicker();

  bool isLoading = true;
  bool isSending = false;
  bool isTyping = false;
  bool sentTyping = false;
  bool isOtherUserOnline = false;
  bool hasOtherUserSeenLatestMessage = false;
  bool isBlockedByMe = false;
  String? otherUserLastSeen;
  double otherUserRatingAverage = 0;
  int otherUserRatingCount = 0;

  String typingUserName = '';
  File? selectedImage;
  List messages = [];

  @override
  void initState() {
    super.initState();
    isBlockedByMe = widget.conversation['blockedByCurrent'] == true;
    setupSocket();
    fetchMessages();
    loadOtherUserRating();
  }

  @override
  void dispose() {
    SocketService.leaveConversation(widget.conversation['_id']);
    SocketService.emitStopTyping(widget.conversation['_id']);
    SocketService.removeChatListeners();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void setupSocket() {
    final conversationId = widget.conversation['_id'];
    final otherUserId = widget.conversation['otherUser']?['_id']?.toString();

    SocketService.joinConversation(conversationId);
    SocketService.joinCurrentUser();
    if (otherUserId != null && otherUserId.isNotEmpty) {
      SocketService.checkUserStatus(otherUserId);
    }

    SocketService.onNewMessage((data) async {
      if (!mounted) return;
      if (data['conversationId'] != conversationId) return;

      final message = Map<String, dynamic>.from(data['message']);
      final messageId = message['_id'];
      final currentUserId = await ApiService.getCurrentUserId();
      final sender = message['sender'];
      message['isMine'] =
          sender is Map && sender['_id']?.toString() == currentUserId;

      final alreadyExists = messages.any((item) => item['_id'] == messageId);
      if (alreadyExists) return;

      setState(() {
        messages.add(message);
        if (message['isMine'] == true) {
          hasOtherUserSeenLatestMessage = false;
        }
      });
      scrollToLatest();
    });

    SocketService.onUpdatedMessage((data) async {
      if (!mounted) return;
      if (data['conversationId'] != conversationId) return;

      final updatedMessage = Map<String, dynamic>.from(data['message']);
      final currentUserId = await ApiService.getCurrentUserId();
      final sender = updatedMessage['sender'];
      updatedMessage['isMine'] =
          sender is Map && sender['_id']?.toString() == currentUserId;

      setState(() {
        final index = messages.indexWhere(
          (item) => item['_id'] == updatedMessage['_id'],
        );
        if (index != -1) {
          messages[index] = updatedMessage;
        }
      });
    });

    SocketService.onTyping((data) {
      if (!mounted) return;
      if (data['conversationId'] != conversationId) return;

      setState(() {
        isTyping = true;
        typingUserName = data['userName']?.toString() ?? 'User';
      });
    });

    SocketService.onStopTyping((data) {
      if (!mounted) return;
      if (data['conversationId'] != conversationId) return;

      setState(() {
        isTyping = false;
        typingUserName = '';
      });
    });

    SocketService.onUserStatus((data) {
      if (!mounted) return;
      if (data['userId']?.toString() != otherUserId) return;

      setState(() {
        isOtherUserOnline = data['isOnline'] == true;
        otherUserLastSeen = data['lastSeen']?.toString();
      });
    });

    SocketService.onUserOnline((data) {
      if (!mounted) return;
      final userId = data is Map ? data['userId']?.toString() : data?.toString();
      if (userId != otherUserId) return;

      setState(() {
        isOtherUserOnline = true;
        otherUserLastSeen = null;
      });
    });

    SocketService.onUserOffline((data) {
      if (!mounted) return;
      final userId = data is Map ? data['userId']?.toString() : data?.toString();
      if (userId != otherUserId) return;

      setState(() {
        isOtherUserOnline = false;
        otherUserLastSeen = data is Map ? data['lastSeen']?.toString() : null;
      });
    });

    SocketService.onMessagesSeen((data) {
      if (!mounted) return;
      if (data['conversationId'] != conversationId) return;
      if (data['seenBy']?.toString() != otherUserId) return;

      final seenIds = ((data['messageIds'] as List?) ?? [])
          .map((item) => item.toString())
          .toSet();

      setState(() {
        messages = messages.map((item) {
          final map = Map<String, dynamic>.from(item);
          final isMine = map['isMine'] == true;
          if (!isMine) return map;

          final currentSeenBy = ((map['seenBy'] as List?) ?? [])
              .map((value) => value.toString())
              .toSet();

          if (seenIds.contains(map['_id']?.toString())) {
            currentSeenBy.add(otherUserId ?? '');
            map['seenBy'] = currentSeenBy.toList();
          }

          return map;
        }).toList();
        hasOtherUserSeenLatestMessage = _isLatestMineSeenBy(otherUserId);
      });
    });
  }

  Future<void> fetchMessages({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => isLoading = true);
    }

    final data = await ApiService.getMessages(widget.conversation['_id']);

    if (!mounted) return;

    setState(() {
      messages = data;
      isLoading = false;
    });

    await _refreshSeenState();
    scrollToLatest();
  }

  Future<void> _refreshSeenState() async {
    final conversations = await ApiService.getConversations();
    if (!mounted) return;

    final currentConversation = conversations.cast<Map?>().firstWhere(
          (item) => item?['_id'] == widget.conversation['_id'],
          orElse: () => null,
        );

    final otherUserId = widget.conversation['otherUser']?['_id']?.toString();
    final readBy = (currentConversation?['readBy'] as List?) ?? [];
    final otherHasRead = readBy.any((item) => item.toString() == otherUserId);

    setState(() {
      hasOtherUserSeenLatestMessage =
          _isLatestMineSeenBy(otherUserId) || (otherHasRead && _isLastMessageMine());
      isBlockedByMe = currentConversation?['blockedByCurrent'] == true;
    });
  }

  Future<void> loadOtherUserRating() async {
    final otherUserId = widget.conversation['otherUser']?['_id']?.toString();
    if (otherUserId == null || otherUserId.isEmpty) return;

    final summary = await ApiService.getUserRatings(otherUserId);
    if (!mounted) return;

    setState(() {
      otherUserRatingAverage =
          (summary['average'] as num?)?.toDouble() ?? 0;
      otherUserRatingCount = (summary['count'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if ((text.isEmpty && selectedImage == null) || isSending) return;

    setState(() => isSending = true);

    final message = await ApiService.sendMessage(
      widget.conversation['_id'],
      text,
      image: selectedImage,
    );

    if (!mounted) return;

    if (message != null) {
      messageController.clear();
      selectedImage = null;
      sentTyping = false;
      SocketService.emitStopTyping(widget.conversation['_id']);
      setState(() {
        final alreadyExists =
            messages.any((item) => item['_id'] == message['_id']);
        if (!alreadyExists) {
          messages.add(message);
        }
        hasOtherUserSeenLatestMessage = false;
        isSending = false;
      });
      scrollToLatest();
    } else {
      setState(() => isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = widget.conversation['otherUser'] ?? {};
    final ad = widget.conversation['ad'] ?? {};

    return Scaffold(
      backgroundColor: AppStyle.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppStyle.textPrimary),
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final userId = otherUser['_id']?.toString();
            if (userId == null || userId.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicUserProfileScreen(userId: userId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppStyle.primary,
                backgroundImage:
                    (otherUser['profileImage']?.toString().isNotEmpty == true)
                        ? NetworkImage(
                            '${ApiService.baseUrl}/uploads/${otherUser['profileImage']}',
                          )
                        : null,
                child: (otherUser['profileImage']?.toString().isNotEmpty == true)
                    ? null
                    : Text(
                        ((otherUser['name'] ?? 'C').toString().isNotEmpty
                                ? (otherUser['name'] ?? 'C').toString()[0]
                                : 'C')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser['name'] ?? 'Chat',
                    style: const TextStyle(
                      color: AppStyle.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    isOtherUserOnline
                        ? 'Online now'
                        : _formatLastSeen(otherUserLastSeen),
                    style: TextStyle(
                      color: isOtherUserOnline
                          ? const Color(0xff10b981)
                          : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  if (otherUserRatingCount > 0)
                    Text(
                      '${otherUserRatingAverage.toStringAsFixed(1)} stars ($otherUserRatingCount)',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: _showChatActionsSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          if ((ad['name'] ?? '').toString().isNotEmpty)
            Container(
              width: double.infinity,
              color: AppStyle.surfaceTint,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Chatting about ${ad['name']}',
                style: const TextStyle(
                  color: AppStyle.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 42,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Start chatting with ${otherUser['name'] ?? 'them'}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchMessages,
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return _messageBubble(messages[index]);
                          },
                        ),
                      ),
          ),
          if (isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$typingUserName is typing...',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    const _TypingDots(),
                  ],
                ),
              ),
            ),
          if (isBlockedByMe)
            Container(
              width: double.infinity,
              color: const Color(0xfffff3cd),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                'You blocked this user. You can no longer send messages.',
                style: TextStyle(
                  color: Color(0xff7a5b00),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            _messageInput(),
        ],
      ),
    );
  }

  void scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _messageBubble(Map message) {
    final isMine = message['isMine'] == true;
    final image = message['image']?.toString();
    final isDeleted = message['isDeleted'] == true;
    final isEdited = message['isEdited'] == true;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMine ? () => _showMessageActions(message) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          constraints: const BoxConstraints(maxWidth: 285),
          decoration: BoxDecoration(
            color: isMine ? AppStyle.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 6),
              bottomRight: Radius.circular(isMine ? 6 : 18),
            ),
            boxShadow: isMine
                ? null
                : [
                    BoxShadow(
                      color: AppStyle.primary.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDeleted && image != null && image.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageViewerScreen(
                          images: [image],
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${ApiService.baseUrl}/uploads/$image',
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              if (isDeleted) ...[
                Text(
                  'This message was deleted',
                  style: TextStyle(
                    color: isMine ? Colors.white70 : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else if ((message['text'] ?? '').toString().isNotEmpty) ...[
                if (image != null && image.isNotEmpty) const SizedBox(height: 8),
                Text(
                  message['text'] ?? '',
                  style: TextStyle(
                    color: isMine ? Colors.white : Colors.black87,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatMessageTime(message['createdAt']),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMine ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  if (isEdited && !isDeleted) ...[
                    const SizedBox(width: 6),
                    Text(
                      'edited',
                      style: TextStyle(
                        fontSize: 11,
                        color: isMine ? Colors.white70 : Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (isMine) ...[
                    const SizedBox(width: 6),
                    Icon(
                      _isMessageSeenByOther(message)
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 15,
                      color: _isMessageSeenByOther(message)
                          ? const Color(0xff93c5fd)
                          : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        selectedImage!,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedImage = null);
                        },
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child:
                              Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: showImageSourcePicker,
                  icon: const Icon(Icons.attach_file_rounded),
                  color: AppStyle.primary,
                ),
                IconButton(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined),
                  color: AppStyle.primary,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f3f6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: messageController,
                      onChanged: onMessageChanged,
                      onSubmitted: (_) => sendMessage(),
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: selectedImage == null
                            ? 'Type a message...'
                            : 'Add a caption...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xffe9edf3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: isSending ? null : sendMessage,
                    icon: Icon(
                      Icons.send_rounded,
                      color: isSending
                          ? Colors.grey
                          : const Color(0xff7c8897),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showImageSourcePicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Open camera'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? picked = await picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      selectedImage = File(picked.path);
    });
  }

  Future<void> _confirmDeleteMessage(Map message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Do you want to delete this message?'),
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

    if (confirm != true) return;

    final success = await ApiService.deleteMessage(
      widget.conversation['_id'],
      message['_id'],
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        final index = messages.indexWhere((item) => item['_id'] == message['_id']);
        if (index != -1) {
          messages[index] = {
            ...messages[index],
            'text': '',
            'image': null,
            'isDeleted': true,
          };
        }
      });
    }
  }

  Future<void> _showMessageActions(Map message) async {
    if (message['isDeleted'] == true) return;
    final canEdit = _canEditMessage(message);

    await showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit message'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditMessageDialog(message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete message',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMessage(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditMessageDialog(Map message) async {
    if (!_canEditMessage(message)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can edit a message only within 5 minutes'),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: message['text'] ?? '');

    final updatedText = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Update your message',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updatedText == null || updatedText.isEmpty) return;

    final updatedMessage = await ApiService.editMessage(
      widget.conversation['_id'],
      message['_id'],
      updatedText,
    );

    if (!mounted) return;

    if (updatedMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edit failed. The 5-minute edit window may be over.'),
        ),
      );
      return;
    }

    setState(() {
      final index = messages.indexWhere(
        (item) => item['_id'] == updatedMessage['_id'],
      );
      if (index != -1) {
        messages[index] = updatedMessage;
      }
    });
  }

  Future<void> _handleMenuAction(String value) async {
    switch (value) {
      case 'delete_chat':
        await _deleteCurrentConversation();
        break;
      case 'block_user':
        await _blockCurrentUser();
        break;
      case 'unblock_user':
        await _unblockCurrentUser();
        break;
      case 'report_user':
        await _reportCurrentUser();
        break;
      case 'rate_user':
        await _rateCurrentUser();
        break;
    }
  }

  Future<void> _showChatActionsSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                _actionTile(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red,
                  title: 'Delete chat',
                  value: 'delete_chat',
                ),
                _actionTile(
                  icon: isBlockedByMe
                      ? Icons.lock_open_rounded
                      : Icons.block_rounded,
                  color: isBlockedByMe
                      ? AppStyle.primary
                      : Colors.orange,
                  title: isBlockedByMe ? 'Unblock user' : 'Block user',
                  value: isBlockedByMe ? 'unblock_user' : 'block_user',
                ),
                _actionTile(
                  icon: Icons.star_rounded,
                  color: Colors.amber.shade700,
                  title: 'Rate user',
                  value: 'rate_user',
                ),
                _actionTile(
                  icon: Icons.flag_outlined,
                  color: Colors.red.shade400,
                  title: 'Report user',
                  value: 'report_user',
                  isLast: true,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;
    await _handleMenuAction(action);
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(0),
        bottom: Radius.circular(isLast ? 16 : 0),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: Colors.grey.shade100),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppStyle.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCurrentConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete chat'),
        content: const Text('This will remove the full chat between you two.'),
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

    if (confirm != true) return;

    final success = await ApiService.deleteConversation(widget.conversation['_id']);
    if (!mounted || !success) return;

    Navigator.pop(context, true);
  }

  Future<void> _blockCurrentUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block user'),
        content: const Text('They will no longer be able to chat with you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.blockUserInConversation(
      widget.conversation['_id'],
    );

    if (!mounted || !success) return;

    setState(() {
      isBlockedByMe = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User blocked')),
    );
  }

  Future<void> _unblockCurrentUser() async {
    final success = await ApiService.unblockUserInConversation(
      widget.conversation['_id'],
    );

    if (!mounted || !success) return;

    setState(() {
      isBlockedByMe = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User unblocked')),
    );
  }

  Future<void> _reportCurrentUser() async {
    String reasonText = '';
    String? selectedReason;
    const suggestions = [
      'Spam or scam',
      'Abusive behavior',
      'Fake information',
      'Harassment',
    ];

    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canSubmit = reasonText.isNotEmpty;

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 24,
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Report user',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppStyle.textPrimary,
                              ),
                            ),
                            Text(
                              'Tell us what happened with ${widget.conversation['otherUser']?['name'] ?? 'this user'}.',
                              style: const TextStyle(
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions.map((item) {
                      final isSelected = selectedReason == item;
                      return ChoiceChip(
                        label: Text(item),
                        selected: isSelected,
                        onSelected: (_) {
                          selectedReason = item;
                          reasonText = item;
                          setDialogState(() {});
                        },
                        selectedColor: AppStyle.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppStyle.primary
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppStyle.primary
                              : Colors.grey.shade300,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    autofocus: true,
                    minLines: 3,
                    maxLines: 5,
                    onChanged: (value) {
                      reasonText = value.trim();
                      if (selectedReason != null && reasonText != selectedReason) {
                        selectedReason = null;
                      }
                      setDialogState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Add more details',
                      filled: true,
                      fillColor: const Color(0xfff5f7fb),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: !canSubmit
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  Navigator.pop(context, reasonText);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Submit Report'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (reason == null || reason.isEmpty) return;

    final success = await ApiService.reportUserInConversation(
      widget.conversation['_id'],
      reason,
    );

    if (!mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User reported')),
    );
  }

  Future<void> _rateCurrentUser() async {
    int selectedScore = 5;
    String commentText = '';
    final otherUserName =
        widget.conversation['otherUser']?['name']?.toString() ?? 'this user';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate user',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppStyle.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'How was your experience with $otherUserName?',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xfff8fafc),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final isSelected = star <= selectedScore;
                      return IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        constraints: const BoxConstraints(),
                        splashRadius: 22,
                        onPressed: () {
                          selectedScore = star;
                          setDialogState(() {});
                        },
                        icon: Icon(
                          isSelected
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _ratingLabel(selectedScore),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppStyle.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                minLines: 3,
                maxLines: 4,
                onChanged: (value) {
                  commentText = value.trim();
                },
                decoration: InputDecoration(
                  hintText: 'Write a short review (optional)',
                  filled: true,
                  fillColor: const Color(0xfff8fafc),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppStyle.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyle.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      return;
    }

    final result = await ApiService.rateUserInConversation(
      widget.conversation['_id'],
      score: selectedScore,
      comment: commentText,
    );

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating failed')),
      );
      return;
    }

    await loadOtherUserRating();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rating submitted')),
    );
  }

  String _ratingLabel(int score) {
    switch (score) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Future<void> onMessageChanged(String value) async {
    final conversationId = widget.conversation['_id'];

    if (value.trim().isEmpty) {
      sentTyping = false;
      SocketService.emitStopTyping(conversationId);
      return;
    }

    if (!sentTyping) {
      sentTyping = true;
      final currentUserName = await ApiService.getCurrentUserName();
      SocketService.emitTyping(conversationId, currentUserName ?? 'User');
    }
  }

  String _formatMessageTime(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return '';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  bool _canEditMessage(Map message) {
    final createdAt = DateTime.tryParse(message['createdAt']?.toString() ?? '');
    if (createdAt == null) return false;

    final age = DateTime.now().difference(createdAt.toLocal());
    return age.inMinutes < 5;
  }

  bool _isLastMessageMine() {
    if (messages.isEmpty) return false;
    return messages.last['isMine'] == true;
  }

  bool _isLatestMineSeenBy(String? otherUserId) {
    if (otherUserId == null || otherUserId.isEmpty) return false;

    for (int i = messages.length - 1; i >= 0; i--) {
      final message = Map<String, dynamic>.from(messages[i]);
      if (message['isMine'] != true) continue;

      final seenBy = ((message['seenBy'] as List?) ?? [])
          .map((item) => item.toString())
          .toSet();
      return seenBy.contains(otherUserId);
    }

    return false;
  }

  bool _isLastMessageById(dynamic messageId) {
    if (messages.isEmpty) return false;
    return messages.last['_id'] == messageId;
  }

  bool _isMessageSeenByOther(Map message) {
    if (message['isMine'] != true) return false;

    final otherUserId = widget.conversation['otherUser']?['_id']?.toString();
    if (otherUserId == null || otherUserId.isEmpty) {
      return _isLastMessageById(message['_id']) && hasOtherUserSeenLatestMessage;
    }

    final seenBy = ((message['seenBy'] as List?) ?? [])
        .map((item) => item.toString())
        .toSet();

    return seenBy.contains(otherUserId);
  }

  String _formatLastSeen(String? value) {
    if (value == null || value.isEmpty) return 'Offline';

    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Offline';

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final time = _formatMessageTime(date.toIso8601String());

    if (isToday) {
      return 'Last seen $time';
    }

    return 'Last seen ${date.day}/${date.month} $time';
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final step = (controller.value * 3).floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final active = index <= step;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? AppStyle.primary : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
