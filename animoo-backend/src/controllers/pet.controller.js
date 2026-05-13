const Pet = require('../models/Pet');
const PetCareLog = require('../models/PetCareLog');

function normalizeReminderTimes(value) {
  if (!value) return [];

  if (Array.isArray(value)) {
    return value.map((item) => item.toString().trim()).filter(Boolean);
  }

  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      if (Array.isArray(parsed)) {
        return parsed.map((item) => item.toString().trim()).filter(Boolean);
      }
    } catch (_) {}
  }

  return value
    .toString()
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

exports.getMyPets = async (req, res) => {
  try {
    const pets = await Pet.find({ user: req.user._id }).sort({ createdAt: -1 });
    res.json(pets);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.addPet = async (req, res) => {
  try {
    const {
      name,
      type,
      breed,
      age,
      weight,
      gender,
      mealsPerDay,
      foodReminderTimes,
      vaccineReminderDate,
      notes,
    } = req.body;

    if (!name || !name.trim() || !type) {
      return res.status(400).json({ message: 'Name and type are required' });
    }

    const pet = await Pet.create({
      user: req.user._id,
      name: name.trim(),
      type,
      breed: breed?.trim() || '',
      age: age?.trim() || '',
      weight: weight?.trim() || '',
      gender: gender || 'unknown',
      image: req.file?.filename || null,
      mealsPerDay: Number(mealsPerDay) || 1,
      foodReminderTimes: normalizeReminderTimes(foodReminderTimes),
      vaccineReminderDate: vaccineReminderDate?.trim() || '',
      notes: notes?.trim() || '',
    });

    res.status(201).json(pet);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updatePet = async (req, res) => {
  try {
    const pet = await Pet.findOne({
      _id: req.params.id,
      user: req.user._id,
    });

    if (!pet) {
      return res.status(404).json({ message: 'Pet not found' });
    }

    const {
      name,
      type,
      breed,
      age,
      weight,
      gender,
      mealsPerDay,
      foodReminderTimes,
      vaccineReminderDate,
      notes,
    } = req.body;

    if (name !== undefined) pet.name = name.trim();
    if (type !== undefined) pet.type = type;
    if (breed !== undefined) pet.breed = breed.trim();
    if (age !== undefined) pet.age = age.trim();
    if (weight !== undefined) pet.weight = weight.trim();
    if (gender !== undefined) pet.gender = gender;
    if (mealsPerDay !== undefined) {
      pet.mealsPerDay = Number(mealsPerDay) || 1;
    }
    if (foodReminderTimes !== undefined) {
      pet.foodReminderTimes = normalizeReminderTimes(foodReminderTimes);
    }
    if (vaccineReminderDate !== undefined) {
      pet.vaccineReminderDate = vaccineReminderDate.trim();
    }
    if (notes !== undefined) pet.notes = notes.trim();
    if (req.file) pet.image = req.file.filename;

    await pet.save();

    res.json(pet);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deletePet = async (req, res) => {
  try {
    const pet = await Pet.findOne({
      _id: req.params.id,
      user: req.user._id,
    });

    if (!pet) {
      return res.status(404).json({ message: 'Pet not found' });
    }

    await PetCareLog.deleteMany({ pet: pet._id, user: req.user._id });
    await pet.deleteOne();
    res.json({ message: 'Pet deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
