import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  List _tasks = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedCategory = "All";

  final List<String> _categories = ["All", "General", "Homework", "Project", "Exam Prep", "Personal"];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/tasks/$rollNo"));
      if (res.statusCode == 200) {
        setState(() {
          _tasks = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch tasks: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTask(String title, String description, String priority, String category, DateTime? deadline) async {
    try {
      final rollNo = await StorageService.getRollNo();
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/tasks"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "rollNo": rollNo,
          "title": title,
          "description": description,
          "priority": priority,
          "category": category,
          "deadline": deadline?.toIso8601String(),
          "completed": false,
        }),
      );
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task added successfully")));
        _fetchTasks();
      }
    } catch (e) {
      debugPrint("Failed to add task: $e");
    }
  }

  Future<void> _editTask(String id, String title, String description, String priority, String category, DateTime? deadline) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/tasks/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "description": description,
          "priority": priority,
          "category": category,
          "deadline": deadline?.toIso8601String(),
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task updated successfully")));
        _fetchTasks();
      }
    } catch (e) {
      debugPrint("Failed to edit task: $e");
    }
  }

  Future<void> _toggleTaskComplete(String id, bool completed) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/tasks/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"completed": completed}),
      );
      if (res.statusCode == 200) {
        _fetchTasks();
      }
    } catch (e) {
      debugPrint("Failed to update task: $e");
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      final res = await http.delete(Uri.parse("${ApiService.baseUrl}/api/tasks/$id"));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task deleted")));
        _fetchTasks();
      }
    } catch (e) {
      debugPrint("Failed to delete task: $e");
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = "Medium";
    String selectedCategory = "General";
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Add New Task", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Task Title"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: "Priority"),
                      items: ["High", "Medium", "Low"].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDlgState(() => selectedPriority = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDlgState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDeadline == null
                                ? "No Deadline Set"
                                : "Deadline: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2027),
                            );
                            if (picked != null) {
                              setDlgState(() => selectedDeadline = picked);
                            }
                          },
                          child: const Text("Select Date"),
                        ),
                      ],
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title cannot be empty")));
                      return;
                    }
                    _addTask(title, descController.text.trim(), selectedPriority, selectedCategory, selectedDeadline);
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

  void _showEditDialog(Map task) {
    final id = task['_id']?.toString() ?? '';
    final titleController = TextEditingController(text: task['title']?.toString() ?? '');
    final descController = TextEditingController(text: task['description']?.toString() ?? '');
    String selectedPriority = task['priority']?.toString() ?? "Medium";
    String selectedCategory = task['category']?.toString() ?? "General";
    
    DateTime? selectedDeadline = DateTime.tryParse(task['deadline']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Edit Task details", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Task Title"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: "Priority"),
                      items: ["High", "Medium", "Low"].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDlgState(() => selectedPriority = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDlgState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDeadline == null
                                ? "No Deadline Set"
                                : "Deadline: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDeadline ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime(2027),
                            );
                            if (picked != null) {
                              setDlgState(() => selectedDeadline = picked);
                            }
                          },
                          child: const Text("Select Date"),
                        ),
                      ],
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title cannot be empty")));
                      return;
                    }
                    _editTask(id, title, descController.text.trim(), selectedPriority, selectedCategory, selectedDeadline);
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
    final filtered = _tasks.where((t) {
      final title = t['title']?.toString().toLowerCase() ?? '';
      final desc = t['description']?.toString().toLowerCase() ?? '';
      final matchesSearch = title.contains(_searchQuery.toLowerCase()) || desc.contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == "All" || t['category'] == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text("Task Checklist"),
        backgroundColor: Colors.black54,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search tasks...",
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF13233D),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(child: Text("No tasks found", style: TextStyle(color: Colors.white54, fontSize: 16)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final task = filtered[index];
                            final title = task['title']?.toString() ?? '';
                            final desc = task['description']?.toString() ?? '';
                            final isDone = task['completed'] == true;
                            final prio = task['priority']?.toString() ?? 'Medium';
                            
                            final deadlineStr = task['deadline']?.toString() ?? '';
                            final dl = DateTime.tryParse(deadlineStr);
                            final formattedDl = dl != null ? "${dl.day}/${dl.month}/${dl.year}" : "No Deadline";

                            Color prioColor = Colors.green;
                            if (prio == 'High') prioColor = Colors.redAccent;
                            if (prio == 'Medium') prioColor = Colors.amber;

                            return Card(
                              color: const Color(0xFF13233D),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => _showEditDialog(task),
                                leading: IconButton(
                                  icon: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? const Color(0xFF00BFA5) : Colors.white54),
                                  onPressed: () => _toggleTaskComplete(task['_id'], !isDone),
                                ),
                                title: Text(
                                  title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text("Deadline: $formattedDl", style: const TextStyle(color: Colors.white70)),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: prioColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                      child: Text(prio, style: TextStyle(color: prioColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deleteTask(task['_id']),
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
