const express = require("express");
const router = express.Router();
const Notice = require("../models/Notice");

// Get all notices
router.get("/api/notices", async (req, res) => {
  try {
    const notices = await Notice.find().sort({ isPinned: -1, date: -1 });
    res.json(notices);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create notice
router.post("/api/notices", async (req, res) => {
  try {
    const { title, content, category, isPinned } = req.body;
    if (!title || !category) {
      return res.status(400).json({ message: "Title and Category are required" });
    }
    const newNotice = new Notice({ title, content, category, isPinned });
    await newNotice.save();
    res.status(201).json(newNotice);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update notice
router.put("/api/notices/:id", async (req, res) => {
  try {
    const updated = await Notice.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: "Notice not found" });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete notice
router.delete("/api/notices/:id", async (req, res) => {
  try {
    const deleted = await Notice.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "Notice not found" });
    res.json({ message: "Notice deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
