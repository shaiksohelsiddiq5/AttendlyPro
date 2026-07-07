import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class CgpaTrackerScreen extends StatefulWidget {
  const CgpaTrackerScreen({super.key});

  @override
  State<CgpaTrackerScreen> createState() => _CgpaTrackerScreenState();
}

class _CgpaTrackerScreenState extends State<CgpaTrackerScreen> {
  List _semesters = [];
  double _targetCgpa = 8.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCgpaData();
  }

  Future<void> _fetchCgpaData() async {
    setState(() => _isLoading = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/cgpa/$rollNo"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _semesters = data['semesters'] ?? [];
          _targetCgpa = (data['targetCgpa'] ?? 8.0).toDouble();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch CGPA: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCgpaData() async {
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/cgpa"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "rollNo": rollNo,
          "semesters": _semesters,
          "targetCgpa": _targetCgpa,
        }),
      );
      if (res.statusCode == 200) {
        _fetchCgpaData();
      }
    } catch (e) {
      debugPrint("Failed to save CGPA: $e");
    }
  }

  double _calculateCurrentCgpa() {
    if (_semesters.isEmpty) return 0.0;
    double totalWeightedGpa = 0.0;
    int totalCredits = 0;
    for (final sem in _semesters) {
      final gpa = ((sem['gpa'] ?? 0.0) as num).toDouble();
      final credits = ((sem['credits'] ?? 0) as num).toInt();
      totalWeightedGpa += gpa * credits;
      totalCredits += credits;
    }
    return totalCredits == 0 ? 0.0 : totalWeightedGpa / totalCredits;
  }

  int _calculateTotalCredits() {
    return _semesters.fold<int>(0, (sum, sem) => sum + ((sem['credits'] ?? 0) as num).toInt());
  }

  void _showAddSemDialog() {
    final semController = TextEditingController();
    final gpaController = TextEditingController();
    final creditsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F264C),
          title: const Text("Add Semester GPA", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: semController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Semester Number (e.g. 1, 2)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gpaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "GPA Secured"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: creditsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Semester Credits"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final semNum = int.tryParse(semController.text);
                final gpaVal = double.tryParse(gpaController.text);
                final credVal = int.tryParse(creditsController.text);

                if (semNum == null || gpaVal == null || credVal == null) return;
                setState(() {
                  _semesters.add({
                    "semester": semNum,
                    "gpa": gpaVal,
                    "targetGpa": 0.0,
                    "credits": credVal,
                  });
                  _semesters.sort((a, b) => (a['semester'] ?? 0).compareTo(b['semester'] ?? 0));
                });
                _saveCgpaData();
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _showSetTargetDialog() {
    final targetController = TextEditingController(text: _targetCgpa.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F264C),
          title: const Text("Set Target CGPA", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: "Target CGPA"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(targetController.text);
                if (val == null) return;
                setState(() {
                  _targetCgpa = val;
                });
                _saveCgpaData();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPredictionCard(double currentCgpa) {
    final completedSems = _semesters.length;
    const totalSems = 8;
    final remainingSems = totalSems - completedSems;

    if (remainingSems <= 0) {
      return const Card(
        color: Color(0xFF13233D),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("All 8 semesters completed. Great job!", style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final currentWeighted = currentCgpa * completedSems;
    final targetWeighted = _targetCgpa * totalSems;
    final neededSum = targetWeighted - currentWeighted;
    final averageNeeded = neededSum / remainingSems;

    bool isAchievable = averageNeeded <= 10.0 && averageNeeded >= 0.0;

    return Card(
      color: const Color(0xFF13233D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("CGPA Prediction Assistant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              "Semesters Remaining: $remainingSems",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            isAchievable
                ? Text(
                    "To reach your target CGPA of ${_targetCgpa.toStringAsFixed(2)}, you need to secure an average of ${averageNeeded.toStringAsFixed(2)} GPA in the next $remainingSems semesters.",
                    style: const TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.w500),
                  )
                : Text(
                    "Your target CGPA of ${_targetCgpa.toStringAsFixed(2)} requires an average of ${averageNeeded.toStringAsFixed(2)} GPA, which might be mathematically impossible in $remainingSems semesters.",
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCgpa = _calculateCurrentCgpa();
    final totalCredits = _calculateTotalCredits();

    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text("CGPA Tracker"),
        backgroundColor: Colors.black54,
        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes, color: Colors.amber),
            tooltip: "Set Target",
            onPressed: _showSetTargetDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Score Cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: const Color(0xFF13233D),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text("Current CGPA", style: TextStyle(color: Colors.white60)),
                              const SizedBox(height: 8),
                              Text(currentCgpa.toStringAsFixed(2), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00BFA5))),
                              const SizedBox(height: 4),
                              Text("$totalCredits Credits", style: const TextStyle(color: Colors.white30, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        color: const Color(0xFF13233D),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text("Target CGPA", style: TextStyle(color: Colors.white60)),
                              const SizedBox(height: 8),
                              Text(_targetCgpa.toStringAsFixed(2), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
                              const SizedBox(height: 4),
                              const Text("Set Goal", style: TextStyle(color: Colors.white30, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPredictionCard(currentCgpa),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Semester Results", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF00BFA5)),
                      onPressed: _showAddSemDialog,
                    )
                  ],
                ),
                const SizedBox(height: 10),
                _semesters.isEmpty
                    ? const Card(
                        color: Color(0xFF13233D),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text("No semester details logged yet.", style: TextStyle(color: Colors.white54))),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _semesters.length,
                        itemBuilder: (context, index) {
                          final sem = _semesters[index];
                          final semNum = sem['semester'] ?? 0;
                          final gpa = (sem['gpa'] ?? 0.0).toDouble();
                          final creds = sem['credits'] ?? 0;

                          return Card(
                            color: const Color(0xFF13233D),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF00BFA5).withValues(alpha: 0.12),
                                child: Text("S$semNum", style: const TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold)),
                              ),
                              title: Text("GPA: ${gpa.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text("Credits: $creds", style: const TextStyle(color: Colors.white70)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _semesters.removeAt(index);
                                  });
                                  _saveCgpaData();
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
