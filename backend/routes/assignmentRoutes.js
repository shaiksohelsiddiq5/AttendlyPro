const express = require("express");
const router = express.Router();
const Assignment = require("../models/Assignment");

// Get assignments for a user
router.get("/api/assignments/:rollNo", async (req, res) => {
  try {
    const assignments = await Assignment.find({ rollNo: req.params.rollNo });
    res.json(assignments);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create assignment
router.post("/api/assignments", async (req, res) => {
  try {
    const { rollNo, subject, title, dueDate, priority, description, attachment, status } = req.body;
    if (!rollNo || !subject || !title || !dueDate) {
      return res.status(400).json({ message: "rollNo, subject, title, and dueDate are required" });
    }
    const newAssignment = new Assignment({
      rollNo,
      subject,
      title,
      dueDate,
      priority,
      description,
      attachment,
      status
    });
    await newAssignment.save();
    res.status(201).json(newAssignment);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update assignment
router.put("/api/assignments/:id", async (req, res) => {
  try {
    if (req.body.status === "Completed" && !req.body.completedDate) {
      req.body.completedDate = new Date();
    }
    const updated = await Assignment.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: "Assignment not found" });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete assignment
router.delete("/api/assignments/:id", async (req, res) => {
  try {
    const deleted = await Assignment.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "Assignment not found" });
    res.json({ message: "Assignment deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
