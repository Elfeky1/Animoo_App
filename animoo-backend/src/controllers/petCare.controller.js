const Pet = require('../models/Pet');
const PetCareLog = require('../models/PetCareLog');

async function findUserPet(req) {
  return Pet.findOne({
    _id: req.params.id,
    user: req.user._id,
  });
}

function startOfDay(date = new Date()) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function endOfDay(date = new Date()) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999);
}

exports.getPetDetails = async (req, res) => {
  try {
    const pet = await findUserPet(req);

    if (!pet) {
      return res.status(404).json({ message: 'Pet not found' });
    }

    const logs = await PetCareLog.find({
      pet: pet._id,
      user: req.user._id,
    })
      .sort({ doneAt: -1 })
      .limit(20);

    res.json({ pet, logs });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.markMealDone = async (req, res) => {
  try {
    const pet = await findUserPet(req);

    if (!pet) {
      return res.status(404).json({ message: 'Pet not found' });
    }

    const label = req.body.label?.toString().trim();
    if (!label) {
      return res.status(400).json({ message: 'Meal label is required' });
    }

    const existingLog = await PetCareLog.findOne({
      pet: pet._id,
      user: req.user._id,
      kind: 'meal',
      label,
      doneAt: {
        $gte: startOfDay(),
        $lte: endOfDay(),
      },
    });

    if (existingLog) {
      return res.json(existingLog);
    }

    const log = await PetCareLog.create({
      pet: pet._id,
      user: req.user._id,
      kind: 'meal',
      label,
      notes: req.body.notes?.toString().trim() || '',
    });

    res.status(201).json(log);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.markVaccineDone = async (req, res) => {
  try {
    const pet = await findUserPet(req);

    if (!pet) {
      return res.status(404).json({ message: 'Pet not found' });
    }

    const label =
      req.body.label?.toString().trim() ||
      pet.vaccineReminderDate?.toString().trim() ||
      'Vaccine reminder';
    const nextVaccineDate = req.body.nextVaccineDate?.toString().trim() || '';

    const existingLog = await PetCareLog.findOne({
      pet: pet._id,
      user: req.user._id,
      kind: 'vaccine',
      label,
    });

    if (existingLog) {
      return res.json(existingLog);
    }

    const log = await PetCareLog.create({
      pet: pet._id,
      user: req.user._id,
      kind: 'vaccine',
      label,
      notes: req.body.notes?.toString().trim() || '',
    });

    pet.vaccineReminderDate = nextVaccineDate;
    await pet.save();

    res.status(201).json(log);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
