import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';
import '../../services/units_service.dart';
import '../../services/language_service.dart';

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
          final rawH = (p['height_cm'] as num?)?.toDouble() ?? 0.0;
          final rawW = (p['current_weight_kg'] as num?)?.toDouble() ?? 0.0;
          final rawGW = (p['goal_weight_kg'] as num?)?.toDouble() ?? 0.0;

          final units = UnitsService.instance;

          _heightController.text = units.isFt
              ? (rawH / 30.48).toStringAsFixed(1)
              : (rawH > 0 ? rawH.toStringAsFixed(0) : '');
          _weightController.text =
              rawW > 0 ? units.displayWeight(rawW).toStringAsFixed(1) : '';
          _targetController.text =
              rawGW > 0 ? units.displayWeight(rawGW).toStringAsFixed(1) : '';
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
    final l = LanguageService.instance;
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 5),
      helpText: l.tr('profile_birth_date'),
    );
    if (d != null) setState(() => _birthDate = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l = LanguageService.instance;
    setState(() => _saving = true);
    try {
      await upsertProfile({
        'full_name': _nameController.text.trim(),
        'height_cm': UnitsService.instance.isFt
            ? (double.tryParse(_heightController.text) ?? 0) * 30.48
            : (double.tryParse(_heightController.text) ?? 0),
        'current_weight_kg': UnitsService.instance
            .reverseWeight(double.tryParse(_weightController.text) ?? 0),
        'goal_weight_kg': UnitsService.instance
            .reverseWeight(double.tryParse(_targetController.text) ?? 0),
        if (_selectedSex != null) 'sex': _selectedSex,
        if (_birthDate != null)
          'birth_date': _birthDate!.toIso8601String().substring(0, 10),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.tr('profile_saved')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
    return ListenableBuilder(
      listenable: Listenable.merge(
          [LanguageService.instance, UnitsService.instance]),
      builder: (context, _) {
        final l = LanguageService.instance;
        final u = UnitsService.instance;

        return Scaffold(
          appBar: AppBar(title: Text(l.tr('profile_title'))),
          backgroundColor: kBackground,
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // ── Idioma ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            l.tr('profile_language'),
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                                value: 'es',
                                label: Text(l.tr('lang_es'))),
                            ButtonSegment(
                                value: 'en',
                                label: Text(l.tr('lang_en'))),
                            ButtonSegment(
                                value: 'pt',
                                label: Text(l.tr('lang_pt'))),
                          ],
                          selected: {l.lang},
                          onSelectionChanged: (s) =>
                              l.setLanguage(s.first),
                        ),
                        const SizedBox(height: 24),

                        // ── Sistema de unidades ──────────────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            l.tr('profile_units_title'),
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: SegmentedButton<bool>(
                                segments: [
                                  ButtonSegment(
                                      value: false,
                                      label: Text(l.tr('unit_kg'))),
                                  ButtonSegment(
                                      value: true,
                                      label: Text(l.tr('unit_lbs'))),
                                ],
                                selected: {u.isLbs},
                                onSelectionChanged: (s) {
                                  final toLbs = s.first;
                                  final currentW =
                                      double.tryParse(_weightController.text);
                                  if (currentW != null) {
                                    _weightController.text = toLbs
                                        ? (currentW * 2.20462)
                                            .toStringAsFixed(1)
                                        : (currentW / 2.20462)
                                            .toStringAsFixed(1);
                                  }
                                  final currentT =
                                      double.tryParse(_targetController.text);
                                  if (currentT != null) {
                                    _targetController.text = toLbs
                                        ? (currentT * 2.20462)
                                            .toStringAsFixed(1)
                                        : (currentT / 2.20462)
                                            .toStringAsFixed(1);
                                  }
                                  u.setWeightUnit(toLbs);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SegmentedButton<bool>(
                                segments: [
                                  ButtonSegment(
                                      value: false,
                                      label: Text(l.tr('unit_cm'))),
                                  ButtonSegment(
                                      value: true,
                                      label: Text(l.tr('unit_ft'))),
                                ],
                                selected: {u.isFt},
                                onSelectionChanged: (s) {
                                  final toFt = s.first;
                                  final currentH =
                                      double.tryParse(_heightController.text);
                                  if (currentH != null) {
                                    _heightController.text = toFt
                                        ? (currentH / 30.48).toStringAsFixed(1)
                                        : (currentH * 30.48)
                                            .toStringAsFixed(0);
                                  }
                                  u.setHeightUnit(toFt);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Nombre ─────────────────────────────────
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.tr('profile_name'),
                            prefixIcon:
                                const Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l.tr('profile_name_empty')
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // ── Sexo ───────────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                l.tr('profile_sex'),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600]),
                              ),
                            ),
                            SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'masculino',
                                  label: Text(l.tr('sex_male')),
                                  icon: const Icon(Icons.man, size: 18),
                                ),
                                ButtonSegment(
                                  value: 'femenino',
                                  label: Text(l.tr('sex_female')),
                                  icon: const Icon(Icons.woman, size: 18),
                                ),
                              ],
                              selected: _selectedSex != null
                                  ? {_selectedSex!}
                                  : <String>{},
                              emptySelectionAllowed: true,
                              onSelectionChanged: (s) => setState(() =>
                                  _selectedSex = s.isEmpty ? null : s.first),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Fecha de nacimiento ────────────────────
                        InkWell(
                          onTap: _pickBirthDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l.tr('profile_birth_date'),
                              prefixIcon:
                                  const Icon(Icons.cake_outlined),
                            ),
                            child: Text(
                              _birthDate != null
                                  ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                  : l.tr('profile_birth_date_select'),
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

                        // ── Estatura ───────────────────────────────
                        TextFormField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: u.isFt
                                ? l.tr('profile_height_ft')
                                : l.tr('profile_height_cm'),
                            prefixIcon: const Icon(Icons.height),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l.tr('profile_height_empty');
                            }
                            if (double.tryParse(v) == null) {
                              return l.tr('invalid_number');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // ── Peso actual ────────────────────────────
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l.tr('profile_weight',
                                params: {'unit': u.weightUnitStr}),
                            prefixIcon: const Icon(
                                Icons.monitor_weight_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l.tr('profile_weight_empty');
                            }
                            if (double.tryParse(v) == null) {
                              return l.tr('invalid_number');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // ── Peso objetivo ──────────────────────────
                        TextFormField(
                          controller: _targetController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          decoration: InputDecoration(
                            labelText: l.tr('profile_target',
                                params: {'unit': u.weightUnitStr}),
                            prefixIcon: const Icon(Icons.flag_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l.tr('profile_target_empty');
                            }
                            if (double.tryParse(v) == null) {
                              return l.tr('invalid_number');
                            }
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
                                : Text(l.tr('save_changes')),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
