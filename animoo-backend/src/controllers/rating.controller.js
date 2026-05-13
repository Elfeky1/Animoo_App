const Rating = require('../models/Rating');

function buildSummary(items) {
  const total = items.length;
  const average =
    total === 0
      ? 0
      : items.reduce((sum, item) => sum + (item.score || 0), 0) / total;

  return {
    average: Number(average.toFixed(1)),
    count: total,
    ratings: items,
  };
}

exports.getUserRatings = async (req, res) => {
  try {
    const ratings = await Rating.find({ ratedUser: req.params.userId })
      .populate('rater', 'name profileImage')
      .populate('ad', 'name')
      .sort({ createdAt: -1 });

    res.json(buildSummary(ratings));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMyRatings = async (req, res) => {
  try {
    const ratings = await Rating.find({ ratedUser: req.user._id })
      .populate('rater', 'name profileImage')
      .populate('ad', 'name')
      .sort({ createdAt: -1 });

    res.json(buildSummary(ratings));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
