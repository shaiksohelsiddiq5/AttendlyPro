import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List _studyPlans = [];
  bool _isLoading = true;
  int _studyStreak = 0;
  double _totalHours = 0.0;

  // Daily State
  DateTime _selectedDate = DateTime.now();
  List _dailyGoals = [];
  double _dailyHours = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchStudyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudyData() async {
    setState(() => _isLoading = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/study-plans/$rollNo"));
      if (res.statusCode == 200) {
        final List plans = jsonDecode(res.body);
        _studyPlans = plans;

        // Calculate dynamic study streak
        final uniqueDates = plans.map((p) => p['date']?.toString() ?? "").toSet().where((d) => d.isNotEmpty).toList();
        uniqueDates.sort();
        int currentStreak = 0;
        int maxStreak = 0;
        if (uniqueDates.length > 0) {
          currentStreak = 1;
          maxStreak = 1;
          for (int i = 1; i < uniqueDates.length; i++) {
            final prev = DateTime.tryParse(uniqueDates[i - 1]);
            final curr = DateTime.tryParse(uniqueDates[i]);
            if (prev != null && curr != null) {
              final diff = curr.difference(prev).inDays;
              if (diff == 1) {
                currentStreak++;
                if (currentStreak > maxStreak) {
                  maxStreak = currentStreak;
                }
              } else if (diff > 1) {
                currentStreak = 1;
              }
            }
          }
        }
        _studyStreak = maxStreak;

        // Calculate total estimated hours (e.g. 1.5 hrs per completed goal)
        final completedCount = plans.where((p) => p['completed'] == true).length;
        _totalHours = completedCount * 1.5;

        // Get daily goals for selectedDate
        final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
        _dailyGoals = plans.where((p) => p['date'] == dateStr).toList();
        
        final completedToday = _dailyGoals.where((g) => g['completed'] == true).length;
        _dailyHours = completedToday * 1.5;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Failed to fetch study data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addStudyGoal(String goalText, String priority) async {
    try {
      final rollNo = await StorageService.getRollNo();
      final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/study-plans"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "rollNo": rollNo,
          "goal": goalText,
          "date": dateStr,
          "completed": false,
          "priority": priority,
        }),
      );
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Goal added successfully")));
        _fetchStudyData();
      }
    } catch (e) {
      debugPrint("Failed to add goal: $e");
    }
  }

  Future<void> _editStudyGoal(String id, String goalText, String priority) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/study-plans/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "goal": goalText,
          "priority": priority,
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Goal updated successfully")));
        _fetchStudyData();
      }
    } catch (e) {
      debugPrint("Failed to edit goal: $e");
    }
  }

  Future<void> _toggleGoalStatus(String id, bool completed) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/study-plans/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "completed": completed,
        }),
      );
      if (res.statusCode == 200) {
        _fetchStudyData();
      }
    } catch (e) {
      debugPrint("Failed to toggle goal status: $e");
    }
  }

  Future<void> _deleteStudyGoal(String id) async {
    try {
      final res = await http.delete(Uri.parse("${ApiService.baseUrl}/api/study-plans/$id"));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Goal deleted")));
        _fetchStudyData();
      }
    } catch (e) {
      debugPrint("Failed to delete goal: $e");
    }
  }

  void _showAddGoalDialog() {
    final goalController = TextEditingController();
    String selectedPriority = "Medium";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Add Daily Goal", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: goalController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: "Enter study goal, e.g. Revise Java..."),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF0F264C),
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: "Priority"),
                    items: ["High", "Medium", "Low"].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => setDialogState(() => selectedPriority = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final text = goalController.text.trim();
                    if (text.isEmpty) return;
                    _addStudyGoal(text, selectedPriority);
                    Navigator.pop(context);
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditGoalDialog(Map goalObj) {
    final id = goalObj['_id']?.toString() ?? '';
    final goalController = TextEditingController(text: goalObj['goal']?.toString() ?? '');
    String selectedPriority = goalObj['priority']?.toString() ?? "Medium";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Edit Daily Goal", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: goalController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Goal Description"),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF0F264C),
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: "Priority"),
                    items: ["High", "Medium", "Low"].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => setDialogState(() => selectedPriority = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final text = goalController.text.trim();
                    if (text.isEmpty) return;
                    _editStudyGoal(id, text, selectedPriority);
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDailyTab() {
    final completedCount = _dailyGoals.where((g) => g['completed'] == true).length;
    final totalCount = _dailyGoals.length;
    final completionPct = totalCount == 0 ? 0.0 : (completedCount / totalCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                  _fetchStudyData();
                },
              ),
              Text(
                "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                  _fetchStudyData();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF13233D),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Daily Goal Progress", style: TextStyle(color: Colors.white70)),
                      Text("${(completionPct * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: completionPct,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00BFA5)),
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                          const SizedBox(height: 4),
                          const Text("Study Streak", style: TextStyle(color: Colors.white60, fontSize: 12)),
                          Text("$_studyStreak Days", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.schedule, color: Color(0xFF9B91FF), size: 28),
                          const SizedBox(height: 4),
                          const Text("Est. Time", style: TextStyle(color: Colors.white60, fontSize: 12)),
                          Text("${_dailyHours.toStringAsFixed(1)} hrs", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Goals List", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF00BFA5)),
                onPressed: _showAddGoalDialog,
              )
            ],
          ),
          const SizedBox(height: 10),
          _dailyGoals.isEmpty
              ? const Card(
                  color: Color(0xFF13233D),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text("No goals added for today.", style: TextStyle(color: Colors.white54))),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _dailyGoals.length,
                  itemBuilder: (context, index) {
                    final goalObj = _dailyGoals[index];
                    final goalText = goalObj['goal']?.toString() ?? '';
                    final prio = goalObj['priority']?.toString() ?? 'Medium';
                    final isDone = goalObj['completed'] == true;

                    Color pColor = Colors.green;
                    if (prio == 'High') pColor = Colors.redAccent;
                    if (prio == 'Medium') pColor = Colors.amber;

                    return Card(
                      color: const Color(0xFF13233D),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _showEditGoalDialog(goalObj),
                        leading: IconButton(
                          icon: Icon(isDone ? Icons.check_box : Icons.check_box_outline_blank, color: isDone ? const Color(0xFF00BFA5) : Colors.white54),
                          onPressed: () {
                            _toggleGoalStatus(goalObj['_id'], !isDone);
                          },
                        ),
                        title: Text(
                          goalText,
                          style: TextStyle(
                            color: Colors.white,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Priority: $prio",
                            style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteStudyGoal(goalObj['_id']),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF13233D),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Weekly Highlights", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Est. Weekly Study Time:", style: TextStyle(color: Colors.white70)),
                    Text("${_totalHours.toStringAsFixed(1)} Hours", style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Daily Consistency Checklist:", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                ...List.generate(7, (idx) {
                  final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
                  final dayName = days[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 80, child: Text(dayName, style: const TextStyle(color: Colors.white60))),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (idx % 2 == 0) ? 0.8 : 0.4,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(idx % 2 == 0 ? const Color(0xFF00BFA5) : const Color(0xFF9B91FF)),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text((idx % 2 == 0) ? "3.0h" : "1.5h", style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF13233D),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Monthly Progress Snapshot", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text("Consistency Grid", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    final hasStudied = index % 3 != 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: hasStudied ? const Color(0xFF00BFA5).withValues(alpha: 0.6) : Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(color: hasStudied ? Colors.white : Colors.white24, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Material(
                  color: Colors.black54,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF00BFA5),
                    labelColor: const Color(0xFF00BFA5),
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(text: "Daily Planner"),
                      Tab(text: "Weekly"),
                      Tab(text: "Monthly"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDailyTab(),
                      _buildWeeklyTab(),
                      _buildMonthlyTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
