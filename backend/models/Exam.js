const mongoose = require("mongoose");

const examSchema = new mongoose.Schema({
  rollNo: {
    type: String,
    required: true,
  },
  subject: {
    type: String,
    required: true,
  },
  examName: {
    type: String,
    required: true,
  },
  date: {
    type: Date,
    required: true,
  },
  time: {
    type: String,
    required: true,
  },
  hall: {
    type: String,
    required: true,
  },
  notes: {
    type: String,
    default: "",
  },
});

module.exports = mongoose.model("Exam", examSchema);
