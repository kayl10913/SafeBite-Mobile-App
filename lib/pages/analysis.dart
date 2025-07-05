// pages/analysis.dart

import 'package:flutter/material.dart';
import '../services/analytics_service.dart'; // Import the new service
import 'home.dart';
import 'notification.dart';
import 'profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';

// Base URL for the Express backend (use 10.0.2.2 for Android emulator)
const String baseUrl = 'http://10.0.2.2:3000/api';
// Base URL for the Express backend when running on a website or local browser
const String websiteBaseUrl = 'http://localhost:3000/api';

class AnalysisPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const AnalysisPage({super.key, required this.user});
  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  // --- Begin: Copied state from home.dart for sensor activity and food detections ---
  List<String> months = [];
  String selectedMonth = '';

  // Sensor Activity
  int sensorActivityCount = 0;
  bool isLoadingSensor = true;
  String sensorError = '';
  List<Map<String, dynamic>> dailySensorData = [];
  bool isLoadingChart = true;
  String chartError = '';

  // Recent Food Detections
  List<Map<String, dynamic>> recentFoodDetections = [];
  bool isLoadingFood = true;
  String foodError = '';

  // Add at the top of your State class:
  String selectedFilter = 'All';
  final List<String> filterOptions = [
    'All',
    'Monthly/Year',
    'Weekly',
    'Month/Daily',
  ];

  @override
  void initState() {
    super.initState();
    fetchRecentFoodDetections();
    fetchSensorActivity();
    fetchAndSetLatestMonth();
  }

  Future<void> fetchAvailableMonths() async {
    final userId = widget.user['user_id'];
    if (userId == null) return;
    final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
    final response = await http.get(
      Uri.parse('$apiUrl/dashboard/available-months?user_id=$userId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        months = List<String>.from(data['months'].map((m) {
          // Convert '2025-07' to 'Jul 2025'
          final parts = m.split('-');
          final monthNum = int.parse(parts[1]);
          final year = parts[0];
          final monthName = [
            '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ][monthNum];
          return '$monthName $year';
        }));
        if (months.isNotEmpty) selectedMonth = months.first;
      });
    }
  }

  Future<void> fetchRecentFoodDetections() async {
    setState(() {
      isLoadingFood = true;
      foodError = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');
      if (sessionToken == null) {
        setState(() {
          foodError = 'Not logged in';
          isLoadingFood = false;
        });
        return;
      }
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.get(
        Uri.parse('$apiUrl/dashboard/recent-food'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            recentFoodDetections = List<Map<String, dynamic>>.from(data['data']);
            isLoadingFood = false;
          });
        } else {
          setState(() {
            foodError = 'Failed to load food data';
            isLoadingFood = false;
          });
        }
      } else {
        setState(() {
          foodError = 'Server error: ${response.statusCode}';
          isLoadingFood = false;
        });
      }
    } catch (e) {
      setState(() {
        foodError = 'Error: ${e.toString()}';
        isLoadingFood = false;
      });
    }
  }

  Future<void> fetchSensorActivity() async {
    setState(() {
      isLoadingSensor = true;
      sensorError = '';
    });
    try {
      final userId = widget.user['user_id'];
      if (userId == null) {
        setState(() {
          sensorError = 'User ID not found';
          isLoadingSensor = false;
        });
        return;
      }
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final response = await http.get(Uri.parse('$apiUrl/dashboard/sensor-activity?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            sensorActivityCount = data['usage_count'] ?? 0;
            isLoadingSensor = false;
          });
        } else {
          setState(() {
            sensorError = 'Failed to load sensor data';
            isLoadingSensor = false;
          });
        }
      } else {
        setState(() {
          sensorError = 'Server error: ${response.statusCode}';
          isLoadingSensor = false;
        });
      }
    } catch (e) {
      setState(() {
        sensorError = 'Error: ${e.toString()}';
        isLoadingSensor = false;
      });
    }
  }

  String? getStartDateFromReadings() {
    if (recentFoodDetections.isEmpty) return null;
    final sorted = List<Map<String, dynamic>>.from(recentFoodDetections)
      ..sort((a, b) => a['date'].compareTo(b['date']));
    return sorted.first['date'];
  }

  String? getEndDateFromReadings() {
    if (recentFoodDetections.isEmpty) return null;
    final sorted = List<Map<String, dynamic>>.from(recentFoodDetections)
      ..sort((a, b) => a['date'].compareTo(b['date']));
    return sorted.last['date'];
  }

  Future<Map<String, String?>> fetchReadingsDateRange() async {
    final userId = widget.user['user_id'];
    if (userId == null) return {'min': null, 'max': null};
    final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
    final response = await http.get(
      Uri.parse('$apiUrl/dashboard/readings-date-range?user_id=$userId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'min': data['min_date'] as String?,
        'max': data['max_date'] as String?,
      };
    }
    return {'min': null, 'max': null};
  }

  Future<void> fetchDailySensorData() async {
    setState(() {
      isLoadingChart = true;
      chartError = '';
    });
    try {
      final userId = widget.user['user_id'];
      if (userId == null || userId.toString().isEmpty) {
        setState(() {
          chartError = 'User ID not found';
          isLoadingChart = false;
        });
        return;
      }
      // Use recent food detections for date range
      final start = getStartDateFromRecentFoodDetections() ?? '2025-06-01';
      final end = getEndDateFromRecentFoodDetections() ?? '2025-06-30';
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final chartUrl = '$apiUrl/dashboard/sensor-activity?user_id=$userId&start=$start&end=$end&chart=1';
      print('Chart API: $chartUrl');
      final response = await http.get(Uri.parse(chartUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawData = data['data'];
        if (rawData != null && rawData is List) {
          setState(() {
            dailySensorData = List<Map<String, dynamic>>.from(rawData);
            isLoadingChart = false;
          });
        } else {
          setState(() {
            dailySensorData = [];
            chartError = 'No chart data available';
            isLoadingChart = false;
          });
        }
      } else {
        setState(() {
          chartError = 'Server error: ${response.statusCode}';
          isLoadingChart = false;
        });
      }
    } catch (e) {
      setState(() {
        chartError = 'Error: ${e.toString()}';
        isLoadingChart = false;
      });
    }
  }

  Future<void> fetchDailySensorDataForRange(String start, String end) async {
    setState(() {
      isLoadingChart = true;
      chartError = '';
    });
    try {
      final userId = widget.user['user_id'];
      if (userId == null || userId.toString().isEmpty) {
        setState(() {
          chartError = 'User ID not found';
          isLoadingChart = false;
        });
        return;
      }
      final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
      final chartUrl = '$apiUrl/dashboard/sensor-activity?user_id=$userId&start=$start&end=$end&chart=1';
      print('Chart API: $chartUrl');
      final response = await http.get(Uri.parse(chartUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawData = data['data'];
        if (rawData != null && rawData is List) {
          setState(() {
            dailySensorData = List<Map<String, dynamic>>.from(rawData);
            isLoadingChart = false;
          });
        } else {
          setState(() {
            dailySensorData = [];
            chartError = 'No chart data available';
            isLoadingChart = false;
          });
        }
      } else {
        setState(() {
          chartError = 'Server error: ${response.statusCode}';
          isLoadingChart = false;
        });
      }
    } catch (e) {
      setState(() {
        chartError = 'Error: ${e.toString()}';
        isLoadingChart = false;
      });
    }
  }

  String? getStartDateFromRecentFoodDetections() {
    if (recentFoodDetections.isEmpty) return null;
    final sorted = List<Map<String, dynamic>>.from(recentFoodDetections)
      ..sort((a, b) => DateTime.parse(_toIsoDate(a['date'])).compareTo(DateTime.parse(_toIsoDate(b['date']))));
    return _toIsoDate(sorted.first['date']);
  }

  String? getEndDateFromRecentFoodDetections() {
    if (recentFoodDetections.isEmpty) return null;
    final sorted = List<Map<String, dynamic>>.from(recentFoodDetections)
      ..sort((a, b) => DateTime.parse(_toIsoDate(a['date'])).compareTo(DateTime.parse(_toIsoDate(b['date']))));
    return _toIsoDate(sorted.last['date']);
  }

  // Helper to convert 'Jul 3, 2025' or similar to '2025-07-03'
  String _toIsoDate(String dateStr) {
    try {
      // Try ISO first
      return DateTime.parse(dateStr).toIso8601String().substring(0, 10);
    } catch (_) {
      // Try parsing 'Jul 9, 2025'
      try {
        final months = {
          'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
          'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
        };
        final parts = dateStr.replaceAll(',', '').split(' ');
        if (parts.length == 3 && months.containsKey(parts[0])) {
          final month = months[parts[0]]!;
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final dt = DateTime(year, month, day);
          return dt.toIso8601String().substring(0, 10);
        }
      } catch (_) {}
      // Fallback: return as is
      return dateStr;
    }
  }

  // Helper: Get available months from recentFoodDetections
  List<String> getAvailableMonths() {
    final Set<String> monthsSet = {};
    for (var item in recentFoodDetections) {
      final dateStr = _toIsoDate(item['date']);
      final dt = DateTime.parse(dateStr);
      final monthLabel = '${_monthName(dt.month)} ${dt.year}';
      monthsSet.add(monthLabel);
    }
    final monthsList = monthsSet.toList();
    monthsList.sort((a, b) {
      final aParts = a.split(' ');
      final bParts = b.split(' ');
      final aDate = DateTime(int.parse(aParts[1]), _monthNum(aParts[0]));
      final bDate = DateTime(int.parse(bParts[1]), _monthNum(bParts[0]));
      return aDate.compareTo(bDate);
    });
    return monthsList;
  }

  String _monthName(int month) {
    const names = [ '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ];
    return names[month];
  }
  int _monthNum(String name) {
    const names = [ '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ];
    return names.indexOf(name);
  }

  // When user selects a month, fetch chart data for that month
  void onMonthChanged(String monthLabel) {
    setState(() {
      selectedMonth = monthLabel;
    });
    // Parse month and year from label, e.g., 'Jul 2025'
    final parts = monthLabel.split(' ');
    final monthNum = _monthNum(parts[0]);
    final year = int.parse(parts[1]);
    final start = DateTime(year, monthNum, 1).toIso8601String().substring(0, 10);
    final end = DateTime(year, monthNum + 1, 0).toIso8601String().substring(0, 10);
    fetchDailySensorDataForRange(start, end);
  }

  Future<void> fetchAndSetLatestMonth() async {
    final userId = widget.user['user_id'];
    if (userId == null) return;
    final apiUrl = kIsWeb ? websiteBaseUrl : baseUrl;
    final response = await http.get(
      Uri.parse('$apiUrl/dashboard/readings-date-range?user_id=$userId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final maxDate = data['max_date']; // e.g., "2025-07-03"
      if (maxDate != null) {
        final dt = DateTime.parse(maxDate);
        final monthLabel = '${_monthName(dt.month)} ${dt.year}';
        setState(() {
          selectedMonth = monthLabel;
        });
        // Now fetch chart data for this month:
        final start = DateTime(dt.year, dt.month, 1).toIso8601String().substring(0, 10);
        final end = DateTime(dt.year, dt.month + 1, 0).toIso8601String().substring(0, 10);
        fetchDailySensorDataForRange(start, end);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3C6E0), // Softer blue background
      appBar: AppBar(
        title: const Text('Analysis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: const Color(0xFF0B1739),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _aiAnalyzerSummaryBoxStatic(),
              const SizedBox(height: 28),

              const SizedBox(height: 16),
              _sensorActivityChart(),
              const SizedBox(height: 28),
              _foodRiskChart({}), // Keep as placeholder, or remove if not needed
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  'Recent Food Detections',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0B1739)),
                ),
              ),
              _recentFoodDetectionsTable(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B1739),
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: const Color(0xFF80848F),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => SafeBiteHomePage(user: widget.user)),
            );
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => NotificationPage(user: widget.user)),
            );
          } else if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => ProfilePage(user: widget.user)),
            );
          }
        },
      ),
    );
  }

  // Static AI Analyzer box (no data)
  Widget _aiAnalyzerSummaryBoxStatic() {
    return Card(
      color: const Color(0xFF3B4371), // Prominent purple/blue
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.white.withOpacity(0.8), size: 28),
                const SizedBox(width: 10),
                const Text('AI Analyzer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'The analysis dashboard for June 2025 shows a noticeable increase in sensor activity, rising by 10%, likely indicating heightened monitoring or system engagement, while simultaneously, food risk dropped sharply by 50%, which could suggest improved safety protocols or environmental conditions. This inverse relationship between higher detection efforts and declining risk levels hints at effective interventions or optimizations—possibly stronger monitoring helping to mitigate potential hazards.',
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorActivityChart() {
    final score = 0;
    final change = 0;
    return Card(
      color: const Color(0xFF19233C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.sensors, color: Colors.white70, size: 20),
                    const SizedBox(width: 6),
                    const Text(
                      'Sensor activity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 18),
                  label: Text(
                    selectedMonth,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  onPressed: () {
                    // Show your month picker or dropdown here
                    // You can use showModalBottomSheet or a custom month picker dialog
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Usage Count: ', style: TextStyle(color: Colors.white70)),
                if (isLoadingSensor)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                else if (sensorError.isNotEmpty)
                  Text(sensorError, style: const TextStyle(color: Colors.redAccent, fontSize: 12))
                else
                  Text('$sensorActivityCount', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF181A20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: isLoadingChart
                  ? const Center(child: CircularProgressIndicator())
                  : chartError.isNotEmpty
                      ? Center(child: Text(chartError, style: const TextStyle(color: Colors.red)))
                      : dailySensorData.isEmpty
                          ? const Center(child: Text('No data', style: TextStyle(color: Colors.white54)))
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: 1,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return const FlLine(
                                        color: Color(0xff37434d),
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return const FlLine(
                                        color: Color(0xff37434d),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          int dayIdx = value.toInt();
                                          final daysInMonth = DateTime(int.parse(selectedMonth.split(' ')[1]), _monthNum(selectedMonth.split(' ')[0]) + 1, 0).day;
                                          if (dayIdx < 1 || dayIdx > daysInMonth) return const SizedBox.shrink();
                                          if (dayIdx == 1 || dayIdx == daysInMonth || dayIdx % 5 == 0) {
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                dayIdx.toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            value.toInt().toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                        reservedSize: 42,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: const Color(0xff37434d)),
                                  ),
                                  minX: 1,
                                  maxX: DateTime(int.parse(selectedMonth.split(' ')[1]), _monthNum(selectedMonth.split(' ')[0]) + 1, 0).day.toDouble(),
                                  minY: 0,
                                  maxY: dailySensorData.isNotEmpty
                                      ? dailySensorData.map((e) => (e['count'] as num).toDouble()).reduce((a, b) => a > b ? a : b) + 1
                                      : 1,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: getSpots(),
                                      isCurved: true,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xff23b6e6), Color(0xff02d39a)],
                                      ),
                                      barWidth: 5,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xff23b6e6).withOpacity(0.3),
                                            const Color(0xff02d39a).withOpacity(0.3),
              ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodRiskChart(Map<String, dynamic> data) {
    // Defensive: If selectedMonth is empty or invalid, show no data
    if (selectedMonth.isEmpty || !selectedMonth.contains(' ')) {
      return Card(
        color: const Color(0xFF19233C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        child: const SizedBox(
          height: 180,
          child: Center(child: Text('No data', style: TextStyle(color: Colors.white54))),
        ),
      );
    }
    // Get month/year from selectedMonth
    final parts = selectedMonth.split(' ');
    final monthNum = _monthNum(parts[0]);
    final year = int.parse(parts[1]);
    final daysInMonth = DateTime(year, monthNum + 1, 0).day;
    // Aggregate food risk data by date for both statuses
    final Map<String, int> spoiltCounts = {};
    final Map<String, int> warningCounts = {};
    for (var item in recentFoodDetections) {
      final status = item['status'] ?? '';
      final date = _toIsoDate(item['date']);
      if (status == 'Spoilt') {
        spoiltCounts[date] = (spoiltCounts[date] ?? 0) + 1;
      } else if (status == 'Spoilt warning') {
        warningCounts[date] = (warningCounts[date] ?? 0) + 1;
      }
    }
    // Build spots for each day of the month
    final spoiltSpots = <FlSpot>[];
    final warningSpots = <FlSpot>[];
    for (int d = 1; d <= daysInMonth; d++) {
      final dateStr = DateTime(year, monthNum, d).toIso8601String().substring(0, 10);
      spoiltSpots.add(FlSpot(d.toDouble(), spoiltCounts[dateStr]?.toDouble() ?? 0));
      warningSpots.add(FlSpot(d.toDouble(), warningCounts[dateStr]?.toDouble() ?? 0));
    }
    // Calculate score and change
    final int totalRisky = spoiltCounts.values.fold(0, (a, b) => a + b) + warningCounts.values.fold(0, (a, b) => a + b);
    int prevMonthRisky = 0;
    if (monthNum > 1) {
      final prevMonth = monthNum - 1;
      final prevDays = DateTime(year, prevMonth + 1, 0).day;
      for (int d = 1; d <= prevDays; d++) {
        final dateStr = DateTime(year, prevMonth, d).toIso8601String().substring(0, 10);
        prevMonthRisky += (spoiltCounts[dateStr] ?? 0) + (warningCounts[dateStr] ?? 0);
      }
    }
    final int change = prevMonthRisky == 0 ? 0 : (((totalRisky - prevMonthRisky) / prevMonthRisky) * 100).round();
    return Card(
      color: const Color(0xFF19233C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Food Risk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    backgroundColor: const Color(0xFF232B3E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 18),
                  label: Text(
                    selectedMonth,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  onPressed: () {
                    // Show month picker or do nothing for now
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF181A20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: spoiltSpots.isEmpty && warningSpots.isEmpty
                  ? const Center(child: Text('No data', style: TextStyle(color: Colors.white54)))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: 1,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return const FlLine(
                                color: Color(0xff37434d),
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return const FlLine(
                                color: Color(0xff37434d),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  int dayIdx = value.toInt();
                                  if (dayIdx < 1 || dayIdx > daysInMonth) return const SizedBox.shrink();
                                  if (dayIdx == 1 || dayIdx == daysInMonth || dayIdx % 5 == 0) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        dayIdx.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                reservedSize: 32,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: const Color(0xff37434d)),
                          ),
                          minX: 1,
                          maxX: daysInMonth.toDouble(),
                          minY: 0,
                          maxY: [
                            ...spoiltSpots.map((e) => e.y),
                            ...warningSpots.map((e) => e.y),
                          ].fold<double>(0, (prev, e) => e > prev ? e : prev) + 1,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spoiltSpots,
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [Color(0xffe63946), Color(0xffe63946)],
                              ),
                              barWidth: 5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xffe63946).withOpacity(0.3),
                                    const Color(0xffe63946).withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                            LineChartBarData(
                              spots: warningSpots,
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [Color(0xffffc300), Color(0xffffc300)],
                              ),
                              barWidth: 5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xffffc300).withOpacity(0.3),
                                    const Color(0xffffc300).withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Score: $totalRisky', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 6),
                Text('$change%', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentFoodDetectionsTable() {
    final statusColors = {
      'Good': Colors.green,
      'Spoilt': Colors.red,
      'Spoilt warning': Colors.yellow,
    };
    return Card(
      color: const Color(0xFF19233C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(child: Text('Food', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15))),
                Expanded(child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15))),
                Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15))),
              ],
            ),
            const Divider(color: Colors.white12, thickness: 1, height: 18),
            if (isLoadingFood)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
              )
            else if (foodError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: Text(foodError, style: const TextStyle(color: Colors.redAccent)),
              )
            else if (recentFoodDetections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: Text('No recent food detections', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
              )
            else ...recentFoodDetections.map((item) {
              final food = item['food'] ?? 'N/A';
              final date = item['date'] ?? 'N/A';
              final status = item['status'] ?? 'N/A';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(child: Text(food, style: const TextStyle(color: Colors.white, fontSize: 14))),
                    Expanded(child: Text(date, style: const TextStyle(color: Colors.white, fontSize: 14))),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: statusColors[status] ?? Colors.grey, size: 11),
                          const SizedBox(width: 6),
                          Text(status, style: TextStyle(color: statusColors[status] ?? Colors.grey, fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  List<FlSpot> getSpots() {
    final parts = selectedMonth.split(' ');
    final monthNum = _monthNum(parts[0]);
    final year = int.parse(parts[1]);
    final Map<int, double> dayToValue = {};
    for (int i = 0; i < dailySensorData.length; i++) {
      final date = dailySensorData[i]['date'];
      final dt = DateTime.parse(date);
      if (dt.month == monthNum && dt.year == year) {
        dayToValue[dt.day] = (dailySensorData[i]['count'] as num).toDouble();
      }
    }
    final daysInMonth = DateTime(year, monthNum + 1, 0).day;
    return [
      for (int d = 1; d <= daysInMonth; d++)
        FlSpot(d.toDouble(), dayToValue[d] ?? 0)
    ];
  }

  // Helper for week number:
  String weekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final diff = date.difference(firstMonday).inDays;
    return ((diff / 7).ceil() + 1).toString();
  }
}