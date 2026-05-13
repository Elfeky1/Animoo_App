const express = require('express');
const router = express.Router();

const adminController = require('../controllers/admin.controller');
const auth = require('../../middleware/auth');
const admin = require('../../middleware/admin');


router.get('/users', auth, admin, adminController.getUsers);
router.get('/reports', auth, admin, adminController.getReports);
router.patch('/reports/ads/:id/review', auth, admin, adminController.reviewAdReport);
router.patch('/reports/users/:id/review', auth, admin, adminController.reviewUserReport);


router.put('/users/:id/ban', auth, admin, adminController.toggleBan);


router.put('/users/:id/role', auth, admin, adminController.changeRole);




module.exports = router;
