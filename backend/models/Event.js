const mongoose = require("mongoose");

const eventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: "",
  },
  category: {
    type: String, // College Event, Hackathon, Seminar, Festival, Technical Event, Workshop
    required: true,
  },
  date: {
    type: Date,
    required: true,
  },
  location: {
    type: String,
    default: "",
  },
  registrationClosed: {
    type: Boolean,
    default: false,
  },
  registeredStudents: {
    type: [String], // Array of rollNos
    default: [],
  },
});

module.exports = mongoose.model("Event", eventSchema);
