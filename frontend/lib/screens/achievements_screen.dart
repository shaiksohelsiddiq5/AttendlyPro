import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List _badges = [];
  List _customAchievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAchievements();
  }

  Future<void> _fetchAchievements() async {
    setState(() => _isLoading = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/achievements/$rollNo"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _badges = data['badges'] ?? [];
          _customAchievements = data['customAchievements'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch achievements: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text("Student Achievements"),
        backgroundColor: Colors.black54,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("Unlocked Badges", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _badges.length,
                  itemBuilder: (context, index) {
                    final badge = _badges[index];
                    final title = badge['title']?.toString() ?? '';
                    final desc = badge['description']?.toString() ?? '';
                    final type = badge['badgeType']?.toString() ?? '';
                    final unlocked = badge['unlocked'] == true;

                    IconData icon = Icons.workspace_premium;
                    Color badgeColor = Colors.orange;

                    if (type == '100% Attendance') {
                      icon = Icons.calendar_today_rounded;
                      badgeColor = const Color(0xFF00BFA5);
                    } else if (type == '7 Day Study Streak') {
                      icon = Icons.local_fire_department_rounded;
                      badgeColor = Colors.deepOrangeAccent;
                    } else if (type == '10 Assignments Completed') {
                      icon = Icons.assignment_turned_in_rounded;
                      badgeColor = Colors.purpleAccent;
                    } else if (type == 'First Login') {
                      icon = Icons.stars_rounded;
                      badgeColor = Colors.amber;
                    }

                    return Card(
                      color: unlocked ? const Color(0xFF13233D) : const Color(0xFF13233D).withValues(alpha: 0.4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 48,
                              color: unlocked ? badgeColor : Colors.white24,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: unlocked ? Colors.white : Colors.white30, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              desc,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: unlocked ? Colors.white70 : Colors.white10, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (_customAchievements.isNotEmpty) ...[
                  const Text("Special Accolades", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._customAchievements.map((ach) {
                    final title = ach['title']?.toString() ?? '';
                    final desc = ach['description']?.toString() ?? '';
                    return Card(
                      color: const Color(0xFF13233D),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.emoji_events, color: Colors.amber),
                        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(desc, style: const TextStyle(color: Colors.white70)),
                      ),
                    );
                  }),
                ]
              ],
            ),
    );
  }
}
