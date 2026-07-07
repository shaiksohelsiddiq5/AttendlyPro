import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/storage_service.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String name = '';
  String branch = '';
  String year = '';
  String calendarFile = '';
  String timetableFile = '';
  double attendance = 0;
  double target = 75;

  // New Date-Specific State Variables
  DateTime _selectedDate = DateTime(2025, 7, 5);
  DateTime _commencementDate = DateTime(2025, 7, 5);
  List _todaySessions = [];
  List _attendanceRecords = [];
  Map<String, String> _dailyLogs = {}; // Maps "Subject_Period" -> "present" / "absent"
  List _upcomingHolidays = [];
  List _upcomingExams = [];
  bool _loadingDateData = false;
  bool _isCustomDateSelected = false;

  // Smart Productivity Platform State Variables
  int _pendingAssignmentsCount = 0;
  int _totalNotesCount = 0;
  int _todayStudyGoalsCount = 0;
  int _todayStudyGoalsCompleted = 0;
  double _studyGoalsCompletion = 0.0;
  int _upcomingExamsCount = 0;
  int _totalNoticesCount = 0;
  String _latestNoticeTitle = "No Notice";
  int _pendingTasksCount = 0;
  List _latestNotices = [];
  List _recentNotes = [];
  double _currentCgpa = 0.0;
  int _unlockedAchievementsCount = 0;
  int _upcomingEventsCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isNotEmpty) {
        final response = await http.get(
          Uri.parse("${ApiService.baseUrl}/api/user-stats/$rollNo"),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['stats'] != null) {
            final stats = data['stats'];
            
            await StorageService.saveSetup(
              stats['branch']?.toString() ?? '',
              stats['year']?.toString() ?? '',
              stats['currentAttendance']?.toString() ?? '0',
              stats['targetAttendance']?.toString() ?? '75',
            );

            await StorageService.saveAttendanceCounts(
              (stats['attendedClasses'] as num? ?? 0).toInt(),
              (stats['totalClasses'] as num? ?? 0).toInt(),
            );

            if (stats['calendarFileName'] != null) {
              await StorageService.saveCalendar(stats['calendarFileName'].toString());
            }

            if (stats['timetableFileName'] != null) {
              await StorageService.saveTimetable(stats['timetableFileName'].toString(), "");
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Dashboard sync failed: $e");
    }

    final values = await Future.wait([
      StorageService.getName(),
      StorageService.getBranch(),
      StorageService.getYear(),
      StorageService.getAttendance(),
      StorageService.getTarget(),
      StorageService.getCalendarFileName(),
      StorageService.getTimetableFileName(),
      StorageService.getSelectedDate(),
    ]);
    if (!mounted) return;

    DateTime finalDate = DateTime.now();
    final savedDateStr = values[7];
    bool isCustom = false;

    DateTime calendarStart = DateTime(2025, 7, 5);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isNotEmpty) {
        final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/calendar/commencement/$rollNo"));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true && data['startDate'] != null) {
            final parsed = DateTime.tryParse(data['startDate']);
            if (parsed != null) {
              calendarStart = parsed;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch commencement date: $e");
    }

    if (savedDateStr.isNotEmpty) {
      final parsed = DateTime.tryParse(savedDateStr);
      if (parsed != null) {
        finalDate = parsed;
        isCustom = true;
      }
    } else {
      final totalClasses = await StorageService.getTotalClasses();
      if (totalClasses == 0) {
        finalDate = calendarStart;
      } else {
        finalDate = DateTime.now();
      }
    }

    setState(() {
      name = values[0];
      branch = values[1];
      year = values[2];
      attendance = double.tryParse(values[3]) ?? 0;
      target = double.tryParse(values[4]) ?? 75;
      calendarFile = values[5];
      timetableFile = values[6];
      _selectedDate = finalDate;
      _commencementDate = calendarStart;
      _isCustomDateSelected = isCustom;
    });

    // Refresh Date Specific Data
    await _loadDateSpecificData();
  }

  Future<void> _loadDateSpecificData() async {
    if (!mounted) return;
    setState(() => _loadingDateData = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;

      final weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
      final weekdayName = weekdays[_selectedDate.weekday - 1];

      // 1. Fetch timetable sessions
      final timetableRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/timetable/$rollNo"));
      List sessions = [];
      if (timetableRes.statusCode == 200) {
        final data = jsonDecode(timetableRes.body);
        if (data['success'] == true && data['sessions'] != null) {
          sessions = (data['sessions'] as List)
              .where((s) => s['day']?.toString().toLowerCase() == weekdayName.toLowerCase())
              .toList();
          sessions.sort((a, b) => (a['period']?.toString() ?? '').compareTo(b['period']?.toString() ?? ''));
        }
      }

      // 2. Fetch daily logs for selected date
      final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final logRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/daily-log/$rollNo/$dateStr"));
      Map<String, String> logs = {};
      if (logRes.statusCode == 200) {
        final data = jsonDecode(logRes.body);
        if (data['success'] == true && data['logs'] != null) {
          for (final log in data['logs']) {
            final key = "${log['subject']}_${log['period']}";
            logs[key] = log['status']?.toString() ?? '';
          }
        }
      }

      // 3. Fetch subject wise attendance data
      final attRes = await http.get(Uri.parse("${ApiService.baseUrl}/attendance/$rollNo"));
      List attData = [];
      if (attRes.statusCode == 200) {
        attData = jsonDecode(attRes.body) as List;
      }

      // 4. Fetch calendar holidays
      final holidaysRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/holidays/$rollNo"));
      List upcomingHols = [];
      if (holidaysRes.statusCode == 200) {
        final List allHols = jsonDecode(holidaysRes.body) as List;
        upcomingHols = allHols.where((h) {
          final hDate = DateTime.tryParse(h['date']?.toString() ?? '');
          if (hDate == null) return false;
          final hD = DateTime(hDate.year, hDate.month, hDate.day);
          final sD = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
          return hD.isAfter(sD) || hD.isAtSameMomentAs(sD);
        }).toList();
        upcomingHols.sort((a, b) => (a['date']?.toString() ?? '').compareTo(b['date']?.toString() ?? ''));
      }

      // 5. Fetch calendar exams
      final examsRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/exams/$rollNo"));
      List upcomingExs = [];
      if (examsRes.statusCode == 200) {
        final List allExs = jsonDecode(examsRes.body) as List;
        upcomingExs = allExs.where((e) {
          final eDate = DateTime.tryParse(e['date']?.toString() ?? '');
          if (eDate == null) return false;
          final eD = DateTime(eDate.year, eDate.month, eDate.day);
          final sD = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
          return eD.isAfter(sD) || eD.isAtSameMomentAs(sD);
        }).toList();
        upcomingExs.sort((a, b) => (a['date']?.toString() ?? '').compareTo(b['date']?.toString() ?? ''));
      }

      // 6. Fetch pending assignments
      int pendingAssignments = 0;
      try {
        final assignmentsRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/assignments/$rollNo"));
        if (assignmentsRes.statusCode == 200) {
          final List list = jsonDecode(assignmentsRes.body) as List;
          pendingAssignments = list.where((a) => a['status'] == 'Pending').length;
        }
      } catch (e) {
        debugPrint("Failed to fetch assignments: $e");
      }

      // 7. Fetch study planner goals
      double goalsCompletion = 0.0;
      int studyGoalsTotal = 0;
      int studyGoalsCompleted = 0;
      try {
        final studyRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/study-plans/$rollNo"));
        if (studyRes.statusCode == 200) {
          final List plans = jsonDecode(studyRes.body) as List;
          final todayGoals = plans.where((p) => p['date'] == dateStr).toList();
          studyGoalsTotal = todayGoals.length;
          studyGoalsCompleted = todayGoals.where((g) => g['completed'] == true).length;
          goalsCompletion = studyGoalsTotal == 0 ? 0.0 : studyGoalsCompleted / studyGoalsTotal;
        }
      } catch (e) {
        debugPrint("Failed to fetch study goals: $e");
      }

      // 8. Fetch latest notices
      List noticesList = [];
      try {
        final noticesRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/notices"));
        if (noticesRes.statusCode == 200) {
          noticesList = jsonDecode(noticesRes.body) as List;
        }
      } catch (e) {
        debugPrint("Failed to fetch notices: $e");
      }

      // 9. Fetch recent notes
      List notesList = [];
      try {
        final notesRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/notes/$rollNo"));
        if (notesRes.statusCode == 200) {
          notesList = jsonDecode(notesRes.body) as List;
        }
      } catch (e) {
        debugPrint("Failed to fetch notes: $e");
      }

      // 10. Fetch pending tasks
      int pendingTasks = 0;
      try {
        final tasksRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/tasks/$rollNo"));
        if (tasksRes.statusCode == 200) {
          final List list = jsonDecode(tasksRes.body) as List;
          pendingTasks = list.where((t) => t['completed'] == false).length;
        }
      } catch (e) {
        debugPrint("Failed to fetch tasks: $e");
      }

      // 11. Fetch upcoming events count
      int upcomingEvents = 0;
      try {
        final eventsRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/events"));
        if (eventsRes.statusCode == 200) {
          final List list = jsonDecode(eventsRes.body) as List;
          final now = DateTime.now();
          upcomingEvents = list.where((e) {
            final eDate = DateTime.tryParse(e['date']?.toString() ?? '');
            if (eDate == null) return false;
            return eDate.isAfter(now);
          }).length;
        }
      } catch (e) {
        debugPrint("Failed to fetch events: $e");
      }

      // 12. Fetch CGPA
      double currentCgpa = 0.0;
      try {
        final cgpaRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/cgpa/$rollNo"));
        if (cgpaRes.statusCode == 200) {
          final data = jsonDecode(cgpaRes.body);
          final List sems = data['semesters'] ?? [];
          double totalGradePoints = 0.0;
          int totalCreditsCount = 0;
          for (final sem in sems) {
            final gpa = ((sem['gpa'] ?? 0.0) as num).toDouble();
            final creds = ((sem['credits'] ?? 0) as num).toInt();
            totalGradePoints += gpa * creds;
            totalCreditsCount += creds;
          }
          currentCgpa = totalCreditsCount == 0 ? 0.0 : totalGradePoints / totalCreditsCount;
        }
      } catch (e) {
        debugPrint("Failed to fetch CGPA: $e");
      }

      // 13. Fetch Achievements
      int unlockedAchievements = 0;
      try {
        final achRes = await http.get(Uri.parse("${ApiService.baseUrl}/api/achievements/$rollNo"));
        if (achRes.statusCode == 200) {
          final data = jsonDecode(achRes.body);
          final List badges = data['badges'] ?? [];
          unlockedAchievements = badges.where((b) => b['unlocked'] == true).length;
        }
      } catch (e) {
        debugPrint("Failed to fetch achievements: $e");
      }

      if (mounted) {
        setState(() {
          _todaySessions = sessions;
          _dailyLogs = logs;
          _attendanceRecords = attData;
          _upcomingHolidays = upcomingHols;
          _upcomingExams = upcomingExs;
          _pendingAssignmentsCount = pendingAssignments;
          _totalNotesCount = notesList.length;
          _todayStudyGoalsCount = studyGoalsTotal;
          _todayStudyGoalsCompleted = studyGoalsCompleted;
          _studyGoalsCompletion = goalsCompletion;
          _upcomingExamsCount = upcomingExs.length;
          _totalNoticesCount = noticesList.length;
          _latestNoticeTitle = noticesList.isNotEmpty ? noticesList.first['title']?.toString() ?? "No Notice" : "No Notice";
          _pendingTasksCount = pendingTasks;
          _latestNotices = noticesList;
          _recentNotes = notesList;
          _upcomingEventsCount = upcomingEvents;
          _currentCgpa = currentCgpa;
          _unlockedAchievementsCount = unlockedAchievements;
          _loadingDateData = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading date data: $e");
      if (mounted) {
        setState(() => _loadingDateData = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final firstDate = _commencementDate;
    final now = DateTime.now();
    final lastLimit = DateTime(2026, 4, 18);
    final lastDate = now.isAfter(lastLimit) ? now : lastLimit;

    DateTime initial = _isCustomDateSelected ? _selectedDate : _commencementDate;
    if (initial.isBefore(firstDate)) {
      initial = firstDate;
    } else if (initial.isAfter(lastDate)) {
      initial = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      await _showSubjectAttendedClassesDialog(picked);
    }
  }

  Future<void> _showSubjectAttendedClassesDialog(DateTime pickedDate) async {
    final rollNo = await StorageService.getRollNo();
    if (rollNo.isEmpty) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, int> subjectScheduledCounts = {};
    try {
      final dateStr = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/calculate-subject-classes/$rollNo/$dateStr"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['subjects'] != null) {
          final subjectsMap = data['subjects'] as Map<String, dynamic>;
          subjectsMap.forEach((key, val) {
            subjectScheduledCounts[key] = (val as num).toInt();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching subject counts: $e");
    }

    if (mounted) {
      Navigator.pop(context);
    }

    bool coversAll = true;
    if (subjectScheduledCounts.isEmpty) {
      coversAll = true;
    } else {
      for (final subject in subjectScheduledCounts.keys) {
        final conducted = subjectScheduledCounts[subject] ?? 0;
        final record = _attendanceRecords.firstWhere(
          (r) => r['subject']?.toString().toLowerCase() == subject.toLowerCase(),
          orElse: () => null,
        );
        final dbTotal = record != null ? (record['total'] as num? ?? 0).toInt() : 0;
        if (dbTotal < conducted) {
          coversAll = false;
          break;
        }
      }
    }

    if (coversAll) {
      setState(() {
        _selectedDate = pickedDate;
        _isCustomDateSelected = true;
      });
      final dateStr = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      await StorageService.saveSelectedDate(dateStr);
      await _loadDateSpecificData();
      return;
    }

    final controllers = <String, TextEditingController>{};
    for (final subject in subjectScheduledCounts.keys) {
      final record = _attendanceRecords.firstWhere(
        (r) => r['subject']?.toString().toLowerCase() == subject.toLowerCase(),
        orElse: () => null,
      );
      final currentAttended = record != null ? (record['present'] as num? ?? 0).toInt() : 0;
      final maxConducted = subjectScheduledCounts[subject] ?? 0;
      final defaultVal = currentAttended > maxConducted ? maxConducted : currentAttended;
      controllers[subject] = TextEditingController(text: defaultVal.toString());
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Attendance History Update\n(till ${pickedDate.day}/${pickedDate.month}/${pickedDate.year})",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  "Specify how many classes you have attended for each subject out of total conducted classes:",
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ...subjectScheduledCounts.keys.map((subject) {
                  final maxVal = subjectScheduledCounts[subject] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: controllers[subject],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              hintText: "0",
                              suffixText: "/$maxVal",
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _selectedDate = pickedDate;
                  _isCustomDateSelected = true;
                });
                final dateStr = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                await StorageService.saveSelectedDate(dateStr);
                await _loadDateSpecificData();
              },
              child: const Text("Skip Update"),
            ),
            ElevatedButton(
              onPressed: () async {
                bool hasError = false;
                final updates = <String, Map<String, int>>{};

                controllers.forEach((subject, controller) {
                  final entered = int.tryParse(controller.text);
                  final maxVal = subjectScheduledCounts[subject] ?? 0;
                  if (entered == null || entered < 0 || entered > maxVal) {
                    hasError = true;
                  } else {
                    updates[subject] = {"present": entered, "total": maxVal};
                  }
                });

                if (hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter valid class counts (0 up to conducted classes)")),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);

                try {
                  for (final subject in updates.keys) {
                    final p = updates[subject]!['present']!;
                    final t = updates[subject]!['total']!;
                    await http.post(
                      Uri.parse("${ApiService.baseUrl}/attendance"),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "rollNo": rollNo,
                        "subject": subject,
                        "present": p,
                        "total": t,
                      }),
                    );
                  }
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Attendance history updated successfully")),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text("Error updating history: $e")),
                  );
                }

                if (mounted) {
                  setState(() {
                    _selectedDate = pickedDate;
                    _isCustomDateSelected = true;
                  });
                  final dateStr = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  await StorageService.saveSelectedDate(dateStr);
                  await _load();
                }
              },
              child: const Text("Save & Update"),
            ),
          ],
        );
      },
    );

    controllers.forEach((_, c) => c.dispose());
  }

  Future<void> _toggleAttendance(String subject, String period, String targetStatus) async {
    final rollNo = await StorageService.getRollNo();
    if (rollNo.isEmpty) return;

    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final key = "${subject}_$period";
    final currentStatus = _dailyLogs[key];

    setState(() {
      _loadingDateData = true;
    });

    try {
      if (currentStatus == targetStatus) {
        final res = await http.delete(
          Uri.parse("${ApiService.baseUrl}/api/daily-log/$rollNo/$dateStr/$subject/$period"),
        );
        if (res.statusCode == 200) {
          debugPrint("Cleared daily log for $key");
        }
      } else {
        final res = await http.post(
          Uri.parse("${ApiService.baseUrl}/api/daily-log"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "rollNo": rollNo,
            "date": dateStr,
            "subject": subject,
            "period": period,
            "status": targetStatus,
          }),
        );
        if (res.statusCode == 200) {
          debugPrint("Set daily log for $key to $targetStatus");
        }
      }
    } catch (e) {
      debugPrint("Error toggling daily log: $e");
    }

    await _load();
  }

  Widget _buildBunkBadge(String subject) {
    final isCommencement = _selectedDate.year == _commencementDate.year &&
        _selectedDate.month == _commencementDate.month &&
        _selectedDate.day == _commencementDate.day;

    int present = 0;
    int total = 0;
    if (!isCommencement) {
      final record = _attendanceRecords.firstWhere(
        (r) => r['subject']?.toString().toLowerCase() == subject.toLowerCase(),
        orElse: () => null,
      );
      present = record != null ? (record['present'] as num? ?? 0).toInt() : 15;
      total = record != null ? (record['total'] as num? ?? 0).toInt() : 20;
    }

    double currPct = total == 0 ? 0.0 : (present / total) * 100;
    double newPct = (present / (total + 1)) * 100;
    final isBunkable = newPct >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isBunkable ? const Color(0xFF20C997).withValues(alpha: 0.12) : const Color(0xFFFF6B6B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isBunkable ? const Color(0xFF20C997) : const Color(0xFFFF6B6B),
              width: 1,
            ),
          ),
          child: Text(
            isBunkable 
              ? "Today you can bunk this class! (→ ${newPct.toStringAsFixed(1)}%)" 
              : "Attend! Attendance will drop too low (→ ${newPct.toStringAsFixed(1)}%)",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isBunkable ? const Color(0xFF20C997) : const Color(0xFFFF6B6B),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Current: ${currPct.toStringAsFixed(1)}% ($present/$total classes)",
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final safe = attendance >= target;
    final displayName = name.trim().isEmpty
        ? 'Student'
        : name.trim().split(' ').first;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Text(
              'Hey, $displayName 👋',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              [branch, year].where((item) => item.isNotEmpty).join(' • '),
              style: TextStyle(color: Colors.white.withValues(alpha: .62)),
            ),
            const SizedBox(height: 18),
            _AttendanceHero(attendance: attendance, target: target, safe: safe),
            
            const SizedBox(height: 20),
            
            // Quick Action Buttons (Quick Stats)
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 2; // Default for mobile
                if (constraints.maxWidth >= 900) {
                  crossAxisCount = 4; // Desktop
                } else if (constraints.maxWidth >= 600) {
                  crossAxisCount = 2; // Tablet
                }
                
                final double cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
                const double cardHeight = 130; // Max height requirement
                final double aspectRatio = cardWidth / cardHeight;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                  children: [
                    _QuickActionCard(
                      title: "Assignments",
                      count: "$_pendingAssignmentsCount",
                      status: "Pending",
                      icon: Icons.assignment_rounded,
                      gradient: const [Color(0xFFE94057), Color(0xFF8A2387)],
                      onTap: () => Navigator.pushNamed(context, "/assignments").then((_) => _load()),
                    ),
                    _QuickActionCard(
                      title: "Notes Hub",
                      count: "$_totalNotesCount",
                      status: "Uploaded",
                      icon: Icons.menu_book_rounded,
                      gradient: const [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                      onTap: () => Navigator.pushNamed(context, "/notes-manager").then((_) => _load()),
                    ),
                    _QuickActionCard(
                      title: "Study Planner",
                      count: "$_todayStudyGoalsCompleted/$_todayStudyGoalsCount",
                      status: "Goals Met",
                      icon: Icons.track_changes_rounded,
                      gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                      onTap: () => Navigator.pushNamed(context, "/study-planner").then((_) => _load()),
                    ),
                    _QuickActionCard(
                      title: "Exams",
                      count: "$_upcomingExamsCount",
                      status: "Scheduled",
                      icon: Icons.school_rounded,
                      gradient: const [Color(0xFFff9966), Color(0xFFff5e62)],
                      onTap: () => Navigator.pushNamed(context, "/exams").then((_) => _load()),
                    ),
                    _QuickActionCard(
                      title: "Tasks",
                      count: "$_pendingTasksCount",
                      status: "Pending",
                      icon: Icons.check_circle_rounded,
                      gradient: const [Color(0xFF00c6ff), Color(0xFF0072ff)],
                      onTap: () => Navigator.pushNamed(context, "/task-manager").then((_) => _load()),
                    ),
                    _QuickActionCard(
                      title: "Events",
                      count: "$_upcomingEventsCount",
                      status: "Upcoming",
                      icon: Icons.event_rounded,
                      gradient: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                      onTap: () => Navigator.pushNamed(context, "/event-manager").then((_) => _load()),
                    ),
                    _QuickActionCard(
                      title: "CGPA",
                      count: _currentCgpa.toStringAsFixed(2),
                      status: "Current",
                      icon: Icons.insights_rounded,
                      gradient: const [Color(0xFFF3904F), Color(0xFF3B4371)],
                      onTap: () => Navigator.pushNamed(context, "/cgpa-tracker").then((_) => _load()),
                    ),
                    _QuickActionCard(
                      title: "Achievements",
                      count: "$_unlockedAchievementsCount",
                      status: "Badges Unlocked",
                      icon: Icons.emoji_events_rounded,
                      gradient: const [Color(0xFFf12711), Color(0xFFf5af19)],
                      onTap: () => Navigator.pushNamed(context, "/achievements").then((_) => _load()),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            
            // 1. Date Picker Row
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today_rounded, color: Color(0xFF9B91FF)),
                title: const Text('Schedule Date Selector', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("View checklist for: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text("Change Date"),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 2. Today's checklist & bunk predictor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Schedule Checklist',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (_loadingDateData)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_todaySessions.isEmpty)
              Card(
                color: const Color(0xFF0F264C),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "No classes scheduled for today (${_selectedDate.weekday == 7 ? 'Sunday' : 'Holiday / Off-day'})",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
                    ),
                  ),
                ),
              )
            else
              ..._todaySessions.map((session) {
                final subject = session['subject']?.toString() ?? 'Class';
                final period = session['period']?.toString() ?? '1';
                final startTime = session['startTime']?.toString() ?? '';
                final endTime = session['endTime']?.toString() ?? '';
                final room = session['room']?.toString() ?? 'N/A';
                
                final key = "${subject}_$period";
                final status = _dailyLogs[key]; // "present" or "absent" or null
                
                final isCommencement = _selectedDate.year == _commencementDate.year &&
                    _selectedDate.month == _commencementDate.month &&
                    _selectedDate.day == _commencementDate.day;

                int present = 0;
                int total = 0;
                if (!isCommencement) {
                  final record = _attendanceRecords.firstWhere(
                    (r) => r['subject']?.toString().toLowerCase() == subject.toLowerCase(),
                    orElse: () => null,
                  );
                  present = record != null ? (record['present'] as num? ?? 0).toInt() : 15;
                  total = record != null ? (record['total'] as num? ?? 0).toInt() : 20;
                }
                
                double currPct = total == 0 ? 0.0 : (present / total) * 100;
                double newPct = (present / (total + 1)) * 100;
                final isBunkable = newPct >= target;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Left Period indicator
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Period $period",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$startTime - $endTime",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Middle Subject Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Room: $room",
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              _buildBunkBadge(subject),
                            ],
                          ),
                        ),
                        // Right Checklist Action Buttons
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: isBunkable 
                                    ? const Color(0xFF20C997).withValues(alpha: 0.12) 
                                    : const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isBunkable ? const Color(0xFF20C997) : const Color(0xFFFF6B6B),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "${currPct.toStringAsFixed(0)}%",
                                style: TextStyle(
                                  color: isBunkable ? const Color(0xFF20C997) : const Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                Icons.check_circle_rounded,
                                color: status == "present" ? const Color(0xFF20C997) : Colors.white.withValues(alpha: 0.2),
                                size: 28,
                              ),
                              onPressed: () => _toggleAttendance(subject, period, "present"),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.cancel_rounded,
                                color: status == "absent" ? const Color(0xFFFF6B6B) : Colors.white.withValues(alpha: 0.2),
                                size: 28,
                              ),
                              onPressed: () => _toggleAttendance(subject, period, "absent"),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 22),
            
            // 3. Upcoming Exams Alerts
            if (_upcomingExams.isNotEmpty) ...[
              Text(
                'Upcoming Exams',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFF1E293B),
                child: Column(
                  children: _upcomingExams.take(4).map((e) {
                    final date = e['date']?.toString() ?? '';
                    final subject = e['subject']?.toString() ?? 'Exam';
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.edit_calendar_rounded, color: Color(0xFFFF6B8A)),
                      title: Text(subject, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(date),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 4. Upcoming Holidays
            if (_upcomingHolidays.isNotEmpty) ...[
              Text(
                'Upcoming Holidays',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFF1E293B),
                child: Column(
                  children: _upcomingHolidays.take(4).map((h) {
                    final date = h['date']?.toString() ?? '';
                    final name = h['name']?.toString() ?? 'Holiday';
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.celebration_rounded, color: Color(0xFFFFB547)),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(date),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              'Smart tools',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: SizedBox(
                    height: 128,
                    child: _FeatureCard(
                      title: 'Bunk predictor',
                      subtitle: 'Can I skip today?',
                      icon: Icons.flight_takeoff_rounded,
                      color: Color(0xFF7C6CFF),
                      route: '/bunk',
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 128,
                    child: _FeatureCard(
                      title: 'Recovery plan',
                      subtitle: 'Reach your target',
                      icon: Icons.trending_up_rounded,
                      color: Color(0xFF20C997),
                      route: '/recovery',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Your semester',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _SemesterTile(
              icon: Icons.how_to_reg_rounded,
              title: 'Mark attendance',
              subtitle: 'Update classes subject-wise',
              route: '/attendance',
            ),
            const SizedBox(height: 10),
            _SemesterTile(
              icon: Icons.school_outlined,
              title: 'Exam alerts',
              subtitle: 'See upcoming exams and deadlines',
              route: '/exams',
            ),
            const SizedBox(height: 10),
            _SemesterTile(
              icon: Icons.calendar_month_outlined,
              title: calendarFile.isEmpty
                  ? 'Upload academic calendar'
                  : 'Academic calendar ready',
              subtitle: calendarFile.isEmpty
                  ? 'Add holidays and exam dates'
                  : calendarFile,
              route: '/calendar-upload',
            ),
            const SizedBox(height: 10),
            _SemesterTile(
              icon: Icons.grid_view_rounded,
              title: timetableFile.isEmpty
                  ? 'Upload timetable'
                  : 'Timetable ready',
              subtitle: timetableFile.isEmpty
                  ? 'Add your weekly classes'
                  : timetableFile,
              route: '/timetable-upload',
            ),
            const SizedBox(height: 22),

            // Latest Notices Cards
            if (_latestNotices.isNotEmpty) ...[
              Text(
                'Latest Notices',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ..._latestNotices.take(2).map((n) {
                final title = n['title']?.toString() ?? '';
                final cat = n['category']?.toString() ?? 'Notice';
                final isPinned = n['isPinned'] == true;
                return Card(
                  color: isPinned ? const Color(0xFF1E3252) : const Color(0xFF13233D),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(isPinned ? Icons.push_pin : Icons.campaign_rounded, color: isPinned ? Colors.orange : const Color(0xFF00BFA5)),
                    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(cat, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Recent Notes Cards
            if (_recentNotes.isNotEmpty) ...[
              Text(
                'Recent Notes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ..._recentNotes.take(2).map((n) {
                final title = n['title']?.toString() ?? '';
                final subject = n['subject']?.toString() ?? 'Notes';
                return Card(
                  color: const Color(0xFF13233D),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.description_rounded, color: Colors.purpleAccent),
                    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(subject, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF13233D),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _AttendanceHero extends StatelessWidget {
  const _AttendanceHero({
    required this.attendance,
    required this.target,
    required this.safe,
  });
  final double attendance;
  final double target;
  final bool safe;

  @override
  Widget build(BuildContext context) {
    final progress = (attendance / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6256E8), Color(0xFF8C65F7)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 9,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
                Text(
                  '${attendance.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall attendance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                Text(
                  safe
                      ? 'You are above your ${target.toStringAsFixed(0)}% target.'
                      : '${(target - attendance).toStringAsFixed(1)}% below your target. Start recovery now.',
                ),
                const SizedBox(height: 8),
                Text(
                  safe ? 'On track ✓' : 'Needs attention',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: safe
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFFD5A5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: .58),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SemesterTile extends StatelessWidget {
  const _SemesterTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: Icon(icon, color: const Color(0xFF9B91FF)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final String title;
  final String count;
  final String status;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.count,
    required this.status,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered ? (Matrix4.identity()..translate(0, -3, 0)) : Matrix4.identity(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [BoxShadow(color: widget.gradient.last.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              splashColor: Colors.white24,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Icon + Arrow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 22),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 14),
                      ],
                    ),
                    // Middle: Title
                    Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Bottom Row: Count + Status text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.count,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        Flexible(
                          child: Text(
                            widget.status,
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

