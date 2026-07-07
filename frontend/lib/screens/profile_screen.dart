import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String name = "";
  String rollNo = "";
  String branch = "";
  String year = "";
  String semester = "";
  String section = "";
  String phone = "";
  String email = "";
  List<String> skills = [];
  String photoPath = "";
  String resumePath = "";

  // Local Picked Files
  PlatformFile? _pickedPhoto;
  PlatformFile? _pickedResume;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final roll = await StorageService.getRollNo();
      if (roll.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/profile/$roll"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['profile'] != null) {
          final p = data['profile'];
          setState(() {
            name = p['name']?.toString() ?? "";
            rollNo = p['rollNo']?.toString() ?? "";
            branch = p['branch']?.toString() ?? "";
            year = p['year']?.toString() ?? "";
            semester = p['semester']?.toString() ?? "";
            section = p['section']?.toString() ?? "";
            phone = p['phone']?.toString() ?? "";
            email = p['email']?.toString() ?? "";
            skills = List<String>.from(p['skills'] ?? []);
            photoPath = p['photo']?.toString() ?? "";
            resumePath = p['resume']?.toString() ?? "";
            _isLoading = false;
          });
          return;
        }
      }

      // Fallback to storage
      name = await StorageService.getName();
      rollNo = await StorageService.getRollNo();
      branch = await StorageService.getBranch();
      year = await StorageService.getYear();
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Failed to fetch profile: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedPhoto = result.files.first;
      });
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedResume = result.files.first;
      });
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: name);
    final branchController = TextEditingController(text: branch);
    final yearController = TextEditingController(text: year);
    final semController = TextEditingController(text: semester);
    final secController = TextEditingController(text: section);
    final phoneController = TextEditingController(text: phone);
    final emailController = TextEditingController(text: email);
    final skillsController = TextEditingController(text: skills.join(", "));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Edit Profile Info", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Student Name"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: branchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Branch"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: yearController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Year (e.g. 2-1)"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: semController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Semester (e.g. 3rd)"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: secController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Section (e.g. A)"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Phone Number"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Email Address"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: skillsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Skills (comma separated)"),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _pickedPhoto == null ? "Photo: None selected" : "Photo: Selected ✓",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _pickPhoto();
                            setDlgState(() {});
                          },
                          child: const Text("Select Photo"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _pickedResume == null ? "Resume: None selected" : "Resume: Selected ✓",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _pickResume();
                            setDlgState(() {});
                          },
                          child: const Text("Select Resume"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final newBranch = branchController.text.trim();
                    final newYear = yearController.text.trim();

                    if (newName.isEmpty || newBranch.isEmpty || newYear.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Name, Branch, and Year are required")),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    setState(() => _isLoading = true);

                    try {
                      final uri = Uri.parse("${ApiService.baseUrl}/api/profile/update");
                      final request = http.MultipartRequest("POST", uri);

                      request.fields['rollNo'] = rollNo;
                      request.fields['name'] = newName;
                      request.fields['branch'] = newBranch;
                      request.fields['year'] = newYear;
                      request.fields['semester'] = semController.text.trim();
                      request.fields['section'] = secController.text.trim();
                      request.fields['phone'] = phoneController.text.trim();
                      request.fields['email'] = emailController.text.trim();
                      request.fields['skills'] = skillsController.text.trim();

                      if (_pickedPhoto != null && _pickedPhoto!.bytes != null) {
                        request.files.add(
                          http.MultipartFile.fromBytes(
                            "photo",
                            _pickedPhoto!.bytes!,
                            filename: _pickedPhoto!.name,
                          ),
                        );
                      }
                      if (_pickedResume != null && _pickedResume!.bytes != null) {
                        request.files.add(
                          http.MultipartFile.fromBytes(
                            "resume",
                            _pickedResume!.bytes!,
                            filename: _pickedResume!.name,
                          ),
                        );
                      }

                      final response = await request.send();
                      if (response.statusCode == 200) {
                        await StorageService.saveStudent(newName, rollNo);
                        await StorageService.saveSetup(newBranch, newYear, "", "");
                        _fetchProfileData();
                        messenger.showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
                      } else {
                        messenger.showSnackBar(const SnackBar(content: Text("Failed to update profile")));
                        setState(() => _isLoading = false);
                      }
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
                      setState(() => _isLoading = false);
                    }
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

  Widget profileTile(IconData icon, String title, String value) {
    return Card(
      color: const Color(0xFF13233D),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00BFA5)),
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        trailing: Text(
          value.isNotEmpty ? value : "Not specified",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = photoPath.isNotEmpty ? "${ApiService.baseUrl}/${photoPath.replaceAll('\\', '/')}" : "";

    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEditDialog,
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 70,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                profileTile(Icons.person, "Student Name", name),
                profileTile(Icons.badge, "Roll Number", rollNo),
                profileTile(Icons.school, "Branch", branch),
                profileTile(Icons.menu_book, "Year", year),
                profileTile(Icons.calendar_view_week, "Semester", semester),
                profileTile(Icons.group, "Section", section),
                profileTile(Icons.phone, "Phone", phone),
                profileTile(Icons.email, "Email", email),
                Card(
                  color: const Color(0xFF13233D),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Skills", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        skills.isEmpty
                            ? const Text("No skills listed", style: TextStyle(color: Colors.white30))
                            : Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: skills.map((skill) {
                                  return Chip(
                                    label: Text(skill, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: const Color(0xFF00BFA5).withOpacity(0.12),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),
                if (resumePath.isNotEmpty)
                  Card(
                    color: const Color(0xFF13233D),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.description, color: Colors.orange),
                      title: const Text("Student Resume", style: TextStyle(color: Colors.white)),
                      subtitle: const Text("Tap to download/view", style: TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.download, color: Colors.white30),
                      onTap: () {
                        final resumeUrl = "${ApiService.baseUrl}/${resumePath.replaceAll('\\', '/')}";
                        // Simply download/view via browser opening or custom logic
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Downloading resume: $resumeUrl")));
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}