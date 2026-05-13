import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';

class SocketService {
  static io.Socket? _socket;

  static io.Socket get socket {
    _socket ??= io.io(
      ApiService.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    if (_socket!.disconnected) {
      _socket!.connect();
    }

    return _socket!;
  }

  static void joinConversation(String conversationId) {
    socket.emit('joinConversation', conversationId);
  }

  static Future<void> joinCurrentUser() async {
    final userId = await ApiService.getCurrentUserId();
    if (userId != null) {
      socket.emit('joinUser', userId);
    }
  }

  static void leaveConversation(String conversationId) {
    socket.emit('leaveConversation', conversationId);
  }

  static void onNewMessage(void Function(dynamic data) handler) {
    socket.off('newMessage');
    socket.on('newMessage', handler);
  }

  static void emitTyping(String conversationId, String userName) {
    socket.emit('typing', {
      'conversationId': conversationId,
      'userName': userName,
    });
  }

  static void emitStopTyping(String conversationId) {
    socket.emit('stopTyping', {'conversationId': conversationId});
  }

  static void onTyping(void Function(dynamic data) handler) {
    socket.off('typing');
    socket.on('typing', handler);
  }

  static void onStopTyping(void Function(dynamic data) handler) {
    socket.off('stopTyping');
    socket.on('stopTyping', handler);
  }

  static void onNotification(void Function(dynamic data) handler) {
    socket.off('notification');
    socket.on('notification', handler);
  }

  static void onDeletedMessage(void Function(dynamic data) handler) {
    socket.off('deletedMessage');
    socket.on('deletedMessage', handler);
  }

  static void onUpdatedMessage(void Function(dynamic data) handler) {
    socket.off('updatedMessage');
    socket.on('updatedMessage', handler);
  }

  static void onMessagesSeen(void Function(dynamic data) handler) {
    socket.off('messagesSeen');
    socket.on('messagesSeen', handler);
  }

  static void checkUserStatus(String userId) {
    socket.emit('checkUserStatus', userId);
  }

  static void onUserStatus(void Function(dynamic data) handler) {
    socket.off('userStatus');
    socket.on('userStatus', handler);
  }

  static void onUserOnline(void Function(dynamic data) handler) {
    socket.off('userOnline');
    socket.on('userOnline', handler);
  }

  static void onUserOffline(void Function(dynamic data) handler) {
    socket.off('userOffline');
    socket.on('userOffline', handler);
  }

  static void removeNotificationListener() {
    socket.off('notification');
  }

  static void removeNewMessageListener() {
    socket.off('newMessage');
  }

  static void removeChatListeners() {
    socket.off('newMessage');
    socket.off('typing');
    socket.off('stopTyping');
    socket.off('deletedMessage');
    socket.off('updatedMessage');
    socket.off('messagesSeen');
    socket.off('userStatus');
    socket.off('userOnline');
    socket.off('userOffline');
  }
}
