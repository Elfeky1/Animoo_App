const User = require('../models/User');
const Ad = require('../models/Ad');
const Report = require('../models/Report');
const UserReport = require('../models/UserReport');

exports.getUsers = async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.toggleBan = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.isBanned = !user.isBanned;
    await user.save();

    res.json({
      message: user.isBanned ? 'User banned' : 'User unbanned',
      user,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.changeRole = async (req, res) => {
  try {
    const { role } = req.body;

    if (!['user', 'admin'].includes(role)) {
      return res.status(400).json({ message: 'Invalid role' });
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      message: 'Role updated',
      user,
    });
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

    if (!ad) {
      return res.status(404).json({ message: 'Ad not found' });
    }

    res.json({ message: 'Ad approved', ad });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getReports = async (req, res) => {
  try {
    const adReports = await Report.find()
      .populate('reporter', 'name email phone profileImage')
      .populate({
        path: 'ad',
        select: 'name images idCardImage status availabilityStatus category user',
        populate: {
          path: 'user',
          select: 'name email phone profileImage',
        },
      })
      .sort({ createdAt: -1 });

    const userReports = await UserReport.find()
      .populate('reporter', 'name email phone profileImage')
      .populate('reportedUser', 'name email phone isBanned profileImage')
      .populate({
        path: 'ad',
        select: 'name images status availabilityStatus user',
        populate: {
          path: 'user',
          select: 'name email phone profileImage',
        },
      })
      .sort({ createdAt: -1 });

    res.json({
      adReports,
      userReports,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.reviewAdReport = async (req, res) => {
  try {
    const report = await Report.findByIdAndUpdate(
      req.params.id,
      { status: 'reviewed' },
      { new: true }
    );

    if (!report) {
      return res.status(404).json({ message: 'Report not found' });
    }

    res.json({ message: 'Ad report reviewed', report });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.reviewUserReport = async (req, res) => {
  try {
    const report = await UserReport.findByIdAndUpdate(
      req.params.id,
      { status: 'reviewed' },
      { new: true }
    );

    if (!report) {
      return res.status(404).json({ message: 'Report not found' });
    }

    res.json({ message: 'User report reviewed', report });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
