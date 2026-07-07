const mongoose = require("mongoose");

const subjectSchema = new mongoose.Schema({
  rollNo: {
    type: String,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  code: {
    type: String,
    default: "",
  },
});

module.exports = mongoose.model("Subject", subjectSchema);
