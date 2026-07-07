import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class NotesManagerScreen extends StatefulWidget {
  const NotesManagerScreen({super.key});

  @override
  State<NotesManagerScreen> createState() => _NotesManagerScreenState();
}

class _NotesManagerScreenState extends State<NotesManagerScreen> {
  List _notes = [];
  List<String> _subjects = ["Java", "DBMS", "React", "Node.js", "Computer Networks", "Maths"];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedSubjectFilter = "All";
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    _fetchNotes();
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

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/notes/$rollNo"));
      if (res.statusCode == 200) {
        setState(() {
          _notes = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to load notes: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadNote() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'docx', 'png', 'jpg', 'jpeg', 'mp4'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      if (!mounted) return;
      final titleController = TextEditingController(text: file.name.split('.').first);
      final descController = TextEditingController();
      String selectedSubject = _subjects.isNotEmpty ? _subjects[0] : "General";

      final detailsConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDlgState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0F264C),
                title: const Text("Enter Note Details", style: TextStyle(color: Colors.white)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Notes Title"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F264C),
                      value: selectedSubject,
                      decoration: const InputDecoration(labelText: "Subject"),
                      items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setDlgState(() => selectedSubject = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Description (optional)"),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Upload")),
                ],
              );
            },
          );
        },
      );

      if (detailsConfirmed != true) return;

      final title = titleController.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title cannot be empty")));
        return;
      }

      setState(() => _isLoading = true);

      final rollNo = await StorageService.getRollNo();
      final uri = Uri.parse("${ApiService.baseUrl}/api/notes");
      final request = http.MultipartRequest("POST", uri);

      request.fields['rollNo'] = rollNo;
      request.fields['subject'] = selectedSubject;
      request.fields['title'] = title;
      request.fields['description'] = descController.text.trim();
      
      String ext = file.extension?.toLowerCase() ?? 'pdf';
      request.fields['fileType'] = ext;

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: file.name,
        ),
      );

      final response = await request.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note uploaded successfully")));
        _fetchNotes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note upload failed")));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Note picker/upload error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editNote(String id, String title, String subject, String description) async {
    try {
      final res = await http.put(
        Uri.parse("${ApiService.baseUrl}/api/notes/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "subject": subject,
          "description": description,
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note updated successfully")));
        _fetchNotes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update note")));
      }
    } catch (e) {
      debugPrint("Error updating note: $e");
    }
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      final res = await http.put(Uri.parse("${ApiService.baseUrl}/api/notes/$id/favorite"));
      if (res.statusCode == 200) {
        _fetchNotes();
      }
    } catch (e) {
      debugPrint("Failed to favorite note: $e");
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      final res = await http.delete(Uri.parse("${ApiService.baseUrl}/api/notes/$id"));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note deleted successfully")));
        _fetchNotes();
      }
    } catch (e) {
      debugPrint("Failed to delete note: $e");
    }
  }

  void _showEditDialog(Map note) {
    final id = note['_id']?.toString() ?? '';
    final titleController = TextEditingController(text: note['title']?.toString() ?? '');
    final descController = TextEditingController(text: note['description']?.toString() ?? '');
    String selectedSubject = note['subject']?.toString() ?? "General";

    if (!_subjects.contains(selectedSubject)) {
      _subjects.add(selectedSubject);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Edit Note Details", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Notes Title"),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF0F264C),
                    value: selectedSubject,
                    decoration: const InputDecoration(labelText: "Subject"),
                    items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => setDlgState(() => selectedSubject = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                ],
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
                    _editNote(id, title, selectedSubject, descController.text.trim());
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

  void _previewNote(Map note) {
    final path = note['filePath']?.toString() ?? '';
    final ext = note['fileType']?.toString().toLowerCase() ?? '';
    final url = "${ApiService.baseUrl}/${path.replaceAll('\\', '/')}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(note['title']?.toString() ?? "Preview")),
          body: ext == 'pdf'
              ? SfPdfViewer.network(url)
              : ext == 'png' || ext == 'jpg' || ext == 'jpeg'
                  ? Center(child: Image.network(url))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.insert_drive_file, size: 80, color: Colors.white54),
                          const SizedBox(height: 16),
                          Text("Preview not supported for $ext file types.", style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  void _downloadNote(Map note) {
    final path = note['filePath']?.toString() ?? '';
    final url = "${ApiService.baseUrl}/${path.replaceAll('\\', '/')}";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Download URL: $url"),
        action: SnackBarAction(
          label: "Copy Link",
          onPressed: () {
            // copy to clipboard
            // Clipboard.setData(ClipboardData(text: url));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notes.where((n) {
      final t = n['title']?.toString().toLowerCase() ?? '';
      final s = n['subject']?.toString().toLowerCase() ?? '';
      final d = n['description']?.toString().toLowerCase() ?? '';
      final matchesSearch = t.contains(_searchQuery.toLowerCase()) || 
                            s.contains(_searchQuery.toLowerCase()) ||
                            d.contains(_searchQuery.toLowerCase());
      final matchesSubject = _selectedSubjectFilter == "All" || n['subject'] == _selectedSubjectFilter;
      final matchesFavorite = !_showFavoritesOnly || n['isFavorite'] == true;

      return matchesSearch && matchesSubject && matchesFavorite;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text("Notes Hub"),
        backgroundColor: Colors.black54,
        actions: [
          IconButton(
            icon: Icon(_showFavoritesOnly ? Icons.star : Icons.star_border, color: _showFavoritesOnly ? Colors.amber : Colors.white),
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search notes...",
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
                children: [
                  ChoiceChip(
                    label: const Text("All Subjects"),
                    selected: _selectedSubjectFilter == "All",
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedSubjectFilter = "All");
                    },
                  ),
                  ..._subjects.map((sub) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(sub),
                        selected: _selectedSubjectFilter == sub,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedSubjectFilter = sub);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(child: Text("No notes found", style: TextStyle(color: Colors.white54, fontSize: 16)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final note = filtered[index];
                            final title = note['title']?.toString() ?? '';
                            final sub = note['subject']?.toString() ?? '';
                            final desc = note['description']?.toString() ?? '';
                            final ext = note['fileType']?.toString().toUpperCase() ?? '';
                            final fav = note['isFavorite'] == true;

                            return Card(
                              color: const Color(0xFF13233D),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => _showEditDialog(note),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(color: const Color(0xFF00BFA5).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                  child: Center(
                                    child: Text(ext, style: const TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ),
                                title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sub, style: const TextStyle(color: Colors.white70)),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(fav ? Icons.star : Icons.star_border, color: fav ? Colors.amber : Colors.white54),
                                      onPressed: () => _toggleFavorite(note['_id']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye, color: Colors.blueAccent),
                                      onPressed: () => _previewNote(note),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.download, color: Colors.orangeAccent),
                                      onPressed: () => _downloadNote(note),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _deleteNote(note['_id']),
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
        onPressed: _pickAndUploadNote,
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.upload_file, color: Colors.white),
      ),
    );
  }
}
