const mongoose = require("mongoose");

const reminderSchema = new mongoose.Schema({
  rollNo: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  category: {
    type: String, // Assignment, Exam, Study Time, Attendance, Event, Project, Deadline
    required: true,
  },
  dateTime: {
    type: Date,
    required: true,
  },
  completed: {
    type: Boolean,
    default: false,
  },
});

module.exports = mongoose.model("Reminder", reminderSchema);
