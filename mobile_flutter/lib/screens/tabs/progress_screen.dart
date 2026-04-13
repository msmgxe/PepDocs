import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';

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
          _measurements = measurements.reversed.toList(); // ascending for chart
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
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Progreso')),
      backgroundColor: kBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Body figure card ──────────────────────────────
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

                  // ── Summary mini-cards ────────────────────────────
                  if (currentWeight != null)
                    Row(
                      children: [
                        Expanded(
                          child: _MiniCard(
                            label: 'Peso actual',
                            value: '${currentWeight.toStringAsFixed(1)} kg',
                            color: kPrimary,
                          ),
                        ),
                        if (targetWeight != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniCard(
                              label: 'Meta',
                              value: '${targetWeight.toStringAsFixed(1)} kg',
                              color: Colors.green,
                            ),
                          ),
                        ],
                        if (firstWeight != null &&
                            currentWeight != firstWeight) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniCard(
                              label: 'Diferencia',
                              value:
                                  '${(currentWeight - firstWeight) > 0 ? '+' : ''}${(currentWeight - firstWeight).toStringAsFixed(1)} kg',
                              color: currentWeight < firstWeight
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: 24),

                  // ── Period filter ─────────────────────────────────
                  Center(
                    child: SegmentedButton<_Period>(
                      segments: const [
                        ButtonSegment(value: _Period.month1, label: Text('1M')),
                        ButtonSegment(value: _Period.month3, label: Text('3M')),
                        ButtonSegment(value: _Period.month6, label: Text('6M')),
                        ButtonSegment(
                            value: _Period.all, label: Text('Todo')),
                      ],
                      selected: {_period},
                      onSelectionChanged: (s) =>
                          setState(() => _period = s.first),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Chart ─────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Evolución del peso',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                                              ? 'Sin registros en este período'
                                              : 'Aún no hay registros',
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ve a la pestaña Peso y toca +',
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
                                          color: Colors.grey[200]!,
                                          strokeWidth: 1,
                                        ),
                                      ),
                                      borderData:
                                          FlBorderData(show: false),
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
                                                  color: Colors.grey[600]),
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
                                                  idx >= filtered.length) {
                                                return const SizedBox
                                                    .shrink();
                                              }
                                              if (idx != 0 &&
                                                  idx !=
                                                      filtered.length - 1 &&
                                                  filtered.length > 6 &&
                                                  idx %
                                                          (filtered.length ~/
                                                              4) !=
                                                      0) {
                                                return const SizedBox
                                                    .shrink();
                                              }
                                              final dateStr = filtered[idx][
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
                                                      color:
                                                          Colors.grey[600]),
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
                                          getTooltipItems: (touchedSpots) =>
                                              touchedSpots
                                                  .map((s) =>
                                                      LineTooltipItem(
                                                        '${s.y.toStringAsFixed(1)} kg',
                                                        const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                            getDotPainter: (s, x, b, i) =>
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
                                  'Meta: ${targetWeight.toStringAsFixed(1)} kg',
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

                  // ── History list ──────────────────────────────────
                  if (filtered.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Historial',
                              style: TextStyle(
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
                                          ? DateFormat('dd MMM yyyy', 'es')
                                              .format(date)
                                          : dateStr,
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                    Text(
                                      '${w.toStringAsFixed(1)} kg',
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
                ],
              ),
            ),
    );
  }
}

// ─── Human figure painter ─────────────────────────────────────────────────────

