import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetController = TextEditingController();
  String? _selectedSex;
  DateTime? _birthDate;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await getProfile();
      if (p != null && mounted) {
        setState(() {
          _nameController.text = p['full_name']?.toString() ?? '';
          _heightController.text = p['height_cm']?.toString() ?? '';
          _weightController.text = p['current_weight_kg']?.toString() ?? '';
          _targetController.text = p['goal_weight_kg']?.toString() ?? '';
          _selectedSex = p['sex']?.toString();
          final bs = p['birth_date']?.toString();
          if (bs != null && bs.length >= 10) {
            _birthDate = DateTime.tryParse(bs.substring(0, 10));
          }
        });
      }
    } catch (_) {
      // show empty form on error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 5),
      helpText: 'Fecha de nacimiento',
    );
    if (d != null) setState(() => _birthDate = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await upsertProfile({
        'full_name': _nameController.text.trim(),
        'height_cm': double.tryParse(_heightController.text) ?? 0,
        'current_weight_kg': double.tryParse(_weightController.text) ?? 0,
        'goal_weight_kg': double.tryParse(_targetController.text) ?? 0,
        if (_selectedSex != null) 'sex': _selectedSex,
        if (_birthDate != null)
          'birth_date': _birthDate!.toIso8601String().substring(0, 10),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true = refresh caller
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      backgroundColor: kBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Nombre ────────────────────────────────────
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Sexo ──────────────────────────────────────
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
                              value: 'male',
                              label: Text('Masculino'),
                              icon: Icon(Icons.man, size: 18),
                            ),
                            ButtonSegment(
                              value: 'female',
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Fecha de nacimiento ───────────────────────
                    InkWell(
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        child: Text(
                          _birthDate != null
                              ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                              : 'Seleccionar fecha',
                          style: TextStyle(
                            color: _birthDate != null
                                ? Colors.black87
                                : Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Estatura ─────────────────────────────────
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
                    const SizedBox(height: 20),

                    // ── Peso actual ───────────────────────────────
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
                    const SizedBox(height: 20),

                    // ── Peso objetivo ─────────────────────────────
                    TextFormField(
                      controller: _targetController,
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
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
