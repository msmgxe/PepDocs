import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
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
          _measurements = measurements;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    _showMeasurementDialog(null);
  }

  void _showEditDialog(Map<String, dynamic> measurement) {
    _showMeasurementDialog(measurement);
  }

  void _showMeasurementDialog(Map<String, dynamic>? existing) {
    final weightController = TextEditingController(
        text: existing?['weight_kg']?.toString() ?? '');
    final notesController = TextEditingController(
        text: existing?['notes']?.toString() ?? '');
    DateTime selectedDate = existing != null
        ? DateTime.tryParse(
                existing['measurement_date'].toString().substring(0, 10)) ??
            DateTime.now()
        : DateTime.now();
    File? selectedImage;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      existing == null
                          ? 'Registrar peso'
                          : 'Editar registro',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                // Date picker
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setDialogState(() => selectedDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa el peso';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 12),
                // Photo
                Row(
                  children: [
                    if (selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(selectedImage!,
                            width: 64, height: 64, fit: BoxFit.cover),
                      )
                    else if (existing?['photo_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          existing!['photo_url'].toString(),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx2, err, st) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Foto'),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                            maxWidth: 1080);
                        if (picked != null) {
                          setDialogState(
                              () => selectedImage = File(picked.path));
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    await _saveMeasurement(
                      existing: existing,
                      weight: double.parse(weightController.text),
                      date: selectedDate,
                      notes: notesController.text.trim(),
                      imageFile: selectedImage,
                    );
                  },
                  child: Text(existing == null ? 'Guardar' : 'Actualizar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveMeasurement({
    Map<String, dynamic>? existing,
    required double weight,
    required DateTime date,
    String? notes,
    File? imageFile,
  }) async {
    if (_profile == null) return;
    try {
      String? photoUrl = existing?['photo_url']?.toString();

      if (imageFile != null) {
        photoUrl =
            await uploadPhoto(imageFile, _profile!['id'].toString());
      }

      final data = {
        'patient_id': _profile!['id'].toString(),
        'weight_kg': weight,
        'measurement_date': date.toIso8601String(),
        'notes': notes,
        'photo_url': photoUrl,
      };

      if (existing == null) {
        await addMeasurement(data);
      } else {
        data.remove('patient_id');
        await updateMeasurement(existing['id'].toString(), data);
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    }
  }

  Future<void> _deleteMeasurement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Seguro que deseas eliminar este registro?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: kError),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true) {
      await deleteMeasurement(id);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peso')),
      backgroundColor: kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _measurements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.monitor_weight_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Sin registros aún',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca + para agregar tu primer registro',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _measurements.length,
                      itemBuilder: (ctx, i) {
                        final m = _measurements[i];
                        final dateStr =
                            m['measurement_date']?.toString().substring(0, 10) ??
                                '';
                        final date = DateTime.tryParse(dateStr);
                        final weight =
                            (m['weight_kg'] as num?)?.toDouble() ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: m['photo_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      m['photo_url'].toString(),
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                          Icons.monitor_weight_outlined,
                                          color: kPrimary),
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundColor: kPrimary.withValues(alpha: 0.1),
                                    child: Icon(
                                        Icons.monitor_weight_outlined,
                                        color: kPrimary),
                                  ),
                            title: Text(
                              '${weight.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (date != null)
                                  Text(DateFormat('dd MMM yyyy', 'es')
                                      .format(date)),
                                if (m['notes'] != null &&
                                    m['notes'].toString().isNotEmpty)
                                  Text(
                                    m['notes'].toString(),
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showEditDialog(m),
                                  color: kPrimary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      _deleteMeasurement(m['id'].toString()),
                                  color: kError,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
