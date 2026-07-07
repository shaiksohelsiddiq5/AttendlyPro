const mongoose = require("mongoose");

const fileSchema = new mongoose.Schema({
  rollNo: {
    type: String,
    required: true,
  },
  fileName: {
    type: String,
    required: true,
  },
  fileType: {
    type: String,
    required: true,
  },
  filePath: {
    type: String,
    required: true,
  },
  category: {
    type: String, // Assignment, Resume, Certificate, Notes, Image, PDF
    required: true,
  },
  uploadedAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model("File", fileSchema);
