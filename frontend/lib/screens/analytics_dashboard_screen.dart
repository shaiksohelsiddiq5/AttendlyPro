import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/api_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final rollNo = await StorageService.getRollNo();
      if (rollNo.isEmpty) return;
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/analytics/$rollNo"));
      if (res.statusCode == 200) {
        setState(() {
          _data = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch analytics: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF081426),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final studyTrend = _data['studyHoursTrend'] as List? ?? [];
    final assignments = _data['assignments'] as Map? ?? {"pending": 0, "completed": 0};
    final cgpaTrend = _data['cgpaTrend'] as List? ?? [];
    final attendanceStats = _data['attendanceStats'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF081426),
      appBar: AppBar(
        title: const Text("Analytics Dashboard"),
        backgroundColor: Colors.black54,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAnalytics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Donut Chart for Subject Attendance
            Card(
              color: const Color(0xFF13233D),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Attendance Analysis", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    attendanceStats.isEmpty
                        ? const Center(child: Text("No attendance records to plot", style: TextStyle(color: Colors.white30)))
                        : Row(
                            children: [
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: CustomPaint(
                                  painter: DonutChartPainter(attendanceStats),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: attendanceStats.take(4).map<Widget>((e) {
                                    final pct = e['percentage'] as num? ?? 0.0;
                                    final sub = e['subject']?.toString() ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00BFA5))),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                                          Text("${pct.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )
                            ],
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Study hours trend
            Card(
              color: const Color(0xFF13233D),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Study Hours Trend", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    studyTrend.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Log study goals to display trend", style: TextStyle(color: Colors.white30))))
                        : SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: LineChartPainter(studyTrend.map((e) => (e['hours'] as num? ?? 0.0).toDouble()).toList()),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Assignments Bar Chart
            Card(
              color: const Color(0xFF13233D),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Assignments Workload", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBar("Pending", assignments['pending'] ?? 0, Colors.orange),
                        _buildStatBar("Completed", assignments['completed'] ?? 0, const Color(0xFF00BFA5)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // CGPA Performance Curve
            Card(
              color: const Color(0xFF13233D),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CGPA Growth Curve", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    cgpaTrend.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Log semester results to track CGPA curve", style: TextStyle(color: Colors.white30))))
                        : SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: CurveChartPainter(cgpaTrend.map((e) => (e['gpa'] as num? ?? 0.0).toDouble()).toList()),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, int val, Color color) {
    return Column(
      children: [
        Text("$val", style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}

// Custom Painters for charts
class DonutChartPainter extends CustomPainter {
  final List stats;
  DonutChartPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double thickness = 14;

    final Paint bgPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius - thickness / 2, bgPaint);

    if (stats.isEmpty) return;

    double startAngle = -3.14 / 2;
    final totalAtt = stats.fold(0.0, (sum, e) => sum + (e['attended'] as num? ?? 0.0));
    final totalClass = stats.fold(0.0, (sum, e) => sum + (e['total'] as num? ?? 0.0));
    final double overallPercentage = totalClass == 0 ? 0.0 : totalAtt / totalClass;

    final Paint arcPaint = Paint()
      ..color = const Color(0xFF00BFA5)
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * 3.14 * overallPercentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - thickness / 2),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<double> values;
  LineChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double stepX = size.width / (values.length > 1 ? values.length - 1 : 1);
    final double maxVal = values.fold(1.0, (max, v) => v > max ? v : max);

    final Paint linePaint = Paint()
      ..color = const Color(0xFF9B91FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Paint glowPaint = Paint()
      ..color = const Color(0xFF9B91FF).withOpacity(0.12)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      final double y = size.height - (values[i] / maxVal * size.height * 0.8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CurveChartPainter extends CustomPainter {
  final List<double> values;
  CurveChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double stepX = size.width / (values.length > 1 ? values.length - 1 : 1);
    const double minVal = 0.0;
    const double maxVal = 10.0; // GPA range

    final Paint linePaint = Paint()
      ..color = const Color(0xFF00BFA5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((values[i] - minVal) / (maxVal - minVal) * size.height * 0.8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    // Draw dots
    final Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((values[i] - minVal) / (maxVal - minVal) * size.height * 0.8);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
