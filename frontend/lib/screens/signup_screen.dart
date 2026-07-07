import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscureSignupPassword = true;
  final nameController = TextEditingController();
  final rollController = TextEditingController();
  final passwordController = TextEditingController();
  final branchController = TextEditingController();
  final yearController = TextEditingController();
  final answerController = TextEditingController();

  final List<String> _questions = [
    "What is your mother's maiden name?",
    "What was the name of your first pet?",
    "What is your favorite book?",
    "In what city were you born?",
    "What was the name of your elementary school?",
  ];
  late String _selectedQuestion;

  @override
  void initState() {
    super.initState();
    _selectedQuestion = _questions.first;
  }

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final roll = rollController.text.trim();
    final password = passwordController.text.trim();
    final answer = answerController.text.trim();

    if (name.isEmpty || roll.isEmpty || password.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields (including Security Answer) are required")),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "rollNo": roll,
          "password": password,
          "branch": branchController.text.trim(),
          "year": yearController.text.trim(),
          "securityQuestion": _selectedQuestion,
          "securityAnswer": answer,
        }),
      );

      if (response.statusCode == 201) {
        messenger.showSnackBar(const SnackBar(content: Text("Registration Successful")));
        navigator.pushReplacementNamed("/");
      } else {
        final data = jsonDecode(response.body);
        messenger.showSnackBar(
          SnackBar(
            content: Text(data['message']?.toString() ?? 'Registration failed'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    rollController.dispose();
    passwordController.dispose();
    branchController.dispose();
    yearController.dispose();
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081B3A),
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rollController,
              decoration: const InputDecoration(labelText: "Roll Number"),
            ),
            const SizedBox(height: 12),
             TextField(
               controller: passwordController,
               obscureText: _obscureSignupPassword,
               decoration: InputDecoration(
                 labelText: "Password",
                 suffixIcon: IconButton(
                   icon: Icon(
                     _obscureSignupPassword ? Icons.visibility : Icons.visibility_off,
                     color: Colors.grey,
                   ),
                   onPressed: () {
                     setState(() {
                       _obscureSignupPassword = !_obscureSignupPassword;
                     });
                   },
                 ),
               ),
             ),
            const SizedBox(height: 12),
            TextField(
              controller: branchController,
              decoration: const InputDecoration(labelText: "Branch"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearController,
              decoration: const InputDecoration(labelText: "Year"),
            ),
            const SizedBox(height: 18),
            
            // Security Question Dropdown Selector
            const Text(
              "Select Security Question (for password recovery):",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedQuestion,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _questions.map((q) {
                return DropdownMenuItem<String>(
                  value: q,
                  child: Text(q, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedQuestion = val;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: answerController,
              decoration: const InputDecoration(
                labelText: "Security Answer",
                hintText: "Your answer is case-insensitive",
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: registerUser,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
