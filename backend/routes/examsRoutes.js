const express = require("express");
const router = express.Router();
const Exam = require("../models/Exam");
const { getExamsPage } = require("../controllers/examsController");

// Render browser page (backward compatibility)
router.get("/exams", getExamsPage);

// Get exams for a user
router.get("/api/exams/:rollNo", async (req, res) => {
  try {
    const exams = await Exam.find({ rollNo: req.params.rollNo }).sort({ date: 1 });
    res.json(exams);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Add new exam
router.post("/api/exams", async (req, res) => {
  try {
    const { rollNo, subject, examName, date, time, hall, notes } = req.body;
    if (!rollNo || !subject || !examName || !date || !time || !hall) {
      return res.status(400).json({ message: "All fields except notes are required" });
    }
    const newExam = new Exam({
      rollNo,
      subject,
      examName,
      date,
      time,
      hall,
      notes,
    });
    await newExam.save();
    res.status(201).json(newExam);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update exam
router.put("/api/exams/:id", async (req, res) => {
  try {
    const updated = await Exam.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: "Exam not found" });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete exam
router.delete("/api/exams/:id", async (req, res) => {
  try {
    const deleted = await Exam.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "Exam not found" });
    res.json({ message: "Exam deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;