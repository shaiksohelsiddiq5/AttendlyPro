const express = require("express");
const router = express.Router();
const Event = require("../models/Event");

// Get all events
router.get("/api/events", async (req, res) => {
  try {
    const events = await Event.find().sort({ date: 1 });
    res.json(events);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create event
router.post("/api/events", async (req, res) => {
  try {
    const { title, description, category, date, location } = req.body;
    if (!title || !category || !date) {
      return res.status(400).json({ message: "Title, Category, and Date are required" });
    }
    const newEvent = new Event({ title, description, category, date, location });
    await newEvent.save();
    res.status(201).json(newEvent);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Register for event
router.post("/api/events/register/:id", async (req, res) => {
  try {
    const { rollNo } = req.body;
    if (!rollNo) return res.status(400).json({ message: "rollNo is required" });
    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ message: "Event not found" });
    if (event.registrationClosed) return res.status(400).json({ message: "Registrations are closed" });
    if (event.registeredStudents.includes(rollNo)) {
      return res.status(400).json({ message: "Already registered" });
    }
    event.registeredStudents.push(rollNo);
    await event.save();
    res.json(event);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update event
router.put("/api/events/:id", async (req, res) => {
  try {
    const updated = await Event.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: "Event not found" });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete event
router.delete("/api/events/:id", async (req, res) => {
  try {
    const deleted = await Event.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "Event not found" });
    res.json({ message: "Event deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
