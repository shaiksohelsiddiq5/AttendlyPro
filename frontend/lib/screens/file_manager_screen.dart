import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  List _files = [];
  bool _isLoading = true;
  String _selectedCategoryFilter = "All";

  final List<String> _categories = [
    "All",
    "Assignment",
    "Resume",
    "Certificate",
    "Notes",
    "Image",
    "PDF"
  ];

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() => _isLoading = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/files/$rollNo"));
      if (res.statusCode == 200) {
        setState(() {
          _files = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch files: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      if (!mounted) return;
      String selectedCategory = "Assignment";

      // Choose Category
      final categorySelected = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDlgState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0F264C),
                title: const Text("Select File Category", style: TextStyle(color: Colors.white)),
                content: DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF0F264C),
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Category"),
                  items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setDlgState(() => selectedCategory = val!),
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

      if (categorySelected != true) return;

      setState(() => _isLoading = true);

      final rollNo = await StorageService.getRollNo();
      final uri = Uri.parse("${ApiService.baseUrl}/api/files");
      final request = http.MultipartRequest("POST", uri);

      request.fields['rollNo'] = rollNo;
      request.fields['category'] = selectedCategory;

      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: file.name,
        ),
      );

      final response = await request.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File uploaded successfully")));
        _fetchFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File upload failed")));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("File picking/uploading failed: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFile(String id) async {
    try {
      final res = await http.delete(Uri.parse("${ApiService.baseUrl}/api/files/$id"));
      if (res.statusCode == 200) {
        _fetchFiles();
      }
    } catch (e) {
      debugPrint("Failed to delete file: $e");
    }
  }

  void _previewFile(Map fileItem) {
    final path = fileItem['filePath']?.toString() ?? '';
    final url = "${ApiService.baseUrl}/${path.replaceAll('\\', '/')}";
    final name = fileItem['fileName']?.toString() ?? '';
    final isPdf = name.toLowerCase().endsWith('.pdf');
    final isImage = name.toLowerCase().endsWith('.png') || name.toLowerCase().endsWith('.jpg') || name.toLowerCase().endsWith('.jpeg');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(name)),
          body: isPdf
              ? SfPdfViewer.network(url)
              : isImage
                  ? Center(child: Image.network(url))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.insert_drive_file, size: 80, color: Colors.white54),
                          const SizedBox(height: 16),
                          Text("Preview not supported. Path:\n$url", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _files.where((f) {
      return _selectedCategoryFilter == "All" || f['category'] == _selectedCategoryFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text("Document Vault"),
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
                      ? const Center(child: Text("No files uploaded in this category", style: TextStyle(color: Colors.white54, fontSize: 16)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final fileItem = filtered[index];
                            final name = fileItem['fileName']?.toString() ?? '';
                            final cat = fileItem['category']?.toString() ?? '';
                            final date = fileItem['uploadedAt'] != null ? DateTime.tryParse(fileItem['uploadedAt']) : null;
                            final formattedDate = date != null ? "${date.day}/${date.month}/${date.year}" : "";

                            return Card(
                              color: const Color(0xFF13233D),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const Icon(Icons.file_present_rounded, color: Color(0xFF00BFA5)),
                                title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text("$cat • $formattedDate", style: const TextStyle(color: Colors.white70)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye, color: Colors.blueAccent),
                                      onPressed: () => _previewFile(fileItem),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _deleteFile(fileItem['_id']),
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
        onPressed: _uploadFile,
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.add_to_photos, color: Colors.white),
      ),
    );
  }
}
