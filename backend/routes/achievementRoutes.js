const express = require("express");
const router = express.Router();
const Achievement = require("../models/Achievement");
const User = require("../models/User");
const Assignment = require("../models/Assignment");
const StudyPlan = require("../models/StudyPlan");

// Get achievements list, calculate stats, and persist unlocked badges in MongoDB
router.get("/api/achievements/:rollNo", async (req, res) => {
  try {
    const { rollNo } = req.params;
    
    const user = await User.findOne({ rollNo });
    if (!user) return res.status(404).json({ message: "User not found" });

    // Calculate stats
    const attendancePct = parseFloat(user.currentAttendance) || 0.0;
    const assignments = await Assignment.find({ rollNo });
    const completedAssignments = assignments.filter(a => a.status === "Completed");

    // Study streak
    const studyPlans = await StudyPlan.find({ rollNo });
    // Let's compute study streak by counting consecutive days of study planner goals completed
    // Since we simplified study plans, we can calculate study streak dynamically
    // Let's find unique dates with all goals completed
    const uniqueDates = [...new Set(studyPlans.map(p => p.date))].sort();
    let currentStreak = 0;
    let maxStreak = 0;
    if (uniqueDates.length > 0) {
      currentStreak = 1;
      maxStreak = 1;
      for (let i = 1; i < uniqueDates.length; i++) {
        const prev = new Date(uniqueDates[i - 1]);
        const curr = new Date(uniqueDates[i]);
        const diffTime = Math.abs(curr - prev);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        if (diffDays === 1) {
          currentStreak++;
          if (currentStreak > maxStreak) {
            maxStreak = currentStreak;
          }
        } else if (diffDays > 1) {
          currentStreak = 1;
        }
      }
    }

    const badgeEvaluations = [
      {
        title: "First Login",
        description: "Welcome to Attendly Pro! First login badge unlocked.",
        badgeType: "First Login",
        shouldUnlock: true,
      },
      {
        title: "100% Attendance",
        description: "Maintained a perfect 100% attendance rate.",
        badgeType: "100% Attendance",
        shouldUnlock: attendancePct >= 100.0,
      },
      {
        title: "10 Assignments Completed",
        description: "Completed 10 academic assignments.",
        badgeType: "10 Assignments Completed",
        shouldUnlock: completedAssignments.length >= 10,
      },
      {
        title: "7 Day Study Streak",
        description: "Studied for 7 consecutive days.",
        badgeType: "7 Day Study Streak",
        shouldUnlock: maxStreak >= 7,
      }
    ];

    const badges = [];

    for (const badge of badgeEvaluations) {
      let doc = await Achievement.findOne({ rollNo, title: badge.title });
      if (badge.shouldUnlock) {
        if (!doc) {
          doc = new Achievement({
            rollNo,
            title: badge.title,
            description: badge.description,
            badgeType: badge.badgeType,
          });
          await doc.save();
        }
        badges.push({
          _id: doc._id,
          title: doc.title,
          description: doc.description,
          badgeType: doc.badgeType,
          unlocked: true,
          unlockedAt: doc.unlockedAt
        });
      } else {
        badges.push({
          title: badge.title,
          description: badge.description,
          badgeType: badge.badgeType,
          unlocked: false,
        });
      }
    }

    // Retrieve any manually/custom saved achievements from database
    const customAchievements = await Achievement.find({ rollNo, title: { $nin: badgeEvaluations.map(b => b.title) } });

    res.json({
      success: true,
      badges,
      customAchievements
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create custom achievement manually (leaderboard prep)
router.post("/api/achievements", async (req, res) => {
  try {
    const { rollNo, title, description, badgeType } = req.body;
    if (!rollNo || !title || !description || !badgeType) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    const newAchievement = new Achievement({ rollNo, title, description, badgeType });
    await newAchievement.save();
    res.status(201).json(newAchievement);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
