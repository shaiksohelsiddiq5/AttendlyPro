const express = require("express");
const router = express.Router();
const Task = require("../models/Task");

// Get tasks
router.get("/api/tasks/:rollNo", async (req, res) => {
  try {
    const tasks = await Task.find({ rollNo: req.params.rollNo });
    res.json(tasks);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create task
router.post("/api/tasks", async (req, res) => {
  try {
    const { rollNo, title, priority, deadline, category } = req.body;
    if (!rollNo || !title) {
      return res.status(400).json({ message: "rollNo and title are required" });
    }
    const newTask = new Task({ rollNo, title, priority, deadline, category });
    await newTask.save();
    res.status(201).json(newTask);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update task
router.put("/api/tasks/:id", async (req, res) => {
  try {
    const updated = await Task.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: "Task not found" });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete task
router.delete("/api/tasks/:id", async (req, res) => {
  try {
    const deleted = await Task.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "Task not found" });
    res.json({ message: "Task deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
