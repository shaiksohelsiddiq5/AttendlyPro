const express = require("express");
const router = express.Router();
const Assignment = require("../models/Assignment");
const StudyPlan = require("../models/StudyPlan");
const CGPA = require("../models/CGPA");
const Attendance = require("../models/Attendance");
const Exam = require("../models/Exam");
const Task = require("../models/Task");
const Notice = require("../models/Notice");

// Get analytics summaries
router.get("/api/analytics/:rollNo", async (req, res) => {
  try {
    const { rollNo } = req.params;

    // 1. Fetch study plans
    const studyPlans = await StudyPlan.find({ rollNo });
    const dateGroups = {};
    for (const plan of studyPlans) {
      if (!dateGroups[plan.date]) {
        dateGroups[plan.date] = { completed: 0, total: 0 };
      }
      dateGroups[plan.date].total++;
      if (plan.completed) {
        dateGroups[plan.date].completed++;
      }
    }
    const studyHoursTrend = Object.keys(dateGroups).map(date => ({
      date,
      hours: dateGroups[date].completed * 1.5, // dynamic estimation based on goals met
      completedGoals: dateGroups[date].completed,
      totalGoals: dateGroups[date].total,
    })).sort((a, b) => a.date.localeCompare(b.date));

    // 2. Fetch assignments
    const assignments = await Assignment.find({ rollNo });
    const pendingAssignments = assignments.filter(a => a.status === "Pending").length;
    const completedAssignments = assignments.filter(a => a.status === "Completed").length;

    // 3. Fetch CGPA
    const cgpaRecord = await CGPA.findOne({ rollNo });
    const cgpaTrend = cgpaRecord ? cgpaRecord.semesters.map(s => ({
      semester: s.semester,
      gpa: s.gpa,
      credits: s.credits,
    })).sort((a, b) => a.semester - b.semester) : [];

    // 4. Fetch subject attendance
    const subjectAttendance = await Attendance.find({ rollNo });
    const attendanceStats = subjectAttendance.map(s => ({
      subject: s.subject,
      attended: s.present,
      total: s.total,
      percentage: s.total === 0 ? 0.0 : parseFloat(((s.present / s.total) * 100).toFixed(1)),
    }));

    // 5. Fetch general stats for dashboard dashboard-wide summary
    const totalExams = await Exam.countDocuments({ rollNo });
    const totalTasks = await Task.countDocuments({ rollNo, completed: false });
    const totalNotices = await Notice.countDocuments({});

    res.json({
      success: true,
      studyHoursTrend,
      assignments: {
        pending: pendingAssignments,
        completed: completedAssignments,
      },
      cgpaTrend,
      attendanceStats,
      generalStats: {
        totalExams,
        totalTasks,
        totalNotices
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
