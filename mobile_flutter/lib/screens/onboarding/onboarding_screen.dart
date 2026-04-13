import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/pep_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _selectedSex;
  DateTime? _selectedBirthDate;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 5),
      helpText: 'Fecha de nacimiento',
    );
    if (d != null) setState(() => _selectedBirthDate = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final profile = await upsertProfile({
        'full_name': _nameController.text.trim(),
        'current_weight_kg': double.tryParse(_weightController.text) ?? 0,
        'goal_weight_kg': double.tryParse(_targetWeightController.text) ?? 0,
        'height_cm': double.tryParse(_heightController.text) ?? 0,
        'role': 'patient',
        if (_selectedSex != null) 'sex': _selectedSex,
        if (_selectedBirthDate != null)
          'birth_date': _selectedBirthDate!.toIso8601String().substring(0, 10),
      });

      // Auto-create initial measurement so the chart has data from day one
      final initialWeight = double.tryParse(_weightController.text);
      if (initialWeight != null && initialWeight > 0) {
        await addMeasurement({
          'patient_id': profile['id'].toString(),
          'weight_kg': initialWeight,
          'measurement_date': DateTime.now().toIso8601String().substring(0, 10),
        });
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  const Center(child: PepLogo(size: 72)),
                  const SizedBox(height: 20),
                  Text(
                    '¡Bienvenido/a!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: kPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuéntanos un poco sobre ti para personalizar tu experiencia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // Nombre
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tu nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                  ),
                  const SizedBox(height: 16),

                  // Sexo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Sexo',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'masculino',
                            label: Text('Masculino'),
                            icon: Icon(Icons.man, size: 18),
                          ),
                          ButtonSegment(
                            value: 'femenino',
                            label: Text('Femenino'),
                            icon: Icon(Icons.woman, size: 18),
                          ),
                        ],
                        selected: _selectedSex != null
                            ? {_selectedSex!}
                            : <String>{},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (s) => setState(
                            () => _selectedSex = s.isEmpty ? null : s.first),
                        style: ButtonStyle(
                          visualDensity: VisualDensity.comfortable,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fecha de nacimiento
                  InkWell(
                    onTap: _pickBirthDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento (opcional)',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(
                        _selectedBirthDate != null
                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          color: _selectedBirthDate != null
                              ? Colors.black87
                              : Colors.grey[500],
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Estatura
                  TextFormField(
                    controller: _heightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Estatura (cm)',
                      prefixIcon: Icon(Icons.height),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu estatura';
                      if (double.tryParse(v) == null) return 'Número inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Peso actual
                  TextFormField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Peso actual (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu peso';
                      if (double.tryParse(v) == null) return 'Número inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Peso objetivo
                  TextFormField(
                    controller: _targetWeightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: 'Peso objetivo (kg)',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa tu peso objetivo';
                      }
                      if (double.tryParse(v) == null) return 'Número inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Comenzar'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
