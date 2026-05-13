const mongoose = require('mongoose');

const petSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      required: true,
      enum: ['dog', 'cat', 'bird', 'other'],
    },
    breed: {
      type: String,
      default: '',
      trim: true,
    },
    age: {
      type: String,
      default: '',
      trim: true,
    },
    weight: {
      type: String,
      default: '',
      trim: true,
    },
    gender: {
      type: String,
      enum: ['male', 'female', 'unknown'],
      default: 'unknown',
    },
    image: {
      type: String,
      default: null,
    },
    mealsPerDay: {
      type: Number,
      default: 1,
      min: 1,
      max: 5,
    },
    foodReminderTimes: {
      type: [String],
      default: [],
    },
    vaccineReminderDate: {
      type: String,
      default: '',
      trim: true,
    },
    notes: {
      type: String,
      default: '',
      trim: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Pet', petSchema);
