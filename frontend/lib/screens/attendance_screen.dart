import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/attendance_service.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List attendanceData = [];
  String rollNo = "";

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    rollNo = await StorageService.getRollNo();
    final data = await AttendanceService.getAttendance(rollNo);

    int totalPresent = 0;
    int totalConducted = 0;
    for (final item in data) {
      totalPresent += (item["present"] as num? ?? 0).toInt();
      totalConducted += (item["total"] as num? ?? 0).toInt();
    }

    if (totalConducted > 0) {
      final percent = (totalPresent * 100 / totalConducted).toStringAsFixed(1);
      await StorageService.saveSetup(
        await StorageService.getBranch(),
        await StorageService.getYear(),
        percent,
        await StorageService.getTarget(),
      );
      await StorageService.saveAttendanceCounts(totalPresent, totalConducted);

      try {
        await http.post(
          Uri.parse("${ApiService.baseUrl}/api/setup"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "rollNo": rollNo,
            "branch": await StorageService.getBranch(),
            "year": await StorageService.getYear(),
            "attendance": percent,
            "target": await StorageService.getTarget(),
            "attendedClasses": totalPresent,
            "totalClasses": totalConducted,
          }),
        );
      } catch (_) {}
    }

    setState(() {
      attendanceData = data;
    });
  }

  Future<void> updateAttendance(String subject, int present, int total) async {
    try {
      await AttendanceService.addAttendance(rollNo, subject, present, total);
      await loadAttendance();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    }
  }

  Future<void> deleteSubject(String subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Subject"),
        content: Text("Are you sure you want to delete '$subject'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/attendance/$rollNo/$subject"),
      );
      if (response.statusCode == 200) {
        await loadAttendance();
      } else {
        throw Exception("Failed to delete subject");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete: $e")),
      );
    }
  }

  Future<void> addSubject() async {
    final subjectController = TextEditingController();
    final presentController = TextEditingController();
    final totalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Subject"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: "Subject Name"),
              ),
              TextField(
                controller: presentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Present Classes"),
              ),
              TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Total Classes"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final present = int.tryParse(presentController.text) ?? 0;
                final total = int.tryParse(totalController.text) ?? 0;
                if (subjectController.text.trim().isEmpty || total < present) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please check inputs")),
                  );
                  return;
                }

                await AttendanceService.addAttendance(
                  rollNo,
                  subjectController.text.trim(),
                  present,
                  total,
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                loadAttendance();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081B3A),
      floatingActionButton: FloatingActionButton(
        onPressed: addSubject,
        child: const Icon(Icons.add),
      ),
      body: attendanceData.isEmpty
          ? const Center(
              child: Text(
                "No Subjects Added",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            )
          : ListView.builder(
              itemCount: attendanceData.length,
              itemBuilder: (context, index) {
                final item = attendanceData[index];
                final percent = item["total"] == 0
                    ? 0.0
                    : (item["present"] / item["total"]) * 100.0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item["subject"],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  "${percent.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: percent >= 75.0 ? const Color(0xFF20C997) : const Color(0xFFFF6B6B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => deleteSubject(item["subject"]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text("Present: ", style: TextStyle(fontSize: 15)),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: item["present"] > 0
                                      ? () => updateAttendance(item["subject"], item["present"] - 1, item["total"])
                                      : null,
                                ),
                                Text(
                                  "${item["present"]}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => updateAttendance(
                                    item["subject"],
                                    item["present"] + 1,
                                    item["total"] < item["present"] + 1 ? item["present"] + 1 : item["total"],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text("Total: ", style: TextStyle(fontSize: 15)),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: item["total"] > item["present"]
                                      ? () => updateAttendance(item["subject"], item["present"], item["total"] - 1)
                                      : null,
                                ),
                                Text(
                                  "${item["total"]}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => updateAttendance(item["subject"], item["present"], item["total"] + 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
