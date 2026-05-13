const router = require('express').Router();
const auth = require('../../middleware/auth');
const controller = require('../controllers/rating.controller');

router.get('/me', auth, controller.getMyRatings);
router.get('/users/:userId', auth, controller.getUserRatings);

module.exports = router;
