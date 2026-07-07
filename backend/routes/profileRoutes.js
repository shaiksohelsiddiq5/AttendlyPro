const express = require("express");
const router = express.Router();
const User = require("../models/User");
const multer = require("multer");

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname);
  },
});
const upload = multer({ storage });

// Get profile
router.get("/api/profile/:rollNo", async (req, res) => {
  try {
    const user = await User.findOne({ rollNo: req.params.rollNo });
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json({
      success: true,
      profile: {
        name: user.name,
        rollNo: user.rollNo,
        branch: user.branch,
        year: user.year,
        semester: user.semester || "",
        section: user.section || "",
        phone: user.phone || "",
        email: user.email || "",
        skills: user.skills || [],
        photo: user.photo || "",
        resume: user.resume || "",
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update profile including photo and resume upload
router.post("/api/profile/update", upload.fields([
  { name: 'photo', maxCount: 1 },
  { name: 'resume', maxCount: 1 }
]), async (req, res) => {
  try {
    const { rollNo, name, branch, year, semester, section, phone, email, skills } = req.body;
    if (!rollNo) return res.status(400).json({ message: "rollNo is required" });

    const user = await User.findOne({ rollNo });
    if (!user) return res.status(404).json({ message: "User not found" });

    if (name) user.name = name;
    if (branch) user.branch = branch;
    if (year) user.year = year;
    if (semester !== undefined) user.semester = semester;
    if (section !== undefined) user.section = section;
    if (phone !== undefined) user.phone = phone;
    if (email !== undefined) user.email = email;
    
    if (skills) {
      if (typeof skills === "string") {
        user.skills = skills.split(",").map(s => s.trim()).filter(s => s.length > 0);
      } else if (Array.isArray(skills)) {
        user.skills = skills;
      }
    }

    if (req.files) {
      if (req.files.photo && req.files.photo[0]) {
        user.photo = req.files.photo[0].path;
      }
      if (req.files.resume && req.files.resume[0]) {
        user.resume = req.files.resume[0].path;
      }
    }

    await user.save();
    res.json({ success: true, user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Serve HTML for backward compatibility
router.get("/profile", async (req, res) => {
  res.send(`
    <body style="background:#081b3a; color:white; font-family:Arial; padding:50px; text-align:center;">
      <h1>👨‍🎓 Profile Management</h1>
      <p>Please use the Flutter App to view and edit student profile information details.</p>
      <a href="/dashboard"><button style="padding:10px 20px;">Dashboard</button></a>
    </body>
  `);
});

module.exports = router;