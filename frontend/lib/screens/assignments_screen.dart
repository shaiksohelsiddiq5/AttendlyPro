import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List _assignments = [];
  List<String> _subjects = ["Java", "DBMS", "React", "Node.js", "Computer Networks", "Maths"];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    _fetchAssignments();
  }

  Future<void> _fetchSubjects() async {
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/attendance/$rollNo"));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          setState(() {
            _subjects = data.map((e) => e['subject']?.toString() ?? "").toSet().toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch subjects: $e");
    }
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/assignments/$rollNo"));
      if (res.statusCode == 200) {
        setState(() {
          _assignments = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching assignments: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addAssignment(String title, String subject, DateTime dueDate, String priority, String description) async {
    try {
      final rollNo = await StorageService.getRollNo();
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/assignments"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "rollNo": rollNo,
          "subject": subject,
          "title": title,
          "dueDate": dueDate.toIso8601String(),
          "priority": priority,
          "description": description,
          "status": "Pending",
        }),
      );
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Assignment added successfully")),
        );
        _fetchAssignments();
      } else {
        String msg = "Failed to add assignment";
        try {
          final data = jsonDecode(res.body);
          if (data['message'] != null) msg = data['message'].toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      debugPrint("Error adding assignment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _editAssignment(String id, String title, String subject, DateTime dueDate, String priority, String description) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/assignments/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "subject": subject,
          "title": title,
          "dueDate": dueDate.toIso8601String(),
          "priority": priority,
          "description": description,
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Assignment updated successfully")),
        );
        _fetchAssignments();
      } else {
        String msg = "Failed to update assignment";
        try {
          final data = jsonDecode(res.body);
          if (data['message'] != null) msg = data['message'].toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      debugPrint("Error editing assignment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _updateAssignmentStatus(String id, String status) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/assignments/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      );
      if (res.statusCode == 200) {
        _fetchAssignments();
      }
    } catch (e) {
      debugPrint("Error updating assignment status: $e");
    }
  }

  Future<void> _deleteAssignment(String id) async {
    try {
      final res = await http.delete(Uri.parse("${ApiService.baseUrl}/api/assignments/$id"));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Assignment deleted")),
        );
        _fetchAssignments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete assignment")),
        );
      }
    } catch (e) {
      debugPrint("Error deleting assignment: $e");
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedSubject = _subjects.isNotEmpty ? _subjects[0] : "General";
    String selectedPriority = "Medium";
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Add New Assignment", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Assignment Title"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: selectedSubject,
                      decoration: const InputDecoration(labelText: "Subject"),
                      items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDialogState(() => selectedSubject = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: "Priority"),
                      items: ["High", "Medium", "Low"].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDialogState(() => selectedPriority = val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Due Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
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
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: const Text("Select Date"),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Description (optional)"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Title cannot be empty")),
                      );
                      return;
                    }
                    _addAssignment(title, selectedSubject, selectedDate, selectedPriority, descController.text.trim());
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

  void _showEditDialog(Map assignment) {
    final id = assignment['_id']?.toString() ?? '';
    final titleController = TextEditingController(text: assignment['title']?.toString() ?? '');
    final descController = TextEditingController(text: assignment['description']?.toString() ?? '');
    
    String selectedSubject = assignment['subject']?.toString() ?? "General";
    if (!_subjects.contains(selectedSubject)) {
      _subjects.add(selectedSubject);
    }
    
    String selectedPriority = assignment['priority']?.toString() ?? "Medium";
    DateTime selectedDate = DateTime.tryParse(assignment['dueDate']?.toString() ?? '') ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Edit Assignment", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Assignment Title"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: selectedSubject,
                      decoration: const InputDecoration(labelText: "Subject"),
                      items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDialogState(() => selectedSubject = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: "Priority"),
                      items: ["High", "Medium", "Low"].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDialogState(() => selectedPriority = val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Due Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
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
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: const Text("Select Date"),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Title cannot be empty")),
                      );
                      return;
                    }
                    _editAssignment(id, title, selectedSubject, selectedDate, selectedPriority, descController.text.trim());
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
    final filtered = _assignments.where((a) {
      final t = a['title']?.toString().toLowerCase() ?? '';
      final s = a['subject']?.toString().toLowerCase() ?? '';
      return t.contains(_searchQuery.toLowerCase()) || s.contains(_searchQuery.toLowerCase());
    }).toList();

    final pending = _assignments.where((a) => a['status'] == 'Pending').length;
    final completed = _assignments.where((a) => a['status'] == 'Completed').length;

    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF13233D),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text("Pending", style: TextStyle(color: Colors.white60)),
                          const SizedBox(height: 6),
                          Text("$pending", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
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
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text("Completed", style: TextStyle(color: Colors.white60)),
                          const SizedBox(height: 6),
                          Text("$completed", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00BFA5))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search assignments...",
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF13233D),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(child: Text("No assignments found", style: TextStyle(color: Colors.white54, fontSize: 16)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final assignment = filtered[index];
                            final title = assignment['title']?.toString() ?? '';
                            final sub = assignment['subject']?.toString() ?? '';
                            final isDone = assignment['status'] == 'Completed';
                            final prio = assignment['priority']?.toString() ?? 'Medium';
                            final due = DateTime.tryParse(assignment['dueDate']?.toString() ?? '');
                            final formattedDue = due != null ? "${due.day}/${due.month}/${due.year}" : "";

                            Color priorityColor = Colors.green;
                            if (prio == 'High') priorityColor = Colors.redAccent;
                            if (prio == 'Medium') priorityColor = Colors.amber;

                            return Card(
                              color: const Color(0xFF13233D),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => _showEditDialog(assignment),
                                title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("$sub • Due: $formattedDue", style: const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                      child: Text(prio, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? const Color(0xFF00BFA5) : Colors.white54),
                                      onPressed: () {
                                        _updateAssignmentStatus(assignment['_id'], isDone ? 'Pending' : 'Completed');
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _deleteAssignment(assignment['_id']),
                                    ),
                                  ],
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
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
