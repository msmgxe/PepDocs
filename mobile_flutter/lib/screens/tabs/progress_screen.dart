import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';
import '../../services/units_service.dart';
import '../../services/language_service.dart';
import '../../utils/achievements_helper.dart';

enum _Period { month1, month3, month6, all }

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Map<String, dynamic>> _measurements = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;
  _Period _period = _Period.all;
  int _totalMeasurements = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await getProfile();
      if (profile == null) return;
      final measurements = await getMeasurements(profile['id'].toString());
      if (mounted) {
        setState(() {
          _profile = profile;
          _measurements = measurements.reversed.toList();
          _totalMeasurements = measurements.length;
        });
      }
    } catch (e) {
      // ignore load errors — spinner will stop in finally
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_period == _Period.all) return _measurements;
    final days = {
      _Period.month1: 30,
      _Period.month3: 90,
      _Period.month6: 180,
    }[_period]!;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _measurements.where((m) {
      final dateStr = m['measurement_date']?.toString().substring(0, 10) ?? '';
      final d = DateTime.tryParse(dateStr);
      return d != null && !d.isBefore(cutoff);
    }).toList();
  }

  List<FlSpot> _buildSpots(List<Map<String, dynamic>> data) {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final w = (data[i]['weight_kg'] as num?)?.toDouble();
      if (w != null) spots.add(FlSpot(i.toDouble(), w));
    }
    return spots;
  }

  String _bmiCategory(double bmi) {
    final l = LanguageService.instance;
    if (bmi < 18.5) return l.tr('bmi_underweight');
    if (bmi < 25) return l.tr('bmi_normal_short');
    if (bmi < 30) return l.tr('bmi_overweight');
    return l.tr('bmi_obesity');
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    final filtered = _filtered;
    final spots = _buildSpots(filtered);
    final targetWeight = (_profile?['goal_weight_kg'] as num?)?.toDouble();
    final profileWeight = (_profile?['current_weight_kg'] as num?)?.toDouble();
    final currentWeight = _measurements.isNotEmpty
        ? (_measurements.last['weight_kg'] as num?)?.toDouble()
        : profileWeight;
    final firstWeight = _measurements.isNotEmpty
        ? (_measurements.first['weight_kg'] as num?)?.toDouble()
        : null;
    final height = (_profile?['height_cm'] as num?)?.toDouble();
    final sex = _profile?['sex']?.toString();
    final bmi = (currentWeight != null && height != null && height > 0)
        ? currentWeight / ((height / 100) * (height / 100))
        : null;
    final bmiCategory = bmi != null ? _bmiCategory(bmi) : null;
    final bmiColor = bmi != null ? _bmiColor(bmi) : null;
    final totalLost = (currentWeight != null && firstWeight != null)
        ? firstWeight - currentWeight
        : null;

    double? minY;
    double? maxY;
    if (spots.isNotEmpty) {
      final ys = spots.map((s) => s.y).toList();
      if (targetWeight != null) ys.add(targetWeight);
      minY = ys.reduce((a, b) => a < b ? a : b) - 2;
      maxY = ys.reduce((a, b) => a > b ? a : b) + 2;
    }

    final dateLocale = l.dateLocale;

    return Scaffold(
      appBar: AppBar(title: Text(l.tr('progress_title'))),
      backgroundColor: kBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Body figure card ─────────────────────────────
                  if (currentWeight != null)
                    _BodyCard(
                      sex: sex,
                      currentWeight: currentWeight,
                      height: height,
                      bmi: bmi,
                      bmiCategory: bmi != null ? _bmiCategory(bmi) : null,
                      bmiColor: bmi != null ? _bmiColor(bmi) : null,
                      totalLost: totalLost,
                    ),

                  if (currentWeight != null) const SizedBox(height: 16),

                  // ── Summary mini-cards ───────────────────────────
                  if (currentWeight != null)
                    ListenableBuilder(
                      listenable: UnitsService.instance,
                      builder: (context, _) => Row(
                        children: [
                          Expanded(
                            child: _MiniCard(
                              label: l.tr('progress_initial_weight'),
                              value: UnitsService.instance.formatWeight(
                                  firstWeight ?? currentWeight),
                              color: kPrimary,
                            ),
                          ),
                          if (targetWeight != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniCard(
                                label: l.tr('progress_goal'),
                                value: UnitsService.instance
                                    .formatWeight(targetWeight),
                                color: Colors.green,
                              ),
                            ),
                          ],
                          if (firstWeight != null &&
                              currentWeight != firstWeight) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniCard(
                                label: l.tr('progress_difference'),
                                value:
                                    '${(currentWeight - firstWeight) > 0 ? '+' : ''}${UnitsService.instance.formatWeight((currentWeight - firstWeight).abs())}',
                                color: currentWeight < firstWeight
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  if (bmi != null) ...[
                    const SizedBox(height: 16),
                    _BmiGaugeCard(
                      bmi: bmi,
                      category: bmiCategory,
                      categoryColor: bmiColor,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Period filter ────────────────────────────────
                  Center(
                    child: SegmentedButton<_Period>(
                      segments: const [
                        ButtonSegment(
                            value: _Period.month1, label: Text('1M')),
                        ButtonSegment(
                            value: _Period.month3, label: Text('3M')),
                        ButtonSegment(
                            value: _Period.month6, label: Text('6M')),
                        ButtonSegment(
                            value: _Period.all, label: Text('All')),
                      ],
                      selected: {_period},
                      onSelectionChanged: (s) =>
                          setState(() => _period = s.first),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Chart ────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.tr('progress_chart_title'),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          spots.isEmpty
                              ? SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.show_chart,
                                            size: 40,
                                            color: Colors.grey[300]),
                                        const SizedBox(height: 8),
                                        Text(
                                          filtered.isEmpty &&
                                                  _period != _Period.all
                                              ? l.tr(
                                                  'progress_no_records_period')
                                              : l.tr('progress_no_records'),
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l.tr('progress_hint'),
                                          style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 220,
                                  child: LineChart(
                                    LineChartData(
                                      minY: minY,
                                      maxY: maxY,
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval: 5,
                                        getDrawingHorizontalLine: (v) =>
                                            FlLine(
                                          color: kPrimary
                                              .withValues(alpha: 0.12),
                                          strokeWidth: 1,
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: kPrimary
                                                .withValues(alpha: 0.25),
                                            width: 1.5,
                                          ),
                                          left: BorderSide(
                                            color: kPrimary
                                                .withValues(alpha: 0.25),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (v, meta) =>
                                                Text(
                                              v.toStringAsFixed(0),
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: kPrimary
                                                      .withValues(
                                                          alpha: 0.7)),
                                            ),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 28,
                                            getTitlesWidget: (v, meta) {
                                              final idx = v.toInt();
                                              if (idx < 0 ||
                                                  idx >=
                                                      filtered.length) {
                                                return const SizedBox
                                                    .shrink();
                                              }
                                              if (idx != 0 &&
                                                  idx !=
                                                      filtered.length -
                                                          1 &&
                                                  filtered.length > 6 &&
                                                  idx %
                                                          (filtered
                                                                  .length ~/
                                                              4) !=
                                                      0) {
                                                return const SizedBox
                                                    .shrink();
                                              }
                                              final dateStr = filtered[idx]
                                                          [
                                                          'measurement_date']
                                                      ?.toString()
                                                      .substring(0, 10) ??
                                                  '';
                                              final d =
                                                  DateTime.tryParse(dateStr);
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        top: 4),
                                                child: Text(
                                                  d != null
                                                      ? DateFormat('d/M')
                                                          .format(d)
                                                      : '',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: kPrimary
                                                          .withValues(
                                                              alpha: 0.7)),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: false)),
                                        rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: false)),
                                      ),
                                      lineTouchData: LineTouchData(
                                        touchTooltipData:
                                            LineTouchTooltipData(
                                          getTooltipItems:
                                              (touchedSpots) =>
                                                  touchedSpots
                                                      .map((s) =>
                                                          LineTooltipItem(
                                                            UnitsService
                                                                .instance
                                                                .formatWeight(
                                                                    s.y),
                                                            const TextStyle(
                                                              color: Colors
                                                                  .white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                            ),
                                                          ))
                                                      .toList(),
                                        ),
                                      ),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: spots,
                                          isCurved: true,
                                          color: kPrimary,
                                          barWidth: 3,
                                          dotData: FlDotData(
                                            show: true,
                                            getDotPainter:
                                                (s, x, b, i) =>
                                                    FlDotCirclePainter(
                                              radius: 4,
                                              color: kPrimary,
                                              strokeColor: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: kPrimary
                                                .withValues(alpha: 0.08),
                                          ),
                                        ),
                                        if (targetWeight != null)
                                          LineChartBarData(
                                            spots: [
                                              FlSpot(0, targetWeight),
                                              FlSpot(
                                                  (spots.length - 1)
                                                      .toDouble(),
                                                  targetWeight),
                                            ],
                                            isCurved: false,
                                            color: Colors.green
                                                .withValues(alpha: 0.6),
                                            barWidth: 2,
                                            dashArray: [6, 4],
                                            dotData: const FlDotData(
                                                show: false),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                          if (targetWeight != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                    width: 16,
                                    height: 3,
                                    color: Colors.green
                                        .withValues(alpha: 0.6)),
                                const SizedBox(width: 6),
                                Text(
                                  l.tr('chart_meta', params: {
                                    'amount': UnitsService.instance
                                        .formatWeight(targetWeight)
                                  }),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── History list ─────────────────────────────────
                  if (filtered.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.tr('progress_history'),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...filtered.reversed.take(10).map((m) {
                              final dateStr = m['measurement_date']
                                      ?.toString()
                                      .substring(0, 10) ??
                                  '';
                              final date = DateTime.tryParse(dateStr);
                              final w =
                                  (m['weight_kg'] as num?)?.toDouble() ??
                                      0;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      date != null
                                          ? DateFormat(
                                                  'dd MMM yyyy',
                                                  dateLocale)
                                              .format(date)
                                          : dateStr,
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                    Text(
                                      UnitsService.instance.formatWeight(w),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                  // ── Stats Row ────────────────────────────────────
                  const SizedBox(height: 24),
                  if (currentWeight != null)
                    _StatsRow(
                      initialWeight: firstWeight ?? currentWeight,
                      currentWeight: currentWeight,
                      goalWeight: targetWeight,
                    ),

                  // ── Summary Card ─────────────────────────────────
                  const SizedBox(height: 12),
                  if (currentWeight != null &&
                      firstWeight != null &&
                      firstWeight != currentWeight)
                    _SummaryCard(
                      initialWeight: firstWeight,
                      currentWeight: currentWeight,
                      goalWeight: targetWeight ?? 0,
                    ),

                  // ── Logros ───────────────────────────────────────
                  const SizedBox(height: 24),
                  Text(l.tr('progress_achievements'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _AchievementsGrid(
                    achievements: calculateAchievements(
                      initialWeight:
                          firstWeight ?? (currentWeight ?? 0),
                      currentWeight: currentWeight ?? 0,
                      goalWeight: targetWeight ?? 0,
                      bmi: bmi ?? 0,
                      measurementCount: _totalMeasurements,
                      age: (_profile?['age'] as num?)?.toInt(),
                      sex: _profile?['sex']?.toString(),
                    ),
                  ),

                  // ── Sugerencias ──────────────────────────────────
                  const SizedBox(height: 24),
                  Text(l.tr('progress_suggestions'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _SuggestionsRow(
                    suggestions: getSuggestions(
                      bmi: bmi ?? 0,
                      age: (_profile?['age'] as num?)?.toInt(),
                      sex: _profile?['sex']?.toString(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ─── Body figure card ─────────────────────────────────────────────────────────

class _BodyCard extends StatelessWidget {
  final String? sex;
  final double currentWeight;
  final double? height;
  final double? bmi;
  final String? bmiCategory;
  final Color? bmiColor;
  final double? totalLost;

  const _BodyCard({
    required this.sex,
    required this.currentWeight,
    this.height,
    this.bmi,
    this.bmiCategory,
    this.bmiColor,
    this.totalLost,
  });

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    final isFemale = sex == 'femenino';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isFemale
                            ? const [Color(0xFFF3E5F5), Color(0xFFCE93D8)]
                            : const [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
                      ),
                    ),
                    child: Image.asset(
                      isFemale
                          ? 'assets/images/figure_female.png'
                          : 'assets/images/figure_male.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (sex != null)
                  Text(
                    isFemale ? l.tr('sex_female') : l.tr('sex_male'),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(
                    icon: Icons.monitor_weight_outlined,
                    label: l.tr('home_current_weight'),
                    value: UnitsService.instance.formatWeight(currentWeight),
                    color: kPrimary,
                  ),
                  if (height != null)
                    _StatRow(
                      icon: Icons.height,
                      label: l.tr('info_height'),
                      value: UnitsService.instance.formatHeight(height!),
                      color: Colors.blueGrey,
                    ),
                  if (bmi != null)
                    _StatRow(
                      icon: Icons.calculate_outlined,
                      label: 'IMC',
                      value:
                          '${bmi!.toStringAsFixed(1)} · ${bmiCategory ?? ''}',
                      color: bmiColor ?? Colors.grey,
                    ),
                  if (totalLost != null && totalLost!.abs() > 0.1)
                    _StatRow(
                      icon: totalLost! > 0
                          ? Icons.trending_down
                          : Icons.trending_up,
                      label: totalLost! > 0
                          ? l.tr('progress_decreased')
                          : l.tr('progress_increased'),
                      value: UnitsService.instance
                          .formatWeight(totalLost!.abs()),
                      color:
                          totalLost! > 0 ? Colors.green : Colors.orange,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey[500])),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini summary card ────────────────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ─── BMI Gauge card ───────────────────────────────────────────────────────────

class _BmiGaugeCard extends StatelessWidget {
  final double bmi;
  final String? category;
  final Color? categoryColor;

  const _BmiGaugeCard({
    required this.bmi,
    this.category,
    this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  l.tr('bmi_gauge_title'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (categoryColor ?? Colors.grey)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: categoryColor ?? Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(painter: _BmiGaugePainter(bmi: bmi)),
            ),
            Text(
              l.tr('bmi_healthy_range'),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(
                    color: const Color(0xFF7B1FA2),
                    label: l.tr('bmi_underweight')),
                const SizedBox(width: 10),
                _LegendDot(
                    color: const Color(0xFF4CAF50),
                    label: l.tr('bmi_normal_short')),
                const SizedBox(width: 10),
                _LegendDot(
                    color: const Color(0xFFFF9800),
                    label: l.tr('bmi_overweight')),
                const SizedBox(width: 10),
                _LegendDot(
                    color: const Color(0xFFF44336),
                    label: l.tr('bmi_obesity')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiGaugePainter extends CustomPainter {
  final double bmi;

  static const _min = 15.0;
  static const _max = 40.0;

  const _BmiGaugePainter({required this.bmi});

  double _toAngle(double val) =>
      math.pi +
      (val.clamp(_min, _max) - _min) / (_max - _min) * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.86;
    final center = Offset(cx, cy);
    final r = (size.width * 0.38).clamp(80.0, 130.0);
    const sw = 18.0;

    final rect = Rect.fromCircle(center: center, radius: r);

    const zones = [
      (15.0, 18.5, Color(0xFF7B1FA2)),
      (18.5, 25.0, Color(0xFF4CAF50)),
      (25.0, 30.0, Color(0xFFFF9800)),
      (30.0, 40.0, Color(0xFFF44336)),
    ];

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    for (final z in zones) {
      arcPaint.color = z.$3;
      canvas.drawArc(
          rect, _toAngle(z.$1), _toAngle(z.$2) - _toAngle(z.$1), false,
          arcPaint);
    }

    final divPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0;
    for (final v in [18.5, 25.0, 30.0]) {
      final a = _toAngle(v);
      canvas.drawLine(
        Offset(cx + (r - sw / 2 - 1) * math.cos(a),
            cy + (r - sw / 2 - 1) * math.sin(a)),
        Offset(cx + (r + sw / 2 + 1) * math.cos(a),
            cy + (r + sw / 2 + 1) * math.sin(a)),
        divPaint,
      );
    }

    final bmiTp = TextPainter(
      text: TextSpan(
        text: bmi.toStringAsFixed(1),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    bmiTp.paint(
      canvas,
      Offset(cx - bmiTp.width / 2, cy - r * 0.48 - bmiTp.height / 2),
    );

    final na = _toAngle(bmi);
    canvas.drawLine(
      center,
      Offset(cx + (r - sw / 2 - 4) * math.cos(na),
          cy + (r - sw / 2 - 4) * math.sin(na)),
      Paint()
        ..color = Colors.grey.shade800
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 7, Paint()..color = Colors.grey.shade800);
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BmiGaugePainter o) => o.bmi != bmi;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final double initialWeight;
  final double currentWeight;
  final double? goalWeight;

  const _StatsRow({
    required this.initialWeight,
    required this.currentWeight,
    this.goalWeight,
  });

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    final items = [
      _StatItem(
          label: l.tr('progress_start'),
          value: UnitsService.instance.formatWeight(initialWeight),
          icon: Icons.flag_outlined),
      _StatItem(
          label: l.tr('progress_today'),
          value: UnitsService.instance.formatWeight(currentWeight),
          icon: Icons.place_outlined),
      if (goalWeight != null && goalWeight! > 0)
        _StatItem(
            label: l.tr('progress_meta'),
            value: UnitsService.instance.formatWeight(goalWeight!),
            icon: Icons.gps_fixed),
    ];

    return Row(
      children: items
          .map((item) => Expanded(
                child: Card(
                  margin: const EdgeInsets.only(right: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  color: const Color(0xFFF3EEFF),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 8),
                    child: Column(
                      children: [
                        Icon(item.icon, size: 18, color: kPrimary),
                        const SizedBox(height: 4),
                        Text(item.label,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(item.value,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kPrimary)),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem(
      {required this.label, required this.value, required this.icon});
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double initialWeight;
  final double currentWeight;
  final double goalWeight;

  const _SummaryCard({
    required this.initialWeight,
    required this.currentWeight,
    required this.goalWeight,
  });

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    final lost = initialWeight - currentWeight;
    final toGoal = currentWeight - goalWeight;
    final reachedGoal = goalWeight > 0 && toGoal <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            reachedGoal
                ? Icons.emoji_events
                : (lost > 0 ? Icons.trending_down : Icons.trending_up),
            color: kPrimary,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reachedGoal
                      ? l.tr('progress_goal_reached')
                      : lost > 0
                          ? l.tr('progress_lost', params: {
                              'amount':
                                  UnitsService.instance.formatWeight(lost)
                            })
                          : l.tr('progress_started_at', params: {
                              'amount': UnitsService.instance
                                  .formatWeight(initialWeight)
                            }),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kPrimary),
                ),
                if (!reachedGoal && goalWeight > 0)
                  Text(
                    l.tr('progress_to_go', params: {
                      'amount':
                          UnitsService.instance.formatWeight(toGoal),
                      'goal':
                          UnitsService.instance.formatWeight(goalWeight),
                    }),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  )
                else if (reachedGoal)
                  Text(
                    l.tr('progress_excellent'),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Achievements Grid ────────────────────────────────────────────────────────

class _AchievementsGrid extends StatelessWidget {
  final List<Achievement> achievements;

  const _AchievementsGrid({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, idx) {
        final a = achievements[idx];
        return Container(
          decoration: BoxDecoration(
            color: a.unlocked
                ? const Color(0xFFEDE7FF)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: a.unlocked
                  ? const Color(0xFFD8B4FE)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Opacity(
            opacity: a.unlocked ? 1.0 : 0.55,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.icon,
                      size: 30,
                      color: a.unlocked ? a.iconColor : Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    a.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: a.unlocked ? kPrimary : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.desc,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!a.unlocked) ...[
                    const SizedBox(height: 4),
                    const Icon(Icons.lock_outline,
                        size: 14, color: Colors.grey),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Suggestions Row ──────────────────────────────────────────────────────────

class _SuggestionsRow extends StatelessWidget {
  final List<Suggestion> suggestions;

  const _SuggestionsRow({required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: suggestions.map((s) {
        final bg = s.isYellow
            ? const Color(0xFFFFFDE7)
            : const Color(0xFFF3EEFF);
        final border = s.isYellow
            ? const Color(0xFFF5F3C6)
            : const Color(0xFFE9D5FF);
        final isLast = s == suggestions.last;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Icon(s.icon, size: 28, color: kPrimary),
                const SizedBox(height: 6),
                Text(
                  s.title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  s.desc,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
