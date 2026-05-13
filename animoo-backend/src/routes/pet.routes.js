const express = require('express');

const auth = require('../../middleware/auth');
const upload = require('../../middleware/upload');
const petController = require('../controllers/pet.controller');
const petCareController = require('../controllers/petCare.controller');

const router = express.Router();

router.get('/', auth, petController.getMyPets);
router.get('/:id', auth, petCareController.getPetDetails);
router.post('/:id/meal-done', auth, petCareController.markMealDone);
router.post('/:id/vaccine-done', auth, petCareController.markVaccineDone);
router.post('/', auth, upload.single('image'), petController.addPet);
router.patch('/:id', auth, upload.single('image'), petController.updatePet);
router.delete('/:id', auth, petController.deletePet);

module.exports = router;
