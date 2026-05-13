let io;
const onlineUsers = new Map();
const lastSeenUsers = new Map();

exports.initSocket = (server) => {
  io = require('socket.io')(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  io.on('connection', (socket) => {
    socket.on('joinUser', (userId) => {
      if (userId) {
        socket.userId = userId;
        socket.join(userId);
        const count = (onlineUsers.get(userId) || 0) + 1;
        onlineUsers.set(userId, count);
        io.emit('userOnline', userId);
      }
    });

    socket.on('checkUserStatus', (userId) => {
      socket.emit('userStatus', {
        userId,
        isOnline: onlineUsers.has(userId),
        lastSeen: lastSeenUsers.get(userId) || null,
      });
    });

    socket.on('joinConversation', (conversationId) => {
      if (conversationId) {
        socket.join(conversationId);
      }
    });

    socket.on('leaveConversation', (conversationId) => {
      if (conversationId) {
        socket.leave(conversationId);
      }
    });

    socket.on('typing', ({ conversationId, userName }) => {
      if (conversationId) {
        socket.to(conversationId).emit('typing', { conversationId, userName });
      }
    });

    socket.on('stopTyping', ({ conversationId }) => {
      if (conversationId) {
        socket.to(conversationId).emit('stopTyping', { conversationId });
      }
    });

    socket.on('disconnect', () => {
      const userId = socket.userId;
      if (!userId) return;

      const currentCount = onlineUsers.get(userId) || 0;
      if (currentCount <= 1) {
        onlineUsers.delete(userId);
        const timestamp = new Date().toISOString();
        lastSeenUsers.set(userId, timestamp);
        io.emit('userOffline', {
          userId,
          lastSeen: timestamp,
        });
      } else {
        onlineUsers.set(userId, currentCount - 1);
      }
    });
  });

  return io;
};

exports.getSocket = () => io;
