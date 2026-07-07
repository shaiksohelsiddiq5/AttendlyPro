import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/dashboard_screen.dart';

import 'screens/attendance_screen.dart';
import 'screens/holidays_screen.dart';
import 'screens/exams_screen.dart';

import 'screens/leave_planner_screen.dart';
import 'screens/bunk_screen.dart';
import 'screens/recovery_screen.dart';

import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';

import 'screens/calendar_upload_screen.dart';
import 'screens/timetable_upload_screen.dart';
import 'screens/holiday_manager_screen.dart';

import 'screens/smart_leave_screen.dart';
import 'screens/attendance_analytics_screen.dart';
import 'screens/exam_countdown_screen.dart';
import 'screens/semester_progress_screen.dart';
import 'screens/subject_tracker_screen.dart';
import 'screens/goal_tracker_screen.dart';
import 'screens/notification_center_screen.dart';
import 'screens/student_stats_screen.dart';
import 'screens/smart_recommendation_screen.dart';
import 'screens/attendance_predictor_screen.dart';

import 'screens/semester_summary_screen.dart';
import 'screens/attendance_calculator_screen.dart';
import 'screens/timetable_viewer_screen.dart';
import 'screens/subject_analytics_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/about_screen.dart';
import 'screens/attendance_history_screen.dart';
import 'screens/academic_menu_screen.dart';
import 'screens/leave_menu_screen.dart';
import 'screens/analytics_menu_screen.dart';
import 'screens/profile_menu_screen.dart';

// New Screens
import 'screens/assignments_screen.dart';
import 'screens/study_planner_screen.dart';
import 'screens/notes_manager_screen.dart';
import 'screens/cgpa_tracker_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/notice_board_screen.dart';
import 'screens/reminder_manager_screen.dart';
import 'screens/task_manager_screen.dart';
import 'screens/file_manager_screen.dart';
import 'screens/event_manager_screen.dart';
import 'screens/achievements_screen.dart';

// Shell Layout
import 'widgets/main_layout.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLight = prefs.getBool("isLightMode") ?? false;
  themeNotifier.value = isLight ? ThemeMode.light : ThemeMode.dark;
  runApp(const MyAttendanceApp());
}

class MyAttendanceApp extends StatelessWidget {
  const MyAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "My Attendance Manager",
          themeMode: currentMode,

          // Light Theme Design
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00BFA5),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.grey.shade50,
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black12,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          // Dark Theme Design
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00BFA5),
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

          initialRoute: "/",

          routes: {
            "/": (context) => const LoginScreen(),
            "/signup": (context) => const SignupScreen(),
            "/setup": (context) => const SetupScreen(),
            
            // Core main layout wrapper
            "/dashboard": (context) => const MainLayout(initialTab: 0),
            "/attendance": (context) => const MainLayout(initialTab: 1),
            "/assignments": (context) => const MainLayout(initialTab: 2),
            "/study-planner": (context) => const MainLayout(initialTab: 3),
            "/profile": (context) => const MainLayout(initialTab: 4),

            "/academic-menu": (context) => const AcademicMenuScreen(),
            "/leave-menu": (context) => const LeaveMenuScreen(),
            "/analytics-menu": (context) => const AnalyticsMenuScreen(),
            "/profile-menu": (context) => const ProfileMenuScreen(),
            "/holidays": (context) => const HolidaysScreen(),
            "/exams": (context) => const ExamsScreen(),
            "/leave-planner": (context) => const LeavePlannerScreen(),
            "/bunk": (context) => const BunkScreen(),
            "/recovery": (context) => const RecoveryScreen(),
            "/alerts": (context) => const AlertsScreen(),
            "/calendar-upload": (context) => const CalendarUploadScreen(),
            "/timetable-upload": (context) => const TimetableUploadScreen(),
            "/holiday-manager": (context) => const HolidayManagerScreen(),
            "/smart-leave": (context) => const SmartLeaveScreen(),
            "/attendance-analytics": (context) => const AttendanceAnalyticsScreen(),
            "/exam-countdown": (context) => const ExamCountdownScreen(),
            "/semester-progress": (context) => const SemesterProgressScreen(),
            "/subject-tracker": (context) => const SubjectTrackerScreen(),
            "/goal-tracker": (context) => const GoalTrackerScreen(),
            "/notification-center": (context) => const NotificationCenterScreen(),
            "/student-stats": (context) => const StudentStatsScreen(),
            "/smart-recommendation": (context) => const SmartRecommendationScreen(),
            "/attendance-predictor": (context) => const AttendancePredictorScreen(),
            "/semester-summary": (context) => const SemesterSummaryScreen(),
            "/attendance-calculator": (context) => const AttendanceCalculatorScreen(),
            "/academic-calendar-viewer": (context) => const Scaffold(
              body: Center(child: Text("Open from Upload Screen")),
            ),
            "/timetable-viewer": (context) => const TimetableViewerScreen(),
            "/subject-analytics": (context) => const SubjectAnalyticsScreen(),
            "/ai-assistant": (context) => const AiAssistantScreen(),
            "/settings": (context) => const SettingsScreen(),
            "/help-support": (context) => const HelpSupportScreen(),
            "/about": (context) => const AboutScreen(),
            "/attendance-history": (context) => const AttendanceHistoryScreen(),

            // Upgraded screens
            "/notes-manager": (context) => const NotesManagerScreen(),
            "/cgpa-tracker": (context) => const CgpaTrackerScreen(),
            "/analytics-dashboard": (context) => const AnalyticsDashboardScreen(),
            "/notice-board": (context) => const NoticeBoardScreen(),
            "/reminder-manager": (context) => const ReminderManagerScreen(),
            "/task-manager": (context) => const TaskManagerScreen(),
            "/file-manager": (context) => const FileManagerScreen(),
            "/event-manager": (context) => const EventManagerScreen(),
            "/achievements": (context) => const AchievementsScreen(),
          },
        );
      },
    );
  }
}
