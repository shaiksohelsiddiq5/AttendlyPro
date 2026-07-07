const express = require("express");
const multer = require("multer");
const router = express.Router();
const Note = require("../models/Note");

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname);
  },
});
const upload = multer({ storage });

// Get notes
router.get("/api/notes/:rollNo", async (req, res) => {
  try {
    const notes = await Note.find({ rollNo: req.params.rollNo });
    res.json(notes);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Upload a note
router.post("/api/notes", upload.single("file"), async (req, res) => {
  try {
    const { rollNo, subject, title, fileType, description } = req.body;
    if (!rollNo || !subject || !title || !fileType) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }
    const newNote = new Note({
      rollNo,
      subject,
      title,
      fileName: req.file.originalname,
      fileType,
      filePath: req.file.path,
      description: description || "",
    });
    await newNote.save();
    res.status(201).json(newNote);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update note (edit title, subject, description)
router.put("/api/notes/:id", async (req, res) => {
  try {
    const { title, subject, description } = req.body;
    const note = await Note.findById(req.params.id);
    if (!note) return res.status(404).json({ message: "Note not found" });
    if (title) note.title = title;
    if (subject) note.subject = subject;
    if (description !== undefined) note.description = description;
    await note.save();
    res.json(note);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Toggle Favorite Note
router.put("/api/notes/:id/favorite", async (req, res) => {
  try {
    const note = await Note.findById(req.params.id);
    if (!note) return res.status(404).json({ message: "Note not found" });
    note.isFavorite = !note.isFavorite;
    await note.save();
    res.json(note);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Download note (serves file)
router.get("/api/notes/download/:id", async (req, res) => {
  try {
    const note = await Note.findById(req.params.id);
    if (!note) return res.status(404).json({ message: "Note not found" });
    res.download(note.filePath, note.fileName);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete note
router.delete("/api/notes/:id", async (req, res) => {
  try {
    const deleted = await Note.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "Note not found" });
    res.json({ message: "Note deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
