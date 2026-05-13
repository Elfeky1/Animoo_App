const express = require('express');
const router = express.Router();

const {
  getAnimals,   
} = require('../controllers/ad.controller');


router.get('/', getAnimals);

module.exports = router;
