import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hospitrax/Services/prescription_service.dart';

class PatientAnalyticsScreen extends StatefulWidget {
  final int consultationId;

  const PatientAnalyticsScreen({super.key, required this.consultationId});

  @override
  State<PatientAnalyticsScreen> createState() => _PatientAnalyticsScreenState();
}

class _PatientAnalyticsScreenState extends State<PatientAnalyticsScreen> {
  final PrescriptionService _service = PrescriptionService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getStatusAnalysis(widget.consultationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// Back Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  /// Title Section
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Inpatient Analytics",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Adherence Dashboard",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  /// Refresh Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _future = _service.getStatusAnalysis(
                          widget.consultationId,
                        );
                      });
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final summary = data["summary"];
          final slotWise = data["slotWise"];
          final records = List<Map<String, dynamic>>.from(
            data["records"] ?? [],
          );

          final taken = summary["taken"] ?? 0;
          final missed = summary["missed"] ?? 0;

          double adherence = (taken + missed) == 0
              ? 0
              : (taken / (taken + missed)) * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryCards(summary),
                const SizedBox(height: 25),

                _buildAdherenceGauge(adherence),
                const SizedBox(height: 30),

                _buildDonutChart(summary),
                const SizedBox(height: 30),

                _buildSlotStackedBar(slotWise),
                const SizedBox(height: 30),

                _buildTrendLine(records),
                const SizedBox(height: 30),

                _buildMedicineBar(records),
                const SizedBox(height: 30),

                _buildTimeline(records),
              ],
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // PREMIUM SUMMARY CARDS
  // =====================================================

  Widget _buildSummaryCards(Map summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _card("Total", summary["total"], Colors.blue),
        _card("Taken", summary["taken"], Colors.green),
        _card("Missed", summary["missed"], Colors.red),
        _card("Pending", summary["pending"], Colors.orange),
      ],
    );
  }

  Widget _card(String title, dynamic value, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$value",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // =====================================================
  // ADHERENCE GAUGE
  // =====================================================

  Widget _buildAdherenceGauge(double percentage) {
    percentage = percentage.clamp(0, 100);

    Color riskColor;
    String riskLabel;

    if (percentage >= 80) {
      riskColor = Colors.green;
      riskLabel = "Low Risk";
    } else if (percentage >= 60) {
      riskColor = Colors.orange;
      riskLabel = "Moderate Risk";
    } else {
      riskColor = Colors.red;
      riskLabel = "High Risk";
    }

    return _sectionCard(
      "Adherence Risk Gauge ⭐",
      Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Background Arc
                PieChart(
                  PieChartData(
                    startDegreeOffset: 180,
                    sectionsSpace: 0,
                    centerSpaceRadius: 70,
                    sections: [
                      PieChartSectionData(
                        value: 100,
                        color: Colors.grey.shade200,
                        radius: 20,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),

                /// Foreground Arc
                PieChart(
                  PieChartData(
                    startDegreeOffset: 180,
                    sectionsSpace: 0,
                    centerSpaceRadius: 70,
                    sections: [
                      PieChartSectionData(
                        value: percentage,
                        color: riskColor,
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 100 - percentage,
                        color: Colors.transparent,
                        radius: 20,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),

                /// Center Text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${percentage.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      riskLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: riskColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// Risk Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _RiskDot(color: Colors.green, label: "≥ 80%"),
              _RiskDot(color: Colors.orange, label: "60–79%"),
              _RiskDot(color: Colors.red, label: "< 60%"),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DONUT CHART
  // =====================================================

  Widget _buildDonutChart(Map summary) {
    final double taken = (summary["taken"] ?? 0).toDouble();
    final double missed = (summary["missed"] ?? 0).toDouble();
    final double pending = (summary["pending"] ?? 0).toDouble();

    final double total = taken + missed + pending;

    double percent(double value) => total == 0 ? 0 : (value / total) * 100;

    return _sectionCard(
      "Status Distribution",
      Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Donut Chart
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 65,
                    sections: [
                      PieChartSectionData(
                        value: taken,
                        color: Colors.green,
                        showTitle: false,
                        radius: 25,
                      ),
                      PieChartSectionData(
                        value: missed,
                        color: Colors.red,
                        showTitle: false,
                        radius: 25,
                      ),
                      PieChartSectionData(
                        value: pending,
                        color: Colors.orange,
                        showTitle: false,
                        radius: 25,
                      ),
                    ],
                  ),
                ),

                /// Center Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      total.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Total Records",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(Colors.green, "Taken", percent(taken)),
              _legendItem(Colors.red, "Missed", percent(missed)),
              _legendItem(Colors.orange, "Pending", percent(pending)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, double percentage) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "${percentage.toStringAsFixed(1)}%",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // =====================================================
  // SLOT 100% STACKED BAR
  // =====================================================

  Widget _buildSlotStackedBar(Map slotWise) {
    const slots = ["MORNING", "AFTERNOON", "NIGHT"];

    return _sectionCard(
      "Slot-wise 100% Adherence",
      Column(
        children: [
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                maxY: 100,
                alignment: BarChartAlignment.spaceAround,

                /// Touch Tooltip
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final slot = slots[group.x.toInt()];
                      final data = slotWise[slot] ?? {};

                      final taken = (data["taken"] ?? 0).toDouble();
                      final missed = (data["missed"] ?? 0).toDouble();
                      final pending = (data["pending"] ?? 0).toDouble();
                      final total = taken + missed + pending;

                      if (total == 0) {
                        return BarTooltipItem(
                          "No Data Available",
                          TextStyle(color: Colors.white),
                        );
                      }

                      return BarTooltipItem(
                        "$slot\n"
                        "Taken: ${(taken / total * 100).toStringAsFixed(1)}%\n"
                        "Missed: ${(missed / total * 100).toStringAsFixed(1)}%\n"
                        "Pending: ${(pending / total * 100).toStringAsFixed(1)}%",
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),

                /// Grid Styling
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),

                /// Axis Titles
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, meta) => Text(
                        "${value.toInt()}%",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ["Morning", "Afternoon", "Night"];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[value.toInt()],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                borderData: FlBorderData(show: false),

                /// Bars
                barGroups: List.generate(
                  slots.length,
                  (index) => _slotGroup(index, slotWise[slots[index]] ?? {}),
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 700),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),

          const SizedBox(height: 20),

          /// Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _SlotLegend(color: Color(0xFF4CAF50), label: "Taken"),
              _SlotLegend(color: Color(0xFFE53935), label: "Missed"),
              _SlotLegend(color: Color(0xFFFFA726), label: "Pending"),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _slotGroup(int x, Map data) {
    final taken = (data["taken"] ?? 0).toDouble();
    final missed = (data["missed"] ?? 0).toDouble();
    final pending = (data["pending"] ?? 0).toDouble();

    final total = taken + missed + pending;

    /// Show subtle placeholder if empty
    if (total == 0) {
      return BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: 100,
            width: 26,
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
        ],
      );
    }

    final takenPercent = (taken / total) * 100;
    final missedPercent = (missed / total) * 100;
    final pendingPercent = (pending / total) * 100;

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: 100,
          width: 26,
          borderRadius: BorderRadius.circular(8),
          rodStackItems: [
            BarChartRodStackItem(0, takenPercent, const Color(0xFF4CAF50)),
            BarChartRodStackItem(
              takenPercent,
              takenPercent + missedPercent,
              const Color(0xFFE53935),
            ),
            BarChartRodStackItem(
              takenPercent + missedPercent,
              100,
              const Color(0xFFFFA726),
            ),
          ],
        ),
      ],
    );
  }

  // =====================================================
  // MEDICINE WISE BAR (REAL DATA)
  // =====================================================

  Widget _buildMedicineBar(List records) {
    final Map<String, int> medicineCount = {};

    for (var r in records) {
      final name = r["medicine_name"] ?? "Unknown";
      medicineCount[name] = (medicineCount[name] ?? 0) + 1;
    }

    final medicines = medicineCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (medicines.isEmpty) {
      return _sectionCard(
        "Medicine-wise Usage",
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              "No Medicine Data Available",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final total = medicines.fold<int>(0, (sum, e) => sum + e.value);

    return _sectionCard(
      "Medicine-wise Usage",
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: medicines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final medicine = medicines[index];
          final percent = (medicine.value / total) * 100;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top Row (Name + Count + Rank)
              Row(
                children: [
                  /// Rank badge
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == 0 ? Colors.green : Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: index == 0 ? Colors.white : Colors.blue.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      medicine.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Text(
                    "${medicine.value} doses",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// Progress Bar
              Stack(
                children: [
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percent / 100,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: index == 0
                              ? [
                                  const Color(0xFF43A047),
                                  const Color(0xFF2E7D32),
                                ]
                              : [
                                  const Color(0xFF64B5F6),
                                  const Color(0xFF1E88E5),
                                ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              /// Percentage text
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "${percent.toStringAsFixed(1)}%",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =====================================================
  // 7 DAY TREND LINE (REAL DATA)
  // =====================================================

  Widget _buildTrendLine(List records) {
    final Map<String, int> dailyTaken = {};

    /// Generate last 7 days (fixed calendar days)
    final today = DateTime.now();
    final last7Days = List.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day - (6 - i)),
    );

    /// Initialize with zero values
    for (var day in last7Days) {
      final key = DateFormat("yyyy-MM-dd").format(day);
      dailyTaken[key] = 0;
    }

    /// Count TAKEN records
    for (var r in records) {
      final rawDate = r["date"];
      if (rawDate == null) continue;

      final formatted = DateFormat(
        "yyyy-MM-dd",
      ).format(DateTime.parse(rawDate));

      if (dailyTaken.containsKey(formatted) && r["status"] == "TAKEN") {
        dailyTaken[formatted] = (dailyTaken[formatted] ?? 0) + 1;
      }
    }

    final sortedDates = dailyTaken.keys.toList()..sort();

    /// Convert to spots
    final List<FlSpot> spots = [];
    double total = 0;

    for (int i = 0; i < sortedDates.length; i++) {
      final value = dailyTaken[sortedDates[i]]!.toDouble();
      total += value;
      spots.add(FlSpot(i.toDouble(), value));
    }

    final avg = total / spots.length;

    final highest = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    /// Better rounded maxY
    final maxY = (highest + 2).ceilToDouble();

    /// Dynamic interval
    final interval = (maxY / 4).ceilToDouble();

    return _sectionCard(
      "7-Day Medication Trend",
      SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,

            /// Subtle background shading (Low Zone)
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                HorizontalRangeAnnotation(
                  y1: 0,
                  y2: avg * 0.6,
                  color: Colors.red.withOpacity(0.05),
                ),
              ],
            ),

            /// Cleaner grid
            gridData: FlGridData(
              show: true,
              horizontalInterval: interval,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),

            /// Axis titles
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= sortedDates.length) {
                      return const SizedBox();
                    }

                    final date = DateTime.parse(sortedDates[value.toInt()]);
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat("E").format(date), // Mon Tue Wed
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),

            borderData: FlBorderData(show: false),

            /// Tooltip (cleaner format)
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.all(10),
                getTooltipColor: (_) => Colors.black87,
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    final date = sortedDates[spot.x.toInt()];
                    return LineTooltipItem(
                      "${DateFormat("MMM dd").format(DateTime.parse(date))}\n"
                      "Taken: ${spot.y.toInt()}",
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),

            /// Average reference line
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: avg,
                  color: Colors.orange.shade100,
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.centerRight,
                    labelResolver: (_) => "Avg ${avg.toStringAsFixed(1)}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ),
              ],
            ),

            /// Main line
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                color: const Color(0xFF0D47A1),

                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: spot.y < avg
                          ? Colors.red
                          : const Color(0xFF0D47A1),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),

                /// Premium gradient fill
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF42A5F5).withOpacity(0.4),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),

          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutQuart,
        ),
      ),
    );
  }

  // =====================================================
  // REAL TIMELINE
  // =====================================================

  Widget _buildTimeline(List records) {
    if (records.isEmpty) {
      return _sectionCard(
        "Record Timeline",
        const Center(child: Text("No Records Found")),
      );
    }

    // Sort latest first
    records.sort(
      (a, b) => DateTime.parse(b["date"]).compareTo(DateTime.parse(a["date"])),
    );

    return _sectionCard(
      "Record Timeline",
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final r = records[index];

          final date = DateTime.parse(r["date"]);
          final formattedDate = DateFormat("dd MMM yyyy").format(date);
          final formattedTime = DateFormat("hh:mm a").format(date);

          final status = r["status"];

          Color statusColor;
          IconData statusIcon;

          switch (status) {
            case "TAKEN":
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              break;
            case "MISSED":
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
              break;
            default:
              statusColor = Colors.orange;
              statusIcon = Icons.hourglass_bottom;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Timeline Line + Icon
              Column(
                children: [
                  Icon(statusIcon, color: statusColor, size: 26),
                  if (index != records.length - 1)
                    Container(
                      width: 2,
                      height: 60,
                      color: Colors.grey.shade300,
                    ),
                ],
              ),

              const SizedBox(width: 12),

              /// Content Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r["medicine_name"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Dose: ${r["dose"]} • ${r["time_slot"]}",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =====================================================
  // COMMON CARD WRAPPER
  // =====================================================

  Widget _sectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Top Header Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),

          /// Content Area
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _RiskDot extends StatelessWidget {
  final Color color;
  final String label;

  const _RiskDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SlotLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _SlotLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
