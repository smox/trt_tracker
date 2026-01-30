import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trt_tracker/data/models/lab_result_model.dart';
import 'package:trt_tracker/data/models/enums.dart'; // Für MassUnit
import 'package:trt_tracker/logic/calculator.dart';
import 'package:trt_tracker/logic/providers.dart';
import 'package:trt_tracker/logic/ui_logic.dart';

enum AnalysisRange { oneWeek, oneMonth, threeMonths, sixMonths, oneYear }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalysisRange _selectedRange = AnalysisRange.oneWeek;
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
  }

  Duration _getRangeDuration() {
    switch (_selectedRange) {
      case AnalysisRange.oneWeek:
        return const Duration(days: 7);
      case AnalysisRange.oneMonth:
        return const Duration(days: 30);
      case AnalysisRange.threeMonths:
        return const Duration(days: 90);
      case AnalysisRange.sixMonths:
        return const Duration(days: 180);
      case AnalysisRange.oneYear:
        return const Duration(days: 365);
    }
  }

  Duration _getScrollStep() {
    switch (_selectedRange) {
      case AnalysisRange.oneWeek:
        return const Duration(days: 1);
      case AnalysisRange.oneMonth:
        return const Duration(days: 7);
      case AnalysisRange.threeMonths:
      case AnalysisRange.sixMonths:
      case AnalysisRange.oneYear:
        return const Duration(days: 30);
    }
  }

  bool _shouldShowRange(AnalysisRange range, DateTime therapyStart) {
    final daysSinceStart = DateTime.now().difference(therapyStart).inDays;
    switch (range) {
      case AnalysisRange.oneWeek:
      case AnalysisRange.oneMonth:
        return true;
      case AnalysisRange.threeMonths:
        return daysSinceStart >= 60;
      case AnalysisRange.sixMonths:
        return daysSinceStart >= 150;
      case AnalysisRange.oneYear:
        return daysSinceStart >= 300;
    }
  }

  void _moveView(int direction) {
    setState(() {
      final step = _getScrollStep();
      if (direction > 0)
        _focusedDate = _focusedDate.add(step);
      else
        _focusedDate = _focusedDate.subtract(step);
    });
  }

  void _resetView() {
    setState(() => _focusedDate = DateTime.now());
  }

  List<FlSpot> _generateChartData(
    dynamic injections,
    dynamic userProfile,
    List<LabResultModel> calibrationPoints,
    DateTime start,
    DateTime end,
  ) {
    if (injections == null || userProfile == null) return [];
    final calculator = TestosteroneCalculator();
    List<FlSpot> spots = [];

    int hoursStep = 6;
    if (_selectedRange == AnalysisRange.oneYear) hoursStep = 24;
    if (_selectedRange == AnalysisRange.oneWeek) hoursStep = 2;

    final totalHours = end.difference(start).inHours;

    for (int i = 0; i <= totalHours; i += hoursStep) {
      final targetTime = start.add(Duration(hours: i));
      double finalLevel = calculator.calculateLevelAt(
        targetTime: targetTime,
        injections: injections,
        userProfile: userProfile,
        calibrationPoints: calibrationPoints,
      );
      double displayLevel = TestosteroneCalculator.convertFromNormalized(
        finalLevel,
        userProfile.preferredUnit,
      );
      spots.add(
        FlSpot(targetTime.millisecondsSinceEpoch.toDouble(), displayLevel),
      );
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final injections = ref.watch(injectionListProvider).value ?? [];
    final userProfile = ref.watch(userProfileProvider).value;
    final calibrationPoints = ref.watch(calibrationPointsProvider).value ?? [];

    final unitLabel =
        userProfile?.preferredUnit
            .toString()
            .split('.')
            .last
            .replaceAll('_', '/') ??
        '';
    final userUnit = userProfile?.preferredUnit ?? MassUnit.ng_ml;

    // Therapy Start
    DateTime therapyStart;
    if (injections.isNotEmpty) {
      final oldest = injections.reduce(
        (a, b) => a.timestamp.isBefore(b.timestamp) ? a : b,
      );
      therapyStart = oldest.timestamp;
    } else {
      therapyStart = DateTime.fromMillisecondsSinceEpoch(
        userProfile?.therapyStart ?? DateTime.now().millisecondsSinceEpoch,
      );
    }

    final rangeDuration = _getRangeDuration();
    final halfDuration = Duration(
      milliseconds: rangeDuration.inMilliseconds ~/ 2,
    );
    final start = _focusedDate.subtract(halfDuration);
    final end = _focusedDate.add(halfDuration);

    final allSpots = _generateChartData(
      injections,
      userProfile,
      calibrationPoints,
      start,
      end,
    );
    final nowMillis = DateTime.now().millisecondsSinceEpoch.toDouble();
    List<FlSpot> pastSpots = [];
    List<FlSpot> futureSpots = [];
    FlSpot? connectionSpot;

    for (var spot in allSpots) {
      if (spot.x <= nowMillis) {
        pastSpots.add(spot);
        connectionSpot = spot;
      } else {
        if (futureSpots.isEmpty && connectionSpot != null)
          futureSpots.add(connectionSpot);
        futureSpots.add(spot);
      }
    }

    // --- RANGES ANPASSEN ---
    // Wir konvertieren die Referenzwerte (300 und 1100 ng/dL) in die User-Einheit
    double minRef = TestosteroneCalculator.convertFromNormalized(300, userUnit);
    double maxRef = TestosteroneCalculator.convertFromNormalized(
      1100,
      userUnit,
    );

    double maxY = maxRef;
    if (allSpots.isNotEmpty) {
      for (var spot in allSpots) {
        if (spot.y > maxY) maxY = spot.y;
      }
      maxY = maxY * 1.1; // 10% Padding oben
    }
    double minY = 0.0;

    String headerDateText;
    if (_selectedRange == AnalysisRange.oneWeek) {
      headerDateText =
          "${DateFormat('d. MMM').format(start)} - ${DateFormat('d. MMM').format(end)}";
    } else {
      headerDateText = DateFormat('MMMM yyyy', 'de_DE').format(_focusedDate);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Analyse & Verlauf"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _resetView,
            tooltip: "Zurück zu Heute",
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _moveView(-1),
                  icon: const Icon(Icons.chevron_left, color: Colors.white70),
                ),
                Text(
                  headerDateText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: () => _moveView(1),
                  icon: const Icon(Icons.chevron_right, color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRangeButton("1W", AnalysisRange.oneWeek, therapyStart),
                  _buildRangeButton("1M", AnalysisRange.oneMonth, therapyStart),
                  if (_shouldShowRange(AnalysisRange.threeMonths, therapyStart))
                    _buildRangeButton(
                      "3M",
                      AnalysisRange.threeMonths,
                      therapyStart,
                    ),
                  if (_shouldShowRange(AnalysisRange.sixMonths, therapyStart))
                    _buildRangeButton(
                      "6M",
                      AnalysisRange.sixMonths,
                      therapyStart,
                    ),
                  if (_shouldShowRange(AnalysisRange.oneYear, therapyStart))
                    _buildRangeButton(
                      "1J",
                      AnalysisRange.oneYear,
                      therapyStart,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                right: 24.0,
                left: 12.0,
                bottom: 12.0,
              ),
              child:
                  allSpots.isEmpty
                      ? const Center(
                        child: Text(
                          "Keine Daten verfügbar",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval:
                                (maxY - minY) / 4, // Dynamisches Grid
                            getDrawingHorizontalLine:
                                (_) => const FlLine(
                                  color: Colors.white10,
                                  strokeWidth: 1,
                                ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                // Interval dynamisch basierend auf der Höhe
                                interval: (maxY - minY) / 4,
                                getTitlesWidget: (value, meta) {
                                  if (value < 0) return const SizedBox();
                                  // Hier eventuell auch formatieren
                                  return Text(
                                    value
                                        .toInt()
                                        .toString(), // Y-Achse darf ganze Zahlen bleiben oder value.toStringAsFixed(1)
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: _getXInterval(start, end),
                                getTitlesWidget: (value, meta) {
                                  final date =
                                      DateTime.fromMillisecondsSinceEpoch(
                                        value.toInt(),
                                      );
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('dd.MM.').format(date),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: start.millisecondsSinceEpoch.toDouble(),
                          maxX: end.millisecondsSinceEpoch.toDouble(),
                          minY: minY,
                          maxY: maxY,
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: minRef, // Dynamisch berechnet!
                                color: Colors.red.withOpacity(0.3),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 9,
                                  ),
                                  labelResolver: (_) => "Min",
                                ),
                              ),
                              HorizontalLine(
                                y: maxRef, // Dynamisch berechnet!
                                color: TRTColors.supra.withOpacity(0.3),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.bottomRight,
                                  style: TextStyle(
                                    color: TRTColors.supra,
                                    fontSize: 9,
                                  ),
                                  labelResolver: (_) => "Max",
                                ),
                              ),
                            ],
                            verticalLines: [
                              if (nowMillis >= start.millisecondsSinceEpoch &&
                                  nowMillis <= end.millisecondsSinceEpoch)
                                VerticalLine(
                                  x: nowMillis,
                                  color: Colors.white.withOpacity(0.8),
                                  strokeWidth: 2,
                                  dashArray: [5, 5],
                                  label: VerticalLineLabel(
                                    show: true,
                                    alignment: Alignment.topLeft,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    labelResolver: (_) => "Jetzt",
                                  ),
                                ),
                            ],
                          ),
                          lineBarsData: [
                            if (pastSpots.isNotEmpty)
                              LineChartBarData(
                                spots: pastSpots,
                                isCurved: true,
                                color: const Color(0xFF64FFDA),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF64FFDA).withOpacity(0.3),
                                      const Color(0xFF64FFDA).withOpacity(0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            if (futureSpots.isNotEmpty)
                              LineChartBarData(
                                spots: futureSpots,
                                isCurved: true,
                                color: const Color(0xFF64FFDA).withOpacity(0.6),
                                barWidth: 1.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                              ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => const Color(0xFF1E1E1E),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((
                                  LineBarSpot touchedSpot,
                                ) {
                                  final textStyle = TextStyle(
                                    color:
                                        touchedSpot.bar.color ??
                                        Colors.blueGrey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  );
                                  // TOOLTIP AUF 2 STELLEN
                                  return LineTooltipItem(
                                    '${touchedSpot.y.toStringAsFixed(2)} $unitLabel \n${DateFormat('dd.MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt()))}',
                                    textStyle,
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
            ),
          ),
          SafeArea(top: false, child: _buildStatsFooter(allSpots, unitLabel)),
        ],
      ),
    );
  }

  double _getXInterval(DateTime start, DateTime end) {
    final diffDays = end.difference(start).inDays;
    if (diffDays <= 7) return 1 * 24 * 3600 * 1000;
    if (diffDays <= 30) return 5 * 24 * 3600 * 1000;
    if (diffDays <= 90) return 15 * 24 * 3600 * 1000;
    return 30 * 24 * 3600 * 1000;
  }

  Widget _buildRangeButton(
    String text,
    AnalysisRange range,
    DateTime therapyStart,
  ) {
    final isSelected = _selectedRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRange = range;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF64FFDA) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsFooter(List<FlSpot> spots, String unit) {
    if (spots.isEmpty) return const SizedBox();
    double min = double.infinity;
    double max = double.negativeInfinity;
    double sum = 0;
    int count = 0;
    for (var spot in spots) {
      if (spot.y < min) min = spot.y;
      if (spot.y > max) max = spot.y;
      sum += spot.y;
      count++;
    }
    if (count == 0) return const SizedBox();
    double avg = sum / count;

    // FOOTER AUF 2 STELLEN
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF1E1E1E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem("Min", min.toStringAsFixed(2), unit, Colors.redAccent),
          _buildStatItem("Ø", avg.toStringAsFixed(2), unit, Colors.white),
          _buildStatItem(
            "Max",
            max.toStringAsFixed(2),
            unit,
            TRTColors.highNormal,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                color: Colors.grey.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
