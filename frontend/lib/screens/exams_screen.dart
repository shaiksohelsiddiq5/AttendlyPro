import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  List _exams = [];
  bool _isLoading = true;
  Timer? _countdownTimer;
  String _countdownText = "No exams scheduled";
  Map? _nextExam;

  @override
  void initState() {
    super.initState();
    _fetchExams();
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateCountdown();
    });
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoading = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/exams/$rollNo"));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        setState(() {
          _exams = list;
          _isLoading = false;
        });
        _calculateCountdown();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch exams: $e");
      setState(() => _isLoading = false);
    }
  }

  void _calculateCountdown() {
    if (_exams.isEmpty) {
      if (mounted) setState(() => _countdownText = "No upcoming exams");
      return;
    }

    final now = DateTime.now();
    // Find next upcoming exam date in future
    List upcoming = _exams.where((e) {
      final eDate = DateTime.tryParse(e['date']?.toString() ?? '');
      if (eDate == null) return false;
      return eDate.isAfter(now);
    }).toList();

    if (upcoming.isEmpty) {
      if (mounted) setState(() => _countdownText = "All exams completed!");
      return;
    }

    // Sort by date ascending
    upcoming.sort((a, b) => (a['date']?.toString() ?? '').compareTo(b['date']?.toString() ?? ''));
    final next = upcoming.first;
    final nextDate = DateTime.parse(next['date']);
    
    final diff = nextDate.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (mounted) {
      setState(() {
        _nextExam = next;
        _countdownText = "${days}d ${hours}h ${minutes}m ${seconds}s";
      });
    }
  }

  Future<void> _addExam(String subject, String examName, DateTime date, String time, String hall, String notes) async {
    try {
      final rollNo = await StorageService.getRollNo();
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/exams"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "rollNo": rollNo,
          "subject": subject,
          "examName": examName,
          "date": date.toIso8601String(),
          "time": time,
          "hall": hall,
          "notes": notes,
        }),
      );
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exam added successfully")));
        _fetchExams();
      }
    } catch (e) {
      debugPrint("Failed to add exam: $e");
    }
  }

  Future<void> _editExam(String id, String subject, String examName, DateTime date, String time, String hall, String notes) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/exams/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "subject": subject,
          "examName": examName,
          "date": date.toIso8601String(),
          "time": time,
          "hall": hall,
          "notes": notes,
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exam updated successfully")));
        _fetchExams();
      }
    } catch (e) {
      debugPrint("Failed to edit exam: $e");
    }
  }

  Future<void> _deleteExam(String id) async {
    try {
      final res = await http.delete(Uri.parse("${ApiService.baseUrl}/api/exams/$id"));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exam deleted")));
        _fetchExams();
      }
    } catch (e) {
      debugPrint("Failed to delete exam: $e");
    }
  }

  void _showAddDialog() {
    final subController = TextEditingController();
    final nameController = TextEditingController();
    final timeController = TextEditingController();
    final hallController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Schedule Exam", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: subController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Subject"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Exam Name (e.g. Midterm, Sem)"),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2027),
                            );
                            if (picked != null) {
                              setDlgState(() => selectedDate = picked);
                            }
                          },
                          child: const Text("Select Date"),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Time (e.g. 10:00 AM)"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hallController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Exam Hall"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Additional Notes"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final sub = subController.text.trim();
                    final name = nameController.text.trim();
                    if (sub.isEmpty || name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subject and Name are required")));
                      return;
                    }
                    _addExam(sub, name, selectedDate, timeController.text.trim(), hallController.text.trim(), notesController.text.trim());
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

  void _showEditDialog(Map exam) {
    final id = exam['_id']?.toString() ?? '';
    final subController = TextEditingController(text: exam['subject']?.toString() ?? '');
    final nameController = TextEditingController(text: exam['examName']?.toString() ?? '');
    final timeController = TextEditingController(text: exam['time']?.toString() ?? '');
    final hallController = TextEditingController(text: exam['hall']?.toString() ?? '');
    final notesController = TextEditingController(text: exam['notes']?.toString() ?? '');
    DateTime selectedDate = DateTime.tryParse(exam['date']?.toString() ?? '') ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Edit Exam Details", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: subController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Subject"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Exam Name"),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime(2027),
                            );
                            if (picked != null) {
                              setDlgState(() => selectedDate = picked);
                            }
                          },
                          child: const Text("Select Date"),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Time"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hallController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Exam Hall"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Additional Notes"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final sub = subController.text.trim();
                    final name = nameController.text.trim();
                    if (sub.isEmpty || name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subject and Name are required")));
                      return;
                    }
                    _editExam(id, sub, name, selectedDate, timeController.text.trim(), hallController.text.trim(), notesController.text.trim());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text("Exams Scheduler"),
        backgroundColor: Colors.black54,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Next Exam countdown banner card
            if (_nextExam != null) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFff9966), Color(0xFFff5e62)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text("Next Exam Countdown", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        _countdownText,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${_nextExam!['subject']} • ${_nextExam!['examName']}",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _exams.isEmpty
                      ? const Center(child: Text("No exams scheduled", style: TextStyle(color: Colors.white54, fontSize: 16)))
                      : ListView.builder(
                          itemCount: _exams.length,
                          itemBuilder: (context, index) {
                            final exam = _exams[index];
                            final sub = exam['subject']?.toString() ?? '';
                            final name = exam['examName']?.toString() ?? '';
                            final time = exam['time']?.toString() ?? '';
                            final hall = exam['hall']?.toString() ?? '';
                            final notes = exam['notes']?.toString() ?? '';
                            
                            final date = DateTime.tryParse(exam['date']?.toString() ?? '');
                            final formattedDate = date != null ? "${date.day}/${date.month}/${date.year}" : "";

                            return Card(
                              color: const Color(0xFF13233D),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => _showEditDialog(exam),
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF1E3252),
                                  child: Icon(Icons.school, color: Color(0xFFff9966)),
                                ),
                                title: Text("$sub • $name", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text("Date: $formattedDate @ $time", style: const TextStyle(color: Colors.white70)),
                                    Text("Hall: $hall", style: const TextStyle(color: Colors.white70)),
                                    if (notes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text("Notes: $notes", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ]
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deleteExam(exam['_id']),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFff9966),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}