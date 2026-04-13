import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';
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
        (_profile!['weight_kg'] as num?)?.toDouble();
    if (height == null || height == 0 || weight == null) return null;
    final h = height / 100;
    return weight / (h * h);
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Peso normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
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
    final name = _profile?['full_name']?.toString() ?? 'Paciente';
    final bmi = _bmi();
    final currentWeight = (_latestMeasurement?['weight_kg'] as num?)?.toDouble() ??
        (_profile?['weight_kg'] as num?)?.toDouble();
    final targetWeight = (_profile?['target_weight_kg'] as num?)?.toDouble();
    final height = (_profile?['height_cm'] as num?)?.toDouble();
    final sex = _profile?['sex']?.toString();
    final age = _age();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pep Education'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi perfil',
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
            tooltip: 'Cerrar sesión',
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
                    Row(
                      children: [
                        if (height != null)
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.height,
                              label: 'Estatura',
                              value: '${height.toStringAsFixed(0)} cm',
                            ),
                          ),
                        if (height != null && (sex != null || age != null))
                          const SizedBox(width: 8),
                        if (sex != null)
                          Expanded(
                            child: _InfoChip(
                              icon: sex == 'female' ? Icons.woman : Icons.man,
                              label: 'Sexo',
                              value: sex == 'female' ? 'Femenino' : 'Masculino',
                            ),
                          ),
                        if (sex != null && age != null)
                          const SizedBox(width: 8),
                        if (age != null)
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.cake_outlined,
                              label: 'Edad',
                              value: '$age años',
                            ),
                          ),
                      ],
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
                                  'Índice de Masa Corporal',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600]),
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
                                      color: _bmiColor(bmi).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
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

                  const SizedBox(height: 16),

                  // Weight summary row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Peso actual',
                          value: currentWeight != null
                              ? '${currentWeight.toStringAsFixed(1)} kg'
                              : '—',
                          icon: Icons.monitor_weight_outlined,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Peso objetivo',
                          value: targetWeight != null
                              ? '${targetWeight.toStringAsFixed(1)} kg'
                              : '—',
                          icon: Icons.flag_outlined,
                          color: Colors.green,
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
                                'Próxima cita',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_nextEvent != null) ...[
                            Text(
                              _nextEvent!['title']?.toString() ?? 'Cita',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatEventDate(
                                  _nextEvent!['event_date']?.toString() ?? ''),
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                            ),
                            if (_nextEvent!['notes'] != null &&
                                _nextEvent!['notes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _nextEvent!['notes'].toString(),
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 13),
                              ),
                            ],
                          ] else
                            Text(
                              'Sin citas programadas',
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
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días,';
    if (h < 18) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  String _formatEventDate(String raw) {
    if (raw.isEmpty) return '';
    final date = DateTime.tryParse(raw.substring(0, 10));
    if (date == null) return raw;
    return DateFormat('EEEE d \'de\' MMMM', 'es').format(date);
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
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold),
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
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
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
