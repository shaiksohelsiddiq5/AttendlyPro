const express = require("express");
const router = express.Router();
const Reminder = require("../models/Reminder");

// Get reminders
router.get("/api/reminders/:rollNo", async (req, res) => {
  try {
    const reminders = await Reminder.find({ rollNo: req.params.rollNo });
    res.json(reminders);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create reminder
router.post("/api/reminders", async (req, res) => {
  try {
    const { rollNo, title, category, dateTime } = req.body;
    if (!rollNo || !title || !category || !dateTime) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    const newReminder = new Reminder({ rollNo, title, category, dateTime });
    await newReminder.save();
    res.status(201).json(newReminder);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update reminder
router.put("/api/reminders/:id", async (req, res) => {
  try {
    const updated = await Reminder.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: "Reminder not found" });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete reminder
router.delete("/api/reminders/:id", async (req, res) => {
  try {
    const deleted = await Reminder.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "Reminder not found" });
    res.json({ message: "Reminder deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
