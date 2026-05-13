const express = require('express');
const router = express.Router();

const auth = require('../../middleware/auth');
const upload = require('../../middleware/upload');
const chatController = require('../controllers/chat.controller');

router.post('/conversations', auth, chatController.startConversation);
router.get('/conversations', auth, chatController.getConversations);
router.get('/conversations/:id/messages', auth, chatController.getMessages);
router.post(
  '/conversations/:id/messages',
  auth,
  upload.single('image'),
  chatController.sendMessage
);
router.delete(
  '/conversations/:conversationId/messages/:messageId',
  auth,
  chatController.deleteMessage
);
router.patch(
  '/conversations/:conversationId/messages/:messageId',
  auth,
  chatController.editMessage
);
router.post('/conversations/:id/block', auth, chatController.blockUser);
router.post('/conversations/:id/unblock', auth, chatController.unblockUser);
router.post('/conversations/:id/report-user', auth, chatController.reportUser);
router.post('/conversations/:id/rate', auth, chatController.rateUser);
router.delete('/conversations/:id', auth, chatController.deleteConversation);

module.exports = router;
