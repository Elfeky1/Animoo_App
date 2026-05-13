const Ad = require('../models/Ad');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const Notification = require('../models/Notification');
const Rating = require('../models/Rating');
const User = require('../models/User');
const UserReport = require('../models/UserReport');
const { getSocket } = require('../socket');
const EDIT_WINDOW_MS = 5 * 60 * 1000;

function conversationPreview(message) {
  if (!message) return '';
  if (message.isDeleted) return 'Message deleted';
  return message.text || (message.image ? 'Photo' : '');
}

function canEditMessage(message) {
  if (!message?.createdAt) return false;
  return Date.now() - new Date(message.createdAt).getTime() <= EDIT_WINDOW_MS;
}

async function getBlockState(currentUserId, otherUserId) {
  const users = await User.find({
    _id: { $in: [currentUserId, otherUserId] },
  }).select('blockedUsers');

  const currentUser = users.find(
    (user) => user._id.toString() === currentUserId.toString()
  );
  const otherUser = users.find(
    (user) => user._id.toString() === otherUserId.toString()
  );

  const blockedByCurrent = (currentUser?.blockedUsers || []).some(
    (id) => id.toString() === otherUserId.toString()
  );
  const blockedByOther = (otherUser?.blockedUsers || []).some(
    (id) => id.toString() === currentUserId.toString()
  );

  return { blockedByCurrent, blockedByOther };
}

async function ensureConversationAccess(conversation, currentUserId, res) {
  const otherUserId = conversation.participants.find(
    (participantId) => participantId.toString() !== currentUserId.toString()
  );

  if (!otherUserId) {
    res.status(400).json({ message: 'Conversation participant not found' });
    return null;
  }

  const { blockedByCurrent, blockedByOther } = await getBlockState(
    currentUserId,
    otherUserId
  );

  if (blockedByCurrent || blockedByOther) {
    res.status(403).json({
      message: blockedByCurrent
        ? 'You blocked this user'
        : 'You cannot chat with this user',
      blockedByCurrent,
      blockedByOther,
    });
    return null;
  }

  return otherUserId;
}

function formatConversation(conversation, currentUserId) {
  const data = conversation.toObject();
  const otherUser = data.participants.find(
    (user) => user._id.toString() !== currentUserId.toString()
  );
  const lastMessageSenderId = data.lastMessageSender?.toString();
  const hasRead = (data.readBy || []).some(
    (userId) => userId.toString() === currentUserId.toString()
  );
  const unreadCount =
    data.lastMessage && lastMessageSenderId !== currentUserId.toString() && !hasRead
      ? 1
      : 0;

  return {
    ...data,
    otherUser,
    unreadCount,
    lastMessageIsMine: lastMessageSenderId === currentUserId.toString(),
  };
}

