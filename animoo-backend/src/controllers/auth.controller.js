const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Ad = require('../models/Ad');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const Notification = require('../models/Notification');
const Pet = require('../models/Pet');
const PetCareLog = require('../models/PetCareLog');
const Report = require('../models/Report');
const UserReport = require('../models/UserReport');
const transporter = require('../config/mail');
const generateOtp = require('../utils/generateOtp');


exports.sendOtp = async (req, res) => {
  try {
    const { email, phone } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    let user = await User.findOne({ email });
    if (!user) user = new User({ email, phone });

    const otp = generateOtp();

    user.otpCode = otp;
    user.otpExpires = Date.now() + 5 * 60 * 1000;
    await user.save();

    await transporter.sendMail({
      from: `"Animoo" <${process.env.MAIL_USER}>`,
      to: email,
      subject: 'Your OTP Code',
      html: `<h2>Your OTP is: ${otp}</h2><p>Valid for 5 minutes</p>`,
    });

    res.status(200).json({ message: 'OTP sent successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Failed to send OTP' });
  }
};


exports.verifyOtp = async (req, res) => {
  const { email, otp } = req.body;

  const user = await User.findOne({ email });
  if (!user) return res.status(400).json({ message: 'User not found' });

  if (
    user.otpCode !== otp ||
    !user.otpExpires ||
    user.otpExpires < Date.now()
  ) {
    return res.status(400).json({ message: 'Invalid or expired OTP' });
  }

  user.isVerified = true;
  user.otpCode = null;
  user.otpExpires = null;
  await user.save();

  res.json({ message: 'OTP verified' });
};


exports.register = async (req, res) => {
  const { name, email, phone, password } = req.body;

  const hashed = await bcrypt.hash(password, 10);

  const user = await User.findOneAndUpdate(
    { email },
    { name, phone, password: hashed, isVerified: true },
    { new: true }
  );

  res.status(201).json({ message: 'User registered' });
};


exports.login = async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email });
  if (!user) return res.status(400).json({ message: 'Invalid credentials' });

  if (user.isBanned) {
  return res.status(403).json({
    message: "Your account has been banned. Please contact support."
  });
}

  const match = await bcrypt.compare(password, user.password);
  if (!match) return res.status(400).json({ message: 'Invalid credentials' });

  const token = jwt.sign({ id: user._id,role: user.role, }, process.env.JWT_SECRET, {
    expiresIn: '7d',
  });

  res.json({ token ,
    role: user.role,
    userId: user._id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    profileImage: user.profileImage,
  });
};

exports.me = async (req, res) => {
  res.json({
    _id: req.user._id,
    name: req.user.name,
    email: req.user.email,
    phone: req.user.phone,
    role: req.user.role,
    profileImage: req.user.profileImage,
  });
};

exports.publicProfile = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select(
      'name phone email profileImage role'
    );

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      _id: user._id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      profileImage: user.profileImage,
      role: user.role,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const name = req.body.name?.toString().trim();
    const phone = req.body.phone?.toString().trim();

    if (!name) {
      return res.status(400).json({ message: 'Name is required' });
    }

    req.user.name = name;
    req.user.phone = phone || '';
    if (req.file) {
      req.user.profileImage = req.file.filename;
    }
    await req.user.save();

    res.json({
      _id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      phone: req.user.phone,
      role: req.user.role,
      profileImage: req.user.profileImage,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteAccount = async (req, res) => {
  try {
    const userId = req.user._id;

    const userAds = await Ad.find({ user: userId }).select('_id');
    const adIds = userAds.map((ad) => ad._id);

    const pets = await Pet.find({ user: userId }).select('_id');
    const petIds = pets.map((pet) => pet._id);

    const conversations = await Conversation.find({
      participants: userId,
    }).select('_id');
    const conversationIds = conversations.map((conversation) => conversation._id);

    await Message.deleteMany({
      $or: [
        { sender: userId },
        { conversation: { $in: conversationIds } },
      ],
    });

    await Conversation.deleteMany({
      participants: userId,
    });

    await Notification.deleteMany({ user: userId });
    await PetCareLog.deleteMany({
      $or: [
        { user: userId },
        { pet: { $in: petIds } },
      ],
    });
    await Pet.deleteMany({ user: userId });

    await Report.deleteMany({
      $or: [
        { reporter: userId },
        { ad: { $in: adIds } },
      ],
    });

    await UserReport.deleteMany({
      $or: [
        { reporter: userId },
        { reportedUser: userId },
        { conversation: { $in: conversationIds } },
        { ad: { $in: adIds } },
      ],
    });

    await Ad.deleteMany({ user: userId });

    await User.updateMany(
      {},
      {
        $pull: {
          favorites: { $in: adIds },
          blockedUsers: userId,
        },
      }
    );

    await User.findByIdAndDelete(userId);

    res.json({ message: 'Account deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};


exports.resetPassword = async (req, res) => {
  const { email, password } = req.body;

  const hashed = await bcrypt.hash(password, 10);

  await User.findOneAndUpdate({ email }, { password: hashed });

  res.json({ message: 'Password updated' });
};
