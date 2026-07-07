const express = require("express");
const router = express.Router();
const Subject = require("../models/Subject");

// Get subjects for a user
router.get("/api/subjects/:rollNo", async (req, res) => {
  try {
    const subjects = await Subject.find({ rollNo: req.params.rollNo });
    res.json(subjects);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create subject
router.post("/api/subjects", async (req, res) => {
  try {
    const { rollNo, name, code } = req.body;
    if (!rollNo || !name) {
      return res.status(400).json({ message: "rollNo and name are required" });
    }
    const newSubject = new Subject({ rollNo, name, code });
    await newSubject.save();
    res.status(201).json(newSubject);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update subject
router.put("/api/subjects/:id", async (req, res) => {
  try {
    const updated = await Subject.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: "Subject not found" });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete subject
router.delete("/api/subjects/:id", async (req, res) => {
  try {
    const deleted = await Subject.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "Subject not found" });
    res.json({ message: "Subject deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
