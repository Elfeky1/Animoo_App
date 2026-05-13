const mongoose = require('mongoose');

const userReportSchema = new mongoose.Schema(
  {
    reporter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    reportedUser: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    conversation: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Conversation',
      default: null,
    },
    ad: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Ad',
      default: null,
    },
    reason: {
      type: String,
      required: true,
      trim: true,
    },
    status: {
      type: String,
      enum: ['open', 'reviewed'],
      default: 'open',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('UserReport', userReportSchema);