class _HumanPainter extends CustomPainter {
  final bool isFemale;
  final Color color;
  const _HumanPainter({required this.isFemale, required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final cx = s.width / 2;

    // ── Head (oval) ─────────────────────────────────────────────────────────
    final headRx = s.width * 0.145;
    final headRy = s.width * 0.165;
    final headCy = headRy + s.height * 0.01;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, headCy), width: headRx * 2, height: headRy * 2),
      paint,
    );

    // ── Neck ─────────────────────────────────────────────────────────────────
    final neckW = s.width * 0.082;
    final neckTop = headCy + headRy * 0.82;
    final neckBot = neckTop + s.height * 0.055;
    final neckPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - neckW / 2, neckTop, cx + neckW / 2, neckBot),
        const Radius.circular(3),
      ));
    canvas.drawPath(neckPath, paint);

    // ── Torso with waist curve ───────────────────────────────────────────────
    final shW = isFemale ? s.width * 0.50 : s.width * 0.60;
    final hipW = isFemale ? s.width * 0.54 : s.width * 0.45;
    final waistW = isFemale ? s.width * 0.34 : s.width * 0.42;
    final tTop = neckBot;
    final tBot = s.height * 0.57;
    final waistY = tTop + (tBot - tTop) * 0.52;

    final torso = Path()
      ..moveTo(cx - shW / 2, tTop)
      ..lineTo(cx + shW / 2, tTop)
      ..quadraticBezierTo(
          cx + waistW / 2 + s.width * 0.06, waistY, cx + hipW / 2, tBot)
      ..lineTo(cx - hipW / 2, tBot)
      ..quadraticBezierTo(
          cx - waistW / 2 - s.width * 0.06, waistY, cx - shW / 2, tTop)
      ..close();
    canvas.drawPath(torso, paint);

    // ── Arms ─────────────────────────────────────────────────────────────────
    final aW = s.width * 0.095;
    final aLen = (tBot - tTop) * 0.88;
    for (final side in [-1.0, 1.0]) {
      final ax = cx + side * shW / 2;
      final arm = Path()
        ..moveTo(ax, tTop)
        ..lineTo(ax + side * aW * 1.6, tTop + aLen * 0.18)
        ..lineTo(ax + side * aW * 1.2, tTop + aLen)
        ..lineTo(ax + side * aW * 0.1, tTop + aLen)
        ..lineTo(ax - side * aW * 0.4, tTop + aLen * 0.18)
        ..close();
      canvas.drawPath(arm, paint);
    }

    // ── Legs ─────────────────────────────────────────────────────────────────
    final lW = s.width * 0.21;
    final gap = s.width * 0.025;
    for (final side in [-1.0, 1.0]) {
      final lx = cx + side * gap;
      final leg = Path()
        ..moveTo(lx, tBot)
        ..lineTo(lx + side * lW, tBot)
        ..quadraticBezierTo(
            lx + side * lW * 0.9, s.height * 0.78, lx + side * lW * 0.82, s.height)
        ..lineTo(lx + side * lW * 0.08, s.height)
        ..close();
      canvas.drawPath(leg, paint);
    }
  }

  @override
  bool shouldRepaint(_HumanPainter old) =>
      old.isFemale != isFemale || old.color != color;
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
    final isFemale = sex == 'femenino';
    final figureColor = kPrimary.withValues(alpha: 0.78);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Silhouette ──────────────────────────────────────────────────
            Column(
              children: [
                SizedBox(
                  width: 82,
                  height: 148,
                  child: CustomPaint(
                    painter: _HumanPainter(
                        isFemale: isFemale, color: figureColor),
                  ),
                ),
                const SizedBox(height: 4),
                if (sex != null)
                  Text(
                    isFemale ? 'Femenino' : 'Masculino',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            // ── Stats ───────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Peso actual',
                    value: '${currentWeight.toStringAsFixed(1)} kg',
                    color: kPrimary,
                  ),
                  if (height != null)
                    _StatRow(
                      icon: Icons.height,
                      label: 'Estatura',
                      value: '${height!.toStringAsFixed(0)} cm',
                      color: Colors.blueGrey,
                    ),
                  if (bmi != null)
                    _StatRow(
                      icon: Icons.calculate_outlined,
                      label: 'IMC',
                      value: '${bmi!.toStringAsFixed(1)} · ${bmiCategory ?? ''}',
                      color: bmiColor ?? Colors.grey,
                    ),
                  if (totalLost != null && totalLost!.abs() > 0.1)
                    _StatRow(
                      icon: totalLost! > 0
                          ? Icons.trending_down
                          : Icons.trending_up,
                      label: totalLost! > 0 ? 'Has bajado' : 'Has subido',
                      value: '${totalLost!.abs().toStringAsFixed(1)} kg',
                      color: totalLost! > 0 ? Colors.green : Colors.orange,
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
