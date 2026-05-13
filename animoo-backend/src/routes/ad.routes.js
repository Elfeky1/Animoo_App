const express = require('express');
const router = express.Router();

const adController = require('../controllers/ad.controller');
const auth = require('../../middleware/auth');
const upload = require('../../middleware/upload');
const admin = require('../../middleware/admin');


router.post(
  '/',
  auth,
  upload.fields([
    { name: 'images', maxCount: 4 },
    { name: 'idCard', maxCount: 1 },
  ]),
  adController.addAd
);


router.patch(
  '/:id',
  auth,
  upload.fields([
    { name: 'images', maxCount: 4 },
  ]),
  adController.updateAd
);

router.get('/my', auth, adController.getMyAds);
router.get('/favorites', auth, adController.getFavorites);
router.post('/:id/favorite', auth, adController.toggleFavorite);
router.post('/:id/report', auth, adController.reportAd);
router.patch('/:id/availability', auth, adController.markAdUnavailable);

router.get('/pending', auth,admin, adController.getPendingAds);
router.put('/:id/approve', auth,admin, adController.approveAd);
router.put('/:id/reject', auth, admin, adController.rejectAd);
router.delete('/:id', auth, adController.deleteAd);
router.get('/approved', auth, adController.getApprovedAds);
router.get('/users', auth, admin,async (req, res) => {
  const users = await User.find().select('-password');
  res.json(users);
});



router.get(
  '/stats',
  auth,
  admin,
  adController.getAdStats
);



module.exports = router;
