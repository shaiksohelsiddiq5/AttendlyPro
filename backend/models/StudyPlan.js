const mongoose = require("mongoose");

const studyPlanSchema = new mongoose.Schema({
  rollNo: {
    type: String,
    required: true,
  },
  goal: {
    type: String,
    required: true,
  },
  date: {
    type: String, // YYYY-MM-DD
    required: true,
  },
  completed: {
    type: Boolean,
    default: false,
  },
  priority: {
    type: String, // High, Medium, Low
    default: "Medium",
  },
});

module.exports = mongoose.model("StudyPlan", studyPlanSchema);
