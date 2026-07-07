import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class ReminderManagerScreen extends StatefulWidget {
  const ReminderManagerScreen({super.key});

  @override
  State<ReminderManagerScreen> createState() => _ReminderManagerScreenState();
}

class _ReminderManagerScreenState extends State<ReminderManagerScreen> {
  List _reminders = [];
  bool _isLoading = true;

  final List<String> _categories = [
    "Assignment",
    "Exam",
    "Study Time",
    "Attendance",
    "Event",
    "Project",
    "Deadline"
  ];

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    setState(() => _isLoading = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/reminders/$rollNo"));
      if (res.statusCode == 200) {
        setState(() {
          _reminders = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch reminders: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addReminder(String title, String category, DateTime dateTime) async {
    try {
      final rollNo = await StorageService.getRollNo();
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/reminders"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "rollNo": rollNo,
          "title": title,
          "category": category,
          "dateTime": dateTime.toIso8601String(),
        }),
      );
      if (res.statusCode == 201) {
        _fetchReminders();
      }
    } catch (e) {
      debugPrint("Failed to add reminder: $e");
    }
  }

  Future<void> _toggleReminderComplete(String id, bool completed) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/reminders/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"completed": completed}),
      );
      if (res.statusCode == 200) {
        _fetchReminders();
      }
    } catch (e) {
      debugPrint("Failed to update reminder: $e");
    }
  }

  Future<void> _deleteReminder(String id) async {
    try {
      final res = await http.delete(Uri.parse("${ApiService.baseUrl}/api/reminders/$id"));
      if (res.statusCode == 200) {
        _fetchReminders();
      }
    } catch (e) {
      debugPrint("Failed to delete reminder: $e");
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    String selectedCategory = _categories[0];
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 2));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("New Smart Reminder", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Reminder Title"),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF0F264C),
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: "Category"),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => setDlgState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Date/Time: ${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2027),
                          );
                          if (date == null) return;
                          if (!mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (time == null) return;
                          setDlgState(() {
                            selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        },
                        child: const Text("Set Time"),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    _addReminder(title, selectedCategory, selectedDateTime);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text("Smart Reminders"),
        backgroundColor: Colors.black54,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reminders.isEmpty
                ? const Center(child: Text("No active reminders set", style: TextStyle(color: Colors.white54, fontSize: 16)))
                : ListView.builder(
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      final title = reminder['title']?.toString() ?? '';
                      final cat = reminder['category']?.toString() ?? '';
                      final done = reminder['completed'] == true;
                      final date = DateTime.tryParse(reminder['dateTime']?.toString() ?? '');
                      final formattedDate = date != null ? "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}" : "";

                      IconData icon = Icons.notifications;
                      Color iconColor = const Color(0xFF00BFA5);
                      if (cat == 'Exam') {
                        icon = Icons.timer_rounded;
                        iconColor = Colors.redAccent;
                      } else if (cat == 'Assignment') {
                        icon = Icons.assignment_rounded;
                        iconColor = Colors.orange;
                      } else if (cat == 'Study Time') {
                        icon = Icons.book_rounded;
                        iconColor = Colors.purpleAccent;
                      }

                      return Card(
                        color: const Color(0xFF13233D),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(icon, color: iconColor),
                          title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: done ? TextDecoration.lineThrough : null)),
                          subtitle: Text("$cat • $formattedDate", style: const TextStyle(color: Colors.white70)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? const Color(0xFF00BFA5) : Colors.white54),
                                onPressed: () => _toggleReminderComplete(reminder['_id'], !done),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteReminder(reminder['_id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.add_alarm, color: Colors.white),
      ),
    );
  }
}
