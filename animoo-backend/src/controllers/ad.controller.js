const Ad = require('../models/Ad');
const User = require('../models/User');
const Report = require('../models/Report');

function normalizeDigits(value) {
  if (value === undefined || value === null) return value;

  return value
    .toString()
    .replace(/[٠-٩]/g, (digit) => '٠١٢٣٤٥٦٧٨٩'.indexOf(digit))
    .replace(/[۰-۹]/g, (digit) => '۰۱۲۳۴۵۶۷۸۹'.indexOf(digit));
}

function parseOptionalNumber(value) {
  if (value === undefined || value === null || value.toString().trim() == '') {
    return null;
  }

  const normalized = normalizeDigits(value).trim();
  const parsed = Number(normalized);
  return Number.isNaN(parsed) ? null : parsed;
}

exports.addAd = async (req, res) => {
  try {
    const {
      name,
      description,
      price,
      category,
      existingImages,
      isAdoption,
      age,
      vaccinated,
      healthStatus,
      location,
    } = req.body;

    // تحقق أساسي
    if (
      !name ||
      !description ||
      !category ||
      !req.files?.images ||
      !req.files?.idCard
    ) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // السعر مطلوب فقط لو مش تبني
    if (isAdoption !== 'true' && !price) {
      return res
        .status(400)
        .json({ message: 'Price is required for sale ads' });
    }

    const images = req.files.images.map((f) => f.filename);
    const idCardImage = req.files.idCard[0].filename;

    const ad = await Ad.create({
      name,
      description,

      // لو تبني → السعر null
      price: isAdoption === 'true' ? null : price,

      category,
      isAdoption: isAdoption === 'true',

      age: parseOptionalNumber(age),
      vaccinated:
        vaccinated !== undefined ? vaccinated === 'true' : null,
      healthStatus: healthStatus || null,
      location: location || null,

      images,
      idCardImage,

      user: req.user.id,
      status: 'pending',
    });

    res.status(201).json(ad);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
};



exports.getAnimals = async (req, res) => {
  try {
    const { category, search, adType } = req.query;

    const filter = { status: 'approved' };

    if (category) {
      filter.category = category;
    }

    if (adType === 'adoption') {
      filter.isAdoption = true;
    } else if (adType === 'sale') {
      filter.isAdoption = false;
    }

    if (search && search.trim()) {
      const searchText = search.trim();
      const normalizedSearchText = normalizeDigits(searchText);
      const escapedSearch = searchText.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const searchRegex = new RegExp(escapedSearch, 'i');
      const searchNumber = Number(normalizedSearchText);

      filter.$or = [
        { name: searchRegex },
        { description: searchRegex },
        { price: searchRegex },
        { category: searchRegex },
        { healthStatus: searchRegex },
        { location: searchRegex },
      ];

      if (!Number.isNaN(searchNumber)) {
        filter.$or.push({ age: searchNumber });
      }
    }

    const ads = await Ad.find(filter)
      .populate('user', 'name phone')
      .sort({ createdAt: -1 });
    res.json(ads);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};


exports.getMyAds = async (req, res) => {
  try {
    const ads = await Ad.find({ user: req.user.id })
      .sort({ createdAt: -1 });

    res.json(ads);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};


exports.getPendingAds = async (req, res) => {
  try {
    const ads = await Ad.find({ status: 'pending' })
      .sort({ createdAt: -1 });

    res.json(ads);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.approveAd = async (req, res) => {
  try {
    const ad = await Ad.findByIdAndUpdate(
      req.params.id,
      { status: 'approved' },
      { new: true }
    );

    if (!ad) return res.status(404).json({ message: 'Not found' });

    res.json(ad);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.rejectAd = async (req, res) => {
  try {
    const ad = await Ad.findByIdAndUpdate(
      req.params.id,
      { status: 'rejected' },
      { new: true }
    );

    if (!ad) return res.status(404).json({ message: 'Not found' });

    res.json(ad);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }


};


exports.updateAd = async (req, res) => {
  try {
    console.log('UPDATE AD HIT');
    console.log('PARAM ID:', req.params.id);
    console.log('BODY:', req.body);

    const ad = await Ad.findById(req.params.id);

    if (!ad) {
      return res.status(404).json({ message: 'Ad not found' });
    }

    
    if (ad.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not allowed' });
    }

    
    if (ad.status !== 'pending') {
      return res.status(403).json({
        message: 'You cannot edit this ad after approval or rejection',
      });
    }

    const {
      name,
      description,
      price,
      category,
      isAdoption,
      age,
      vaccinated,
      healthStatus,
      location,
    } = req.body;

    if (name !== undefined) ad.name = name;
    if (description !== undefined) ad.description = description;
    if (category !== undefined) ad.category = category;

    if (isAdoption !== undefined) {
      ad.isAdoption = isAdoption === 'true';
      ad.price = isAdoption === 'true' ? null : price;
    } else if (price !== undefined) {
      ad.price = price;
    }

    if (age !== undefined) ad.age = parseOptionalNumber(age);
    if (vaccinated !== undefined)
      ad.vaccinated = vaccinated === 'true';
    if (healthStatus !== undefined)
      ad.healthStatus = healthStatus;
    if (location !== undefined) ad.location = location;

    let keptImages = ad.images;
    if (existingImages !== undefined) {
      try {
        const parsedImages = JSON.parse(existingImages);
        if (Array.isArray(parsedImages)) {
          keptImages = parsedImages;
        }
      } catch (_) {}
    }

    if (req.files?.images?.length) {
      const uploadedImages = req.files.images.map((f) => f.filename);
      ad.images = [...keptImages, ...uploadedImages];
    } else {
      ad.images = keptImages;
    }

    await ad.save();

    res.json({
      message: 'Ad updated successfully',
      ad,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
  }
};

exports.deleteAd = async (req, res) => {
  try {
    const { id } = req.params;

    const ad = await Ad.findById(id);

    if (!ad) {
      return res.status(404).json({ message: 'Ad not found' });
    }

    
    if (ad.user.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not allowed' });
    }

    await ad.deleteOne();

    res.json({ message: 'Ad deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};


exports.getAdStats = async (req, res) => {
  try {
    const pending = await Ad.countDocuments({ status: 'pending' });
    const approved = await Ad.countDocuments({ status: 'approved' });
    const rejected = await Ad.countDocuments({ status: 'rejected' });

    res.json({
      pending,
      approved,
      rejected,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};


exports.getApprovedAds = async (req, res) => {
  try {
    const ads = await Ad.find({ status: 'approved' })
      .sort({ createdAt: -1 });
    res.json(ads);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.toggleFavorite = async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id);

    if (!ad) {
      return res.status(404).json({ message: 'Ad not found' });
    }

    const user = await User.findById(req.user._id);
    const exists = user.favorites.some(
      (favoriteId) => favoriteId.toString() === req.params.id
    );

    if (exists) {
      user.favorites = user.favorites.filter(
        (favoriteId) => favoriteId.toString() !== req.params.id
      );
    } else {
      user.favorites.push(ad._id);
    }

    await user.save();

    res.json({ isFavorite: !exists });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.markAdUnavailable = async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id);

    if (!ad) {
      return res.status(404).json({ message: 'Ad not found' });
    }

    if (ad.user.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not allowed' });
    }

    const nextStatus = req.body.status?.toString();
    const allowedStatus = ad.isAdoption ? 'adopted' : 'sold';

    if (nextStatus != allowedStatus) {
      return res.status(400).json({ message: 'Invalid availability status' });
    }

    ad.availabilityStatus = nextStatus;
    await ad.save();

    res.json({ message: 'Ad updated', ad });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getFavorites = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate({
      path: 'favorites',
      populate: { path: 'user', select: 'name phone' },
    });

    res.json(user?.favorites || []);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.reportAd = async (req, res) => {
  try {
    const { reason } = req.body;

    if (!reason || !reason.trim()) {
      return res.status(400).json({ message: 'Reason is required' });
    }

    const ad = await Ad.findById(req.params.id);

    if (!ad) {
      return res.status(404).json({ message: 'Ad not found' });
    }

    await Report.create({
      reporter: req.user._id,
      ad: ad._id,
      reason: reason.trim(),
    });

    res.status(201).json({ message: 'Report submitted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
