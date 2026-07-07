import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  bool _obscureLoginPassword = true;
  bool _obscureResetPassword = true;

  final rollController = TextEditingController();

  final passwordController = TextEditingController();

  Future<void> loginUser() async {
    if (rollController.text.trim().isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your roll number and password')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "rollNo": rollController.text,
          "password": passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'] as Map<String, dynamic>? ?? {};

        await StorageService.saveStudent(
          user['name']?.toString() ?? '',
          rollController.text,
        );

        await StorageService.saveSetup(
          user['branch']?.toString() ?? '',
          user['year']?.toString() ?? '',
          user['currentAttendance']?.toString() ?? '',
          user['targetAttendance']?.toString() ?? '',
        );

        await StorageService.saveAttendanceCounts(
          (user['attendedClasses'] as num? ?? 0).toInt(),
          (user['totalClasses'] as num? ?? 0).toInt(),
        );

        if (user['calendarFileName'] != null &&
            user['calendarFileName'].toString().isNotEmpty) {
          await StorageService.saveCalendar(
            user['calendarFileName'].toString(),
          );
        }

        if (user['timetableFileName'] != null &&
            user['timetableFileName'].toString().isNotEmpty) {
          await StorageService.saveTimetable(
            user['timetableFileName'].toString(),
            "",
          );
        }

        if (!mounted) return;

        if (user['setupComplete'] == true) {
          Navigator.pushReplacementNamed(context, "/dashboard");
        } else {
          Navigator.pushReplacementNamed(context, "/setup");
        }
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']?.toString() ?? 'Login failed'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    rollController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final rollResetController = TextEditingController();
    final answerController = TextEditingController();
    final newPasswordController = TextEditingController();

    String securityQuestion = "";
    bool fetchedQuestion = false;
    bool loadingQuestion = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F264C),
              title: const Text("Reset Password", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: rollResetController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Roll Number",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                      ),
                      enabled: !fetchedQuestion,
                    ),
                    const SizedBox(height: 12),
                    if (!fetchedQuestion) ...[
                      if (loadingQuestion)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton(
                          onPressed: () async {
                            final roll = rollResetController.text.trim();
                            if (roll.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter your roll number")),
                              );
                              return;
                            }
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => loadingQuestion = true);
                            try {
                              final res = await http.get(
                                Uri.parse("${ApiService.baseUrl}/forgot-password/question/$roll"),
                              );
                              if (res.statusCode == 200) {
                                final data = jsonDecode(res.body);
                                setState(() {
                                  securityQuestion = data['securityQuestion']?.toString() ?? "";
                                  fetchedQuestion = true;
                                });
                              } else {
                                final data = jsonDecode(res.body);
                                messenger.showSnackBar(
                                  SnackBar(content: Text(data['message']?.toString() ?? "User not found")),
                                );
                              }
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text("Error fetching question: $e")),
                              );
                            } finally {
                              setState(() => loadingQuestion = false);
                            }
                          },
                          child: const Text("Get Security Question"),
                        ),
                    ] else ...[
                      Text(
                        "Question: $securityQuestion",
                        style: const TextStyle(color: Color(0xFFFFB547), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: answerController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Security Answer",
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newPasswordController,
                        obscureText: _obscureResetPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "New Password",
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureResetPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureResetPassword = !_obscureResetPassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
                ),
                if (fetchedQuestion)
                  ElevatedButton(
                    onPressed: () async {
                      final roll = rollResetController.text.trim();
                      final answer = answerController.text.trim();
                      final newPass = newPasswordController.text;
                      if (answer.isEmpty || newPass.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Answer and New Password are required")),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      try {
                        final res = await http.post(
                          Uri.parse("${ApiService.baseUrl}/forgot-password"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "rollNo": roll,
                            "securityAnswer": answer,
                            "newPassword": newPass,
                          }),
                        );

                        if (res.statusCode == 200) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text("Password reset successful!")),
                          );
                          navigator.pop();
                        } else {
                          final data = jsonDecode(res.body);
                          messenger.showSnackBar(
                            SnackBar(content: Text(data['message']?.toString() ?? "Failed to reset password")),
                          );
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    },
                    child: const Text("Reset"),
                  ),
              ],
            );
          },
        );
      },
    );

    rollResetController.dispose();
    answerController.dispose();
    newPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF081426),
        cardTheme: const CardThemeData(
          color: Color(0xFF13233D),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF13233D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF081B3A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "📚 My Attendance Manager",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: rollController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Roll Number",
                    hintStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: _obscureLoginPassword,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Password",
                    hintStyle: const TextStyle(color: Colors.black54),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureLoginPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureLoginPassword = !_obscureLoginPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : loginUser,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Login"),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/signup");
                  },
                  child: const Text("Create Account"),
                ),
                const SizedBox(height: 5),
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text("Forgot Password?", style: TextStyle(color: Colors.white60)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
