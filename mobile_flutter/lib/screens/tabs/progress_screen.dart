import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Map<String, dynamic>> _measurements = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;

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
          // Sort ascending for chart
          _measurements = measurements.reversed.toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<FlSpot> _buildSpots() {
    final spots = <FlSpot>[];
    for (var i = 0; i < _measurements.length; i++) {
      final w = (_measurements[i]['weight_kg'] as num?)?.toDouble();
      if (w != null) spots.add(FlSpot(i.toDouble(), w));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    final targetWeight =
        (_profile?['target_weight_kg'] as num?)?.toDouble();
    final currentWeight = _measurements.isNotEmpty
        ? (_measurements.last['weight_kg'] as num?)?.toDouble()
        : null;
    final firstWeight = _measurements.isNotEmpty
        ? (_measurements.first['weight_kg'] as num?)?.toDouble()
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
                  // Summary cards
                  if (currentWeight != null)
                    Row(
                      children: [
                        Expanded(
                          child: _MiniCard(
                            label: 'Peso actual',
                            value:
                                '${currentWeight.toStringAsFixed(1)} kg',
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (targetWeight != null)
                          Expanded(
                            child: _MiniCard(
                              label: 'Meta',
                              value:
                                  '${targetWeight.toStringAsFixed(1)} kg',
                              color: Colors.green,
                            ),
                          ),
                        const SizedBox(width: 12),
                        if (firstWeight != null && currentWeight != firstWeight)
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
                    ),

                  const SizedBox(height: 24),

                  // Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Evolución del peso',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          spots.isEmpty
                              ? SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Text(
                                      'Sin registros suficientes',
                                      style: TextStyle(
                                          color: Colors.grey[500]),
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
                                      borderData: FlBorderData(show: false),
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
                                                  idx >=
                                                      _measurements.length) {
                                                return const SizedBox.shrink();
                                              }
                                              // Show only first, last, and every Nth
                                              if (idx != 0 &&
                                                  idx !=
                                                      _measurements.length - 1 &&
                                                  _measurements.length > 6 &&
                                                  idx %
                                                          (_measurements.length ~/
                                                              4) !=
                                                      0) {
                                                return const SizedBox.shrink();
                                              }
                                              final dateStr = _measurements[idx][
                                                          'measurement_date']
                                                      ?.toString()
                                                      .substring(0, 10) ??
                                                  '';
                                              final d =
                                                  DateTime.tryParse(dateStr);
                                              return Padding(
                                                padding: const EdgeInsets.only(
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
                                      lineBarsData: [
                                        // Main weight line
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
                                            color:
                                                kPrimary.withValues(alpha: 0.08),
                                          ),
                                        ),
                                        // Target weight line
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
                                    color:
                                        Colors.green.withValues(alpha: 0.6)),
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

                  // History list (condensed)
                  if (_measurements.isNotEmpty)
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
                            ..._measurements.reversed
                                .take(10)
                                .map((m) {
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 4),
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
