const mongoose = require("mongoose");

const taskSchema = new mongoose.Schema({
  rollNo: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  priority: {
    type: String, // High, Medium, Low
    default: "Medium",
  },
  deadline: {
    type: Date,
  },
  description: {
    type: String,
    default: "",
  },
  completed: {
    type: Boolean,
    default: false,
  },
  category: {
    type: String,
    default: "General",
  },
});

module.exports = mongoose.model("Task", taskSchema);
