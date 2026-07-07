import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  List _notices = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedCategory = "All";

  final List<String> _categories = [
    "All",
    "College",
    "Department",
    "Placements",
    "Hackathons",
    "Seminars",
    "Workshops",
    "Events"
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/notices"));
      if (res.statusCode == 200) {
        setState(() {
          _notices = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch notices: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNotice(String title, String content, String category, bool isPinned) async {
    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/notices"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "content": content,
          "category": category,
          "isPinned": isPinned,
        }),
      );
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notice published successfully")));
        _fetchNotices();
      }
    } catch (e) {
      debugPrint("Failed to add notice: $e");
    }
  }

  Future<void> _editNotice(String id, String title, String content, String category, bool isPinned) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/notices/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "content": content,
          "category": category,
          "isPinned": isPinned,
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notice updated successfully")));
        _fetchNotices();
      }
    } catch (e) {
      debugPrint("Failed to edit notice: $e");
    }
  }

  Future<void> _deleteNotice(String id) async {
    try {
      final res = await http.delete(Uri.parse("${ApiService.baseUrl}/api/notices/$id"));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notice deleted")));
        _fetchNotices();
      }
    } catch (e) {
      debugPrint("Failed to delete notice: $e");
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = _categories[1];
    bool isPinned = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Publish Notice", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Notice Title"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: category,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDlgState(() => category = val!),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text("Pin Notice", style: TextStyle(color: Colors.white, fontSize: 14)),
                      value: isPinned,
                      onChanged: (val) => setDlgState(() => isPinned = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Notice Details / Description"),
                      maxLines: 4,
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required")));
                      return;
                    }
                    _addNotice(title, contentController.text.trim(), category, isPinned);
                    Navigator.pop(context);
                  },
                  child: const Text("Publish"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(Map notice) {
    final id = notice['_id']?.toString() ?? '';
    final titleController = TextEditingController(text: notice['title']?.toString() ?? '');
    final contentController = TextEditingController(text: notice['content']?.toString() ?? '');
    String category = notice['category']?.toString() ?? _categories[1];
    bool isPinned = notice['isPinned'] == true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Edit Notice", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Notice Title"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: category,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDlgState(() => category = val!),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text("Pin Notice", style: TextStyle(color: Colors.white, fontSize: 14)),
                      value: isPinned,
                      onChanged: (val) => setDlgState(() => isPinned = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Notice Details / Description"),
                      maxLines: 4,
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required")));
                      return;
                    }
                    _editNotice(id, title, contentController.text.trim(), category, isPinned);
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

  void _showNoticeDetail(Map notice) {
    showDialog(
      context: context,
      builder: (context) {
        final title = notice['title']?.toString() ?? '';
        final content = notice['content']?.toString() ?? '';
        final cat = notice['category']?.toString() ?? 'General';
        final isPinned = notice['isPinned'] == true;

        return AlertDialog(
          backgroundColor: const Color(0xFF0F264C),
          title: Row(
            children: [
              if (isPinned) const Icon(Icons.push_pin, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF00BFA5).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(cat, style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.white60)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notices.where((n) {
      final t = n['title']?.toString().toLowerCase() ?? '';
      final c = n['content']?.toString().toLowerCase() ?? '';
      final matchesSearch = t.contains(_searchQuery.toLowerCase()) || c.contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == "All" || n['category'] == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text("Campus Notices"),
        backgroundColor: Colors.black54,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search notices...",
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
                      ? const Center(child: Text("No notices found", style: TextStyle(color: Colors.white54, fontSize: 16)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final notice = filtered[index];
                            final title = notice['title']?.toString() ?? '';
                            final cat = notice['category']?.toString() ?? 'General';
                            final isPinned = notice['isPinned'] == true;

                            return Card(
                              color: isPinned ? const Color(0xFF1E3252) : const Color(0xFF13233D),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => _showNoticeDetail(notice),
                                leading: Icon(isPinned ? Icons.push_pin : Icons.campaign_rounded, color: isPinned ? Colors.orange : const Color(0xFF00BFA5)),
                                title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text(cat, style: const TextStyle(color: Colors.white70)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                                      onPressed: () => _showEditDialog(notice),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                      onPressed: () => _deleteNotice(notice['_id']),
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
