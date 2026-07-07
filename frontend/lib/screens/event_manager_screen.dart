import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class EventManagerScreen extends StatefulWidget {
  const EventManagerScreen({super.key});

  @override
  State<EventManagerScreen> createState() => _EventManagerScreenState();
}

class _EventManagerScreenState extends State<EventManagerScreen> {
  List _events = [];
  bool _isLoading = true;
  String _selectedCategoryFilter = "All";
  String _rollNo = "";

  final List<String> _categories = [
    "All",
    "College Event",
    "Hackathon",
    "Seminar",
    "Festival",
    "Technical Event",
    "Workshop"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndEvents();
  }

  Future<void> _loadUserAndEvents() async {
    _rollNo = await StorageService.getRollNo();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/events"));
      if (res.statusCode == 200) {
        setState(() {
          _events = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch events: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addEvent(String title, String description, String category, DateTime date, String location) async {
    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/events"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "description": description,
          "category": category,
          "date": date.toIso8601String(),
          "location": location,
        }),
      );
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event created successfully")));
        _fetchEvents();
      }
    } catch (e) {
      debugPrint("Failed to add event: $e");
    }
  }

  Future<void> _editEvent(String id, String title, String description, String category, DateTime date, String location) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/events/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "description": description,
          "category": category,
          "date": date.toIso8601String(),
          "location": location,
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event updated successfully")));
        _fetchEvents();
      }
    } catch (e) {
      debugPrint("Failed to edit event: $e");
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      final res = await http.delete(Uri.parse("${ApiService.baseUrl}/api/events/$id"));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event deleted")));
        _fetchEvents();
      }
    } catch (e) {
      debugPrint("Failed to delete event: $e");
    }
  }

  Future<void> _registerForEvent(String id) async {
    if (_rollNo.isEmpty) return;
    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/events/register/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"rollNo": _rollNo}),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registered successfully!")));
        _fetchEvents();
      } else {
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['message'] ?? "Registration failed")));
      }
    } catch (e) {
      debugPrint("Event registration failed: $e");
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locController = TextEditingController();
    String selectedCategory = _categories[1];
    DateTime selectedDate = DateTime.now().add(const Duration(days: 14));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Schedule Event", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Event Name"),
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
                      controller: locController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Location / Venue"),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event Name is required")));
                      return;
                    }
                    _addEvent(title, descController.text.trim(), selectedCategory, selectedDate, locController.text.trim());
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

  void _showEditDialog(Map event) {
    final id = event['_id']?.toString() ?? '';
    final titleController = TextEditingController(text: event['title']?.toString() ?? '');
    final descController = TextEditingController(text: event['description']?.toString() ?? '');
    final locController = TextEditingController(text: event['location']?.toString() ?? '');
    String selectedCategory = event['category']?.toString() ?? _categories[1];
    DateTime selectedDate = DateTime.tryParse(event['date']?.toString() ?? '') ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Edit Event Details", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Event Name"),
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
                      controller: locController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Location / Venue"),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event Name is required")));
                      return;
                    }
                    _editEvent(id, title, descController.text.trim(), selectedCategory, selectedDate, locController.text.trim());
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
    final filtered = _events.where((e) {
      return _selectedCategoryFilter == "All" || e['category'] == _selectedCategoryFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text("Campus Events Portal"),
        backgroundColor: Colors.black54,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: _selectedCategoryFilter == cat,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategoryFilter = cat);
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
                      ? const Center(child: Text("No events scheduled", style: TextStyle(color: Colors.white54, fontSize: 16)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final eventObj = filtered[index];
                            final title = eventObj['title']?.toString() ?? '';
                            final desc = eventObj['description']?.toString() ?? '';
                            final cat = eventObj['category']?.toString() ?? '';
                            final date = eventObj['date'] != null ? DateTime.tryParse(eventObj['date']) : null;
                            final formattedDate = date != null ? "${date.day}/${date.month}/${date.year}" : "";
                            final loc = eventObj['location']?.toString() ?? '';
                            final regList = List<String>.from(eventObj['registeredStudents'] ?? []);
                            final isRegistered = regList.contains(_rollNo);
                            final closed = eventObj['registrationClosed'] == true;

                            return Card(
                              color: const Color(0xFF13233D),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFF00BFA5).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                                          child: Text(cat, style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        Row(
                                          children: [
                                            Text(formattedDate, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                                              onPressed: () => _showEditDialog(eventObj),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                              onPressed: () => _deleteEvent(eventObj['_id']),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.white54),
                                        const SizedBox(width: 4),
                                        Text(loc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: closed || isRegistered ? null : () => _registerForEvent(eventObj['_id']),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 44),
                                        backgroundColor: isRegistered ? Colors.grey : const Color(0xFF00BFA5),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(isRegistered
                                          ? "Registered ✓"
                                          : closed
                                              ? "Registration Closed"
                                              : "Register Now"),
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
