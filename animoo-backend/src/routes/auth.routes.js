const router = require('express').Router();
const controller = require('../controllers/auth.controller');
const auth = require('../../middleware/auth');
const upload = require('../../middleware/upload');

router.get('/me', auth, controller.me);
router.get('/users/:id', auth, controller.publicProfile);
router.patch('/me', auth, upload.single('profileImage'), controller.updateProfile);
router.delete('/me', auth, controller.deleteAccount);
router.post('/send-otp', controller.sendOtp);
router.post('/verify-otp', controller.verifyOtp);
router.post('/register', controller.register);
router.post('/login', controller.login);
router.post('/reset-password', controller.resetPassword);


module.exports = router;
