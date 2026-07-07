const express = require("express");
const multer = require("multer");
const router = express.Router();
const FileModel = require("../models/File");

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname);
  },
});
const upload = multer({ storage });

// Get files for a student
router.get("/api/files/:rollNo", async (req, res) => {
  try {
    const files = await FileModel.find({ rollNo: req.params.rollNo });
    res.json(files);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Upload file
router.post("/api/files", upload.single("file"), async (req, res) => {
  try {
    const { rollNo, category } = req.body;
    if (!rollNo || !category) {
      return res.status(400).json({ message: "rollNo and category are required" });
    }
    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }
    const newFile = new FileModel({
      rollNo,
      fileName: req.file.originalname,
      fileType: req.file.mimetype,
      filePath: req.file.path,
      category,
    });
    await newFile.save();
    res.status(201).json(newFile);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Download file
router.get("/api/files/download/:id", async (req, res) => {
  try {
    const file = await FileModel.findById(req.params.id);
    if (!file) return res.status(404).json({ message: "File not found" });
    res.download(file.filePath, file.fileName);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete file
router.delete("/api/files/:id", async (req, res) => {
  try {
    const deleted = await FileModel.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "File not found" });
    res.json({ message: "File deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
