import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../screens/dashboard_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/assignments_screen.dart';
import '../screens/study_planner_screen.dart';
import '../screens/profile_screen.dart';

class MainLayout extends StatefulWidget {
  final int initialTab;
  const MainLayout({super.key, this.initialTab = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  final List<Widget> _pages = [
    const DashboardScreen(),
    const AttendanceScreen(),
    const AssignmentsScreen(),
    const StudyPlannerScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    "Dashboard",
    "Attendance Tracker",
    "Assignment Manager",
    "Study Planner",
    "Student Profile",
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToTab(int index) {
    Navigator.pop(context); // Close drawer
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.black54,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Profile Menu',
            onPressed: () => Navigator.pushNamed(context, '/profile-menu'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F264C),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00796B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.school, size: 40, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    "AttendlyPro",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Smart Student Platform",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: Colors.white70),
              title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
              onTap: () => _navigateToTab(0),
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded, color: Colors.white70),
              title: const Text("Attendance", style: TextStyle(color: Colors.white)),
              onTap: () => _navigateToTab(1),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded, color: Colors.white70),
              title: const Text("Timetable", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/timetable-viewer");
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range_rounded, color: Colors.white70),
              title: const Text("Academic Calendar", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/calendar-upload");
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_rounded, color: Colors.white70),
              title: const Text("Assignments", style: TextStyle(color: Colors.white)),
              onTap: () => _navigateToTab(2),
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded, color: Colors.white70),
              title: const Text("Notes Manager", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/notes-manager");
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_rounded, color: Colors.white70),
              title: const Text("Study Planner", style: TextStyle(color: Colors.white)),
              onTap: () => _navigateToTab(3),
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded, color: Colors.white70),
              title: const Text("Exam Manager", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/exams");
              },
            ),
            ListTile(
              leading: const Icon(Icons.grade_rounded, color: Colors.white70),
              title: const Text("CGPA Tracker", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/cgpa-tracker");
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_rounded, color: Colors.white70),
              title: const Text("Analytics Dashboard", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/analytics-dashboard");
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_rounded, color: Colors.white70),
              title: const Text("Notice Board", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/notice-board");
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt_rounded, color: Colors.white70),
              title: const Text("Tasks", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/task-manager");
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note_rounded, color: Colors.white70),
              title: const Text("Events", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/event-manager");
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_rounded, color: Colors.white70),
              title: const Text("Achievements", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/achievements");
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: Colors.white70),
              title: const Text("Profile", style: TextStyle(color: Colors.white)),
              onTap: () => _navigateToTab(4),
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Colors.white70),
              title: const Text("Settings", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/settings");
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await StorageService.logout();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF13233D),
        selectedItemColor: const Color(0xFF00BFA5),
        unselectedItemColor: Colors.white54,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: "Attendance",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: "Assignments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: "Study",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
