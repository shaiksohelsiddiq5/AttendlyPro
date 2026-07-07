const express = require("express");
const router = express.Router();
const CGPA = require("../models/CGPA");

// Get CGPA info for a student
router.get("/api/cgpa/:rollNo", async (req, res) => {
  try {
    let cgpa = await CGPA.findOne({ rollNo: req.params.rollNo });
    if (!cgpa) {
      cgpa = new CGPA({ rollNo: req.params.rollNo, semesters: [], targetCgpa: 8.0 });
      await cgpa.save();
    }
    res.json(cgpa);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update or set CGPA records
router.post("/api/cgpa", async (req, res) => {
  try {
    const { rollNo, semesters, targetCgpa } = req.body;
    if (!rollNo) {
      return res.status(400).json({ message: "rollNo is required" });
    }
    let cgpa = await CGPA.findOne({ rollNo });
    if (cgpa) {
      if (semesters) cgpa.semesters = semesters;
      if (targetCgpa !== undefined) cgpa.targetCgpa = targetCgpa;
      await cgpa.save();
    } else {
      cgpa = new CGPA({ rollNo, semesters, targetCgpa });
      await cgpa.save();
    }
    res.json(cgpa);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete CGPA record
router.delete("/api/cgpa/:id", async (req, res) => {
  try {
    const deleted = await CGPA.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ message: "CGPA record not found" });
    res.json({ message: "CGPA record deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
