const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },

  rollNo: {
    type: String,
    required: true,
    unique: true,
  },

  password: {
    type: String,
    required: true,
  },

  branch: String,
  year: String,
  currentAttendance: {
    type: String,
    default: "",
  },
  targetAttendance: {
    type: String,
    default: "",
  },
  attendedClasses: {
    type: Number,
    default: 0,
  },
  totalClasses: {
    type: Number,
    default: 0,
  },
  setupComplete: {
    type: Boolean,
    default: false,
  },
  calendarFileName: {
    type: String,
    default: "",
  },
  timetableFileName: {
    type: String,
    default: "",
  },
  securityQuestion: {
    type: String,
    default: "",
  },
  securityAnswer: {
    type: String,
    default: "",
  },
  // New profile fields
  photo: {
    type: String,
    default: "",
  },
  skills: {
    type: [String],
    default: [],
  },
  semester: {
    type: String,
    default: "",
  },
  section: {
    type: String,
    default: "",
  },
  phone: {
    type: String,
    default: "",
  },
  email: {
    type: String,
    default: "",
  },
  resume: {
    type: String,
    default: "",
  },
});

module.exports = mongoose.model(
  "User",
  userSchema
);