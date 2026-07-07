const mongoose = require("mongoose");

const assignmentSchema = new mongoose.Schema({
  rollNo: {
    type: String,
    required: true,
  },
  subject: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  dueDate: {
    type: Date,
    required: true,
  },
  priority: {
    type: String, // High, Medium, Low
    default: "Medium",
  },
  description: {
    type: String,
    default: "",
  },
  attachment: {
    type: String,
    default: "",
  },
  status: {
    type: String, // Pending, Completed
    default: "Pending",
  },
  completedDate: {
    type: Date,
  },
});

module.exports = mongoose.model("Assignment", assignmentSchema);
