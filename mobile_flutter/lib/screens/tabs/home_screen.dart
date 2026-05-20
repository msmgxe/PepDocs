import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';
import '../../services/units_service.dart';
import '../../services/language_service.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _latestMeasurement;
  Map<String, dynamic>? _nextEvent;
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
      final events = await getCalendarEvents(profile['id'].toString());

      final now = DateTime.now();
      Map<String, dynamic>? nextEvent;
      for (final e in events) {
        final dateStr = e['event_date']?.toString().substring(0, 10) ?? '';
        if (dateStr.isNotEmpty) {
          final d = DateTime.tryParse(dateStr);
          if (d != null && !d.isBefore(DateTime(now.year, now.month, now.day))) {
            nextEvent = e;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _latestMeasurement =
              measurements.isNotEmpty ? measurements.first : null;
          _nextEvent = nextEvent;
        });
      }
    } catch (e) {
      // ignore load errors — spinner will stop in finally
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? _bmi() {
    if (_profile == null) return null;
    final height = (_profile!['height_cm'] as num?)?.toDouble();
    final weight = (_latestMeasurement?['weight_kg'] as num?)?.toDouble() ??
        (_profile!['current_weight_kg'] as num?)?.toDouble();
    if (height == null || height == 0 || weight == null) return null;
    final h = height / 100;
    return weight / (h * h);
  }

  String _bmiCategory(double bmi) {
    final l = LanguageService.instance;
    if (bmi < 18.5) return l.tr('bmi_underweight');
    if (bmi < 25) return l.tr('bmi_normal');
    if (bmi < 30) return l.tr('bmi_overweight');
    return l.tr('bmi_obesity');
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  int? _age() {
    final birthStr = _profile?['birth_date']?.toString();
    if (birthStr == null) return null;
    final birth = DateTime.tryParse(birthStr.substring(0, 10));
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    final name =
        _profile?['full_name']?.toString() ?? l.tr('patient_default');
    final bmi = _bmi();
    final currentWeight =
        (_latestMeasurement?['weight_kg'] as num?)?.toDouble() ??
            (_profile?['current_weight_kg'] as num?)?.toDouble();
    final targetWeight = (_profile?['goal_weight_kg'] as num?)?.toDouble();
    final height = (_profile?['height_cm'] as num?)?.toDouble();
    final sex = _profile?['sex']?.toString();
    final age = _age();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.tr('app_name'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              l.tr('app_subtitle'),
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: l.tr('my_profile'),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              if (updated == true) _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.tr('logout'),
            onPressed: () async {
              await signOut();
            },
          ),
        ],
      ),
      backgroundColor: kBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Greeting
                  Text(
                    _greeting(),
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: kPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Personal info row: height, sex, age
                  if (height != null || sex != null || age != null)
                    ListenableBuilder(
                      listenable: UnitsService.instance,
                      builder: (context, _) => Row(
                        children: [
                          if (height != null)
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.height,
                                label: l.tr('info_height'),
                                value: UnitsService.instance
                                    .formatHeight(height),
                              ),
                            ),
                          if (height != null && (sex != null || age != null))
                            const SizedBox(width: 8),
                          if (sex != null)
                            Expanded(
                              child: _InfoChip(
                                icon: sex == 'femenino'
                                    ? Icons.woman
                                    : Icons.man,
                                label: l.tr('info_sex'),
                                value: sex == 'femenino'
                                    ? l.tr('sex_female')
                                    : l.tr('sex_male'),
                              ),
                            ),
                          if (sex != null && age != null)
                            const SizedBox(width: 8),
                          if (age != null)
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.cake_outlined,
                                label: l.tr('info_age'),
                                value: l.tr('years_suffix',
                                    params: {'n': '$age'}),
                              ),
                            ),
                        ],
                      ),
                    ),

                  if (height != null || sex != null || age != null)
                    const SizedBox(height: 16),

                  // BMI Card
                  if (bmi != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calculate_outlined,
                                    color: kPrimary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  l.tr('home_bmi'),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  bmi.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: _bmiColor(bmi),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _bmiColor(bmi)
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _bmiCategory(bmi),
                                      style: TextStyle(
                                        color: _bmiColor(bmi),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // BMI legend card — shown only when BMI is available
                  if (bmi != null) ...[
                    const SizedBox(height: 8),
                    _BmiLegendCard(),
                  ],

                  const SizedBox(height: 16),

                  // Weight summary row
                  Row(
                    children: [
                      Expanded(
                        child: ListenableBuilder(
                          listenable: UnitsService.instance,
                          builder: (context, _) => _StatCard(
                            label: l.tr('home_current_weight'),
                            value: currentWeight != null
                                ? UnitsService.instance
                                    .formatWeight(currentWeight)
                                : '—',
                            icon: Icons.monitor_weight_outlined,
                            color: kPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListenableBuilder(
                          listenable: UnitsService.instance,
                          builder: (context, _) => _StatCard(
                            label: l.tr('home_target_weight'),
                            value: targetWeight != null
                                ? UnitsService.instance
                                    .formatWeight(targetWeight)
                                : '—',
                            icon: Icons.flag_outlined,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Next appointment
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event_outlined,
                                  color: kPrimary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                l.tr('home_next_appointment'),
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_nextEvent != null) ...[
                            Text(
                              _nextEvent!['title']?.toString() ??
                                  l.tr('home_default_appointment'),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatEventDate(
                                  _nextEvent!['event_date']?.toString() ??
                                      ''),
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                            ),
                            if (_nextEvent!['notes'] != null &&
                                _nextEvent!['notes']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _nextEvent!['notes'].toString(),
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 13),
                              ),
                            ],
                          ] else
                            Text(
                              l.tr('home_no_appointments'),
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 15),
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

  String _greeting() {
    final l = LanguageService.instance;
    final h = DateTime.now().hour;
    if (h < 12) return l.tr('home_greeting_morning');
    if (h < 18) return l.tr('home_greeting_afternoon');
    return l.tr('home_greeting_evening');
  }

  String _formatEventDate(String raw) {
    if (raw.isEmpty) return '';
    final date = DateTime.tryParse(raw.substring(0, 10));
    if (date == null) return raw;
    final locale = LanguageService.instance.dateLocale;
    if (locale == 'en') {
      return DateFormat('EEEE, MMMM d', 'en').format(date);
    }
    return DateFormat("EEEE d 'de' MMMM", locale).format(date);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: kPrimary, size: 18),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BmiLegendCard extends StatelessWidget {
  const _BmiLegendCard();

  @override
  Widget build(BuildContext context) {
    final l = LanguageService.instance;
    final rows = [
      (const Color(0xFF5C6BC0), '< 18.5',      l.tr('bmi_underweight')),
      (const Color(0xFF43A047), '18.5 – 24.9', l.tr('bmi_normal')),
      (const Color(0xFFFB8C00), '25 – 29.9',   l.tr('bmi_overweight')),
      (const Color(0xFFEF6C00), '30 – 34.9',   l.tr('bmi_label_obesity1')),
      (const Color(0xFFE53935), '≥ 35',         l.tr('bmi_label_obesity2')),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  l.tr('bmi_legend_title'),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.tr('bmi_formula'),
              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            ...rows.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: r.$1, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  SizedBox(width: 82, child: Text(r.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                  Expanded(child: Text(r.$3, style: TextStyle(fontSize: 11, color: Colors.grey[700]))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
