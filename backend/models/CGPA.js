const mongoose = require("mongoose");

const semesterResultSchema = new mongoose.Schema({
  semester: {
    type: Number,
    required: true,
  },
  gpa: {
    type: Number,
    required: true,
  },
  targetGpa: {
    type: Number,
    default: 0.0,
  },
  credits: {
    type: Number,
    default: 0,
  },
});

const cgpaSchema = new mongoose.Schema({
  rollNo: {
    type: String,
    required: true,
    unique: true,
  },
  semesters: [semesterResultSchema],
  targetCgpa: {
    type: Number,
    default: 0.0,
  },
});

module.exports = mongoose.model("CGPA", cgpaSchema);