exports.startConversation = async (req, res) => {
  try {
    const { adId } = req.body;

    if (!adId) {
      return res.status(400).json({ message: 'Ad id is required' });
    }

    const ad = await Ad.findById(adId);
    if (!ad) {
      return res.status(404).json({ message: 'Ad not found' });
    }

    const ownerId = ad.user.toString();
    const userId = req.user._id.toString();

    if (ownerId === userId) {
      return res.status(400).json({ message: 'You cannot chat with yourself' });
    }

    const { blockedByCurrent, blockedByOther } = await getBlockState(
      req.user._id,
      ad.user
    );

    if (blockedByCurrent || blockedByOther) {
      return res.status(403).json({
        message: blockedByCurrent
          ? 'You blocked this user'
          : 'You cannot chat with this user',
      });
    }

    let conversation = await Conversation.findOne({
      ad: ad._id,
      participants: { $all: [req.user._id, ad.user] },
    })
      .populate('ad', 'name images')
      .populate('participants', 'name email profileImage');

    if (!conversation) {
      conversation = await Conversation.create({
        ad: ad._id,
        participants: [req.user._id, ad.user],
        readBy: [req.user._id],
      });

      conversation = await Conversation.findById(conversation._id)
        .populate('ad', 'name images')
        .populate('participants', 'name email profileImage');
    }

    res.json({
      ...formatConversation(conversation, req.user._id),
      blockedByCurrent,
      blockedByOther,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getConversations = async (req, res) => {
  try {
    const currentUser = await User.findById(req.user._id).select('blockedUsers');
    const conversations = await Conversation.find({
      participants: req.user._id,
    })
      .populate('ad', 'name images')
      .populate('participants', 'name email profileImage')
      .sort({ updatedAt: -1 });

    const otherUserIds = conversations
      .map((conversation) =>
        conversation.participants.find(
          (user) => user._id.toString() !== req.user._id.toString()
        )?._id
      )
      .filter(Boolean);

    const otherUsers = await User.find({
      _id: { $in: otherUserIds },
    }).select('blockedUsers');

    const otherUsersMap = new Map(
      otherUsers.map((user) => [user._id.toString(), user])
    );

    res.json(
      conversations.map((conversation) => {
        const formatted = formatConversation(conversation, req.user._id);
        const otherUserId = formatted.otherUser?._id?.toString();
        const blockedByCurrent = (currentUser?.blockedUsers || []).some(
          (id) => id.toString() == otherUserId
        );
        const blockedByOther = (
          otherUsersMap.get(otherUserId)?.blockedUsers || []
        ).some((id) => id.toString() == req.user._id.toString());

        return {
          ...formatted,
          blockedByCurrent,
          blockedByOther,
        };
      })
    );
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMessages = async (req, res) => {
  try {
    const conversation = await Conversation.findOne({
      _id: req.params.id,
      participants: req.user._id,
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    await Message.updateMany(
      {
        conversation: conversation._id,
        sender: { $ne: req.user._id },
        seenBy: { $ne: req.user._id },
      },
      {
        $addToSet: { seenBy: req.user._id },
      }
    );

    const messages = await Message.find({ conversation: conversation._id })
      .populate('sender', 'name email profileImage')
      .sort({ createdAt: 1 });

    await Conversation.updateOne(
      { _id: conversation._id },
      { $addToSet: { readBy: req.user._id } }
    );

    const seenMessageIds = messages
      .filter(
        (message) =>
          message.sender?._id?.toString() !== req.user._id.toString() &&
          (message.seenBy || []).some(
            (userId) => userId.toString() === req.user._id.toString()
          )
      )
      .map((message) => message._id.toString());

    getSocket()?.to(conversation._id.toString()).emit('messagesSeen', {
      conversationId: conversation._id.toString(),
      seenBy: req.user._id.toString(),
      messageIds: seenMessageIds,
    });

    res.json(
      messages.map((message) => ({
        ...message.toObject(),
        isMine: message.sender._id.toString() === req.user._id.toString(),
      }))
    );
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.sendMessage = async (req, res) => {
  try {
    const { text } = req.body;

    if ((!text || !text.trim()) && !req.file) {
      return res.status(400).json({ message: 'Message or image is required' });
    }

    const conversation = await Conversation.findOne({
      _id: req.params.id,
      participants: req.user._id,
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    const otherUserId = await ensureConversationAccess(
      conversation,
      req.user._id,
      res
    );
    if (!otherUserId) return;

    const message = await Message.create({
      conversation: conversation._id,
      sender: req.user._id,
      text: text?.trim() ?? '',
      image: req.file?.filename ?? null,
      seenBy: [req.user._id],
    });

    conversation.lastMessage = conversationPreview(message);
    conversation.lastMessageSender = req.user._id;
    conversation.readBy = [req.user._id];
    await conversation.save();

    const populatedMessage = await Message.findById(message._id).populate(
      'sender',
      'name email profileImage'
    );
    const receiverIds = conversation.participants.filter(
      (participantId) =>
        participantId.toString() !== req.user._id.toString()
    );

    for (const receiverId of receiverIds) {
      const notification = await Notification.create({
        user: receiverId,
        type: 'message',
        title: `New reply from ${req.user.name || 'seller'}`,
        body: message.text || 'Sent a photo',
        meta: {
          conversationId: conversation._id.toString(),
          senderId: req.user._id.toString(),
        },
      });

      getSocket()?.to(receiverId.toString()).emit('notification', notification);
    }

    const responseMessage = {
      ...populatedMessage.toObject(),
      isMine: true,
    };

    const socketMessage = {
      ...populatedMessage.toObject(),
      isMine: false,
    };

    getSocket()?.to(conversation._id.toString()).emit('newMessage', {
      conversationId: conversation._id.toString(),
      message: socketMessage,
    });

    res.status(201).json(responseMessage);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteConversation = async (req, res) => {
  try {
    const conversation = await Conversation.findOne({
      _id: req.params.id,
      participants: req.user._id,
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    await Message.deleteMany({ conversation: conversation._id });
    await conversation.deleteOne();

    res.json({ message: 'Conversation deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteMessage = async (req, res) => {
  try {
    const { conversationId, messageId } = req.params;

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: req.user._id,
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    const otherUserId = await ensureConversationAccess(
      conversation,
      req.user._id,
      res
    );
    if (!otherUserId) return;

    const message = await Message.findOne({
      _id: messageId,
      conversation: conversation._id,
      sender: req.user._id,
    });

    if (!message) {
      return res.status(404).json({ message: 'Message not found' });
    }

    message.text = '';
    message.image = null;
    message.isDeleted = true;
    await message.save();

    const latestMessage = await Message.findOne({
      conversation: conversation._id,
    }).sort({ createdAt: -1 });

    conversation.lastMessage = conversationPreview(latestMessage);
    conversation.lastMessageSender = latestMessage?.sender ?? null;
    if (!latestMessage) {
      conversation.readBy = [];
    }
    await conversation.save();

    const updatedMessage = await Message.findById(message._id).populate(
      'sender',
      'name email profileImage'
    );

    getSocket()?.to(conversation._id.toString()).emit('updatedMessage', {
      conversationId: conversation._id.toString(),
      message: {
        ...updatedMessage.toObject(),
        isMine: false,
      },
    });

    res.json({ message: 'Message deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.editMessage = async (req, res) => {
  try {
    const { conversationId, messageId } = req.params;
    const { text } = req.body;

    if (!text || !text.trim()) {
      return res.status(400).json({ message: 'Text is required' });
    }

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: req.user._id,
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    const otherUserId = await ensureConversationAccess(
      conversation,
      req.user._id,
      res
    );
    if (!otherUserId) return;

    const message = await Message.findOne({
      _id: messageId,
      conversation: conversation._id,
      sender: req.user._id,
    });

    if (!message || message.isDeleted) {
      return res.status(404).json({ message: 'Message not found' });
    }

    if (!canEditMessage(message)) {
      return res
        .status(400)
        .json({ message: 'You can only edit a message within 5 minutes' });
    }

    message.text = text.trim();
    message.isEdited = true;
    await message.save();

    const latestMessage = await Message.findOne({
      conversation: conversation._id,
    }).sort({ createdAt: -1 });

    conversation.lastMessage = conversationPreview(latestMessage);
    conversation.lastMessageSender = latestMessage?.sender ?? null;
    await conversation.save();

    const updatedMessage = await Message.findById(message._id).populate(
      'sender',
      'name email profileImage'
    );

    getSocket()?.to(conversation._id.toString()).emit('updatedMessage', {
      conversationId: conversation._id.toString(),
      message: {
        ...updatedMessage.toObject(),
        isMine: false,
      },
    });

    res.json({
      ...updatedMessage.toObject(),
      isMine: true,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.blockUser = async (req, res) => {
  try {
    const conversation = await Conversation.findOne({
      _id: req.params.id,
      participants: req.user._id,
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    const otherUserId = conversation.participants.find(
      (participantId) => participantId.toString() !== req.user._id.toString()
    );

    if (!otherUserId) {
      return res.status(400).json({ message: 'User not found' });
    }

    await User.updateOne(
      { _id: req.user._id },
      { $addToSet: { blockedUsers: otherUserId } }
    );

    res.json({ message: 'User blocked' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.unblockUser = async (req, res) => {
  try {
    const conversation = await Conversation.findOne({
      _id: req.params.id,
      participants: req.user._id,
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    const otherUserId = conversation.participants.find(
      (participantId) => participantId.toString() !== req.user._id.toString()
    );

    if (!otherUserId) {
      return res.status(400).json({ message: 'User not found' });
    }

    await User.updateOne(
      { _id: req.user._id },
      { $pull: { blockedUsers: otherUserId } }
    );

    res.json({ message: 'User unblocked' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.reportUser = async (req, res) => {
  try {
    const { reason } = req.body;

    if (!reason || !reason.trim()) {
      return res.status(400).json({ message: 'Reason is required' });
    }

    const conversation = await Conversation.findOne({
      _id: req.params.id,
      participants: req.user._id,
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    const otherUserId = conversation.participants.find(
      (participantId) => participantId.toString() !== req.user._id.toString()
    );

    if (!otherUserId) {
      return res.status(400).json({ message: 'User not found' });
    }

    await UserReport.create({
      reporter: req.user._id,
      reportedUser: otherUserId,
      conversation: conversation._id,
      ad: conversation.ad,
      reason: reason.trim(),
    });

    res.status(201).json({ message: 'User reported' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.rateUser = async (req, res) => {
  try {
    const numericScore = Number(req.body.score);

    if (numericScore < 1 || numericScore > 5) {
      return res.status(400).json({ message: 'Score must be between 1 and 5' });
    }

    const conversation = await Conversation.findOne({
      _id: req.params.id,
      participants: req.user._id,
    });

    if (!conversation) {
      return res.status(404).json({ message: 'Conversation not found' });
    }

    const ratedUserId = conversation.participants.find(
      (participantId) => participantId.toString() !== req.user._id.toString()
    );

    if (!ratedUserId) {
      return res.status(400).json({ message: 'User not found' });
    }

    const rating = await Rating.findOneAndUpdate(
      {
        rater: req.user._id,
        conversation: conversation._id,
      },
      {
        rater: req.user._id,
        ratedUser: ratedUserId,
        conversation: conversation._id,
        ad: conversation.ad ?? null,
        score: numericScore,
        comment: req.body.comment?.toString().trim() ?? '',
      },
      {
        new: true,
        upsert: true,
        setDefaultsOnInsert: true,
      }
    )
      .populate('rater', 'name profileImage')
      .populate('ad', 'name');

    const notification = await Notification.create({
      user: ratedUserId,
      type: 'rating',
      title: `${req.user.name || 'Someone'} rated you`,
      body:
        numericScore == 1
          ? 'You received 1 star.'
          : `You received ${numericScore} stars.`,
      meta: {
        raterId: req.user._id.toString(),
        conversationId: conversation._id.toString(),
        adId: conversation.ad?.toString() ?? null,
      },
    });

    getSocket()?.to(ratedUserId.toString()).emit('notification', notification);

    res.json(rating);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
