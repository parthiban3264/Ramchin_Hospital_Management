import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({
    super.key,
    required this.hospitalId,
    required this.doctorId,
  });

  final int hospitalId;
  final String doctorId;

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final List<Color> gradientColors = [Colors.cyan, Colors.blue];
  late final List<FlSpot> weeklyData; // Stable data (no redraw flicker)

  @override
  void initState() {
    super.initState();
    weeklyData = getSpots();
  }

  // Dummy graph data
  List<FlSpot> getSpots() {
    final Random random = Random();
    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), (random.nextInt(20) + 5).toDouble());
    });
  }

  // Bottom axis labels
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    Widget text = const SizedBox.shrink();
    if (value.toInt() >= 0 && value.toInt() < days.length) {
      text = Text(days[value.toInt()], style: style);
    }

    return SideTitleWidget(axisSide: meta.axisSide, space: 8, child: text);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // === Summary Cards ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildContainer(
                    title: 'Patients\nWaiting On\nQueue',
                    value: '8',
                    icon: Icons.access_time,
                    color: Colors.orange,
                  ),
                  buildContainer(
                    title: 'Patients\nUnder\nTreatment',
                    value: '10',
                    icon: Icons.local_hospital,
                    color: Colors.blue,
                  ),
                  buildContainer(
                    title: 'Treated\nPatients\n',
                    value: '25',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(indent: 16, endIndent: 16),

              // === Weekly Chart ===
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Patient Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
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
                                getTitlesWidget: bottomTitleWidgets,
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 10,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: const Color(0xff37434d),
                              width: 1,
                            ),
                          ),
                          minX: 0,
                          maxX: 6,
                          minY: 0,
                          maxY: 30,
                          lineBarsData: [
                            LineChartBarData(
                              spots: weeklyData,
                              isCurved: true,
                              gradient: LinearGradient(colors: gradientColors),
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: gradientColors
                                      .map(
                                        (color) => color.withValues(alpha: 0.3),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === Reusable Stat Container ===
  Widget buildContainer({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.4, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
