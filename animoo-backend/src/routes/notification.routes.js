const express = require('express');
const router = express.Router();

const auth = require('../../middleware/auth');
const notificationController = require('../controllers/notification.controller');

router.get('/', auth, notificationController.getNotifications);
router.patch('/read-all', auth, notificationController.markAllRead);
router.delete('/', auth, notificationController.clearNotifications);

module.exports = router;
