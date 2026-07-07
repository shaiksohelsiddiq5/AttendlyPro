const express = require("express");
const router = express.Router();
const StudyPlan = require("../models/StudyPlan");

// Get study plans/goals for a user
router.get("/api/study-plans/:rollNo", async (req, res) => {
  try {
    const plans = await StudyPlan.find({ rollNo: req.params.rollNo });
    res.json(plans);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create study planner goal
router.post("/api/study-plans", async (req, res) => {
  try {
    const { rollNo, goal, date, completed, priority } = req.body;
    if (!rollNo || !goal || !date) {
      return res.status(400).json({ message: "rollNo, goal, and date are required" });
    }
    const newPlan = new StudyPlan({
      rollNo,
      goal,
      date,
      completed: completed || false,
      priority: priority || "Medium"
    });
    await newPlan.save();
    res.status(201).json(newPlan);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update study planner goal (edit description, priority, or toggle complete status)
router.put("/api/study-plans/:id", async (req, res) => {
  try {
    const updated = await StudyPlan.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: "Study goal not found" });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete study planner goal
router.delete("/api/study-plans/:id", async (req, res) => {
  try {
    const deleted = await StudyPlan.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "Study goal not found" });
    res.json({ message: "Study goal deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
