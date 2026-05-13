const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: String,
    email: { type: String, unique: true },
    phone: String,
    profileImage: {
      type: String,
      default: null,
    },
    password: { type: String, required: false }
,

    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user',
    },

    isBanned: {
      type: Boolean,
      default: false,
    },

    isVerified: {
      type: Boolean,
      default: false,
    },

    otpCode: {
      type: String,
    },
    otpExpires: {
      type: Number, 
    },
    favorites: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Ad',
      },
    ],
    blockedUsers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
