const mongoose = require("mongoose");

const achievementSchema = new mongoose.Schema({
  rollNo: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  badgeType: {
    type: String, // Attendance Badge, Study Streak, Assignment Master, Early Submission, Perfect Week, Gold Student
    required: true,
  },
  unlockedAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model("Achievement", achievementSchema);
