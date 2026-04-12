import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/theme.dart';
import '../../services/supabase_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();

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
      final events = await getCalendarEvents(profile['id'].toString());
      if (mounted) {
        setState(() {
          _profile = profile;
          _events = events;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    return _events.where((e) {
      final raw = e['event_date']?.toString() ?? '';
      if (raw.length < 10) return false;
      return raw.substring(0, 10) == dayStr;
    }).toList();
  }

  void _showAddDialog() {
    _showEventDialog(null, _selectedDay);
  }

  void _showEditDialog(Map<String, dynamic> event) {
    final date = DateTime.tryParse(
            event['event_date']?.toString().substring(0, 10) ?? '') ??
        DateTime.now();
    _showEventDialog(event, date);
  }

  void _showEventDialog(Map<String, dynamic>? existing, DateTime initialDate) {
    final titleController =
        TextEditingController(text: existing?['title']?.toString() ?? '');
    final notesController =
        TextEditingController(text: existing?['notes']?.toString() ?? '');
    DateTime selectedDate = initialDate;
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final formKey = GlobalKey<FormState>();
    bool syncToDevice = false;

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
                      existing == null ? 'Nueva cita' : 'Editar cita',
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
                TextFormField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título de la cita',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingresa un título' : null,
                ),
                const SizedBox(height: 12),
                // Date
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setDialogState(() => selectedDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child:
                        Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                // Time
                InkWell(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (t != null) setDialogState(() => selectedTime = t);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(selectedTime.format(ctx)),
                  ),
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
                // Sync to device calendar
                Row(
                  children: [
                    Checkbox(
                      value: syncToDevice,
                      activeColor: kPrimary,
                      onChanged: (v) =>
                          setDialogState(() => syncToDevice = v ?? false),
                    ),
                    const Text('Agregar al calendario del dispositivo'),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    await _saveEvent(
                      existing: existing,
                      title: titleController.text.trim(),
                      date: selectedDate,
                      time: selectedTime,
                      notes: notesController.text.trim(),
                      syncToDevice: syncToDevice,
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

  Future<void> _saveEvent({
    Map<String, dynamic>? existing,
    required String title,
    required DateTime date,
    required TimeOfDay time,
    String? notes,
    bool syncToDevice = false,
  }) async {
    if (_profile == null) return;
    try {
      final eventDateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);

      final data = {
        'patient_id': _profile!['id'].toString(),
        'title': title,
        'event_date': eventDateTime.toIso8601String(),
        'notes': notes,
      };

      if (existing == null) {
        await addCalendarEvent(data);
      } else {
        data.remove('patient_id');
        await updateCalendarEvent(existing['id'].toString(), data);
      }

      if (syncToDevice) {
        await _syncToDeviceCalendar(title, eventDateTime, notes);
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

  Future<void> _syncToDeviceCalendar(
      String title, DateTime dateTime, String? notes) async {
    try {
      var permissionsGranted = await _deviceCalendar.hasPermissions();
      if (permissionsGranted.isSuccess &&
          !(permissionsGranted.data ?? false)) {
        permissionsGranted = await _deviceCalendar.requestPermissions();
        if (!permissionsGranted.isSuccess ||
            !(permissionsGranted.data ?? false)) {
          return;
        }
      }

      final calendarsResult = await _deviceCalendar.retrieveCalendars();
      if (!calendarsResult.isSuccess ||
          calendarsResult.data == null ||
          calendarsResult.data!.isEmpty) {
        return;
      }

      final calendar = calendarsResult.data!.firstWhere(
        (c) => !(c.isReadOnly ?? true),
        orElse: () => calendarsResult.data!.first,
      );

      final event = Event(
        calendar.id,
        title: title,
        description: notes,
        start: TZDateTime.from(dateTime, local),
        end: TZDateTime.from(
            dateTime.add(const Duration(hours: 1)), local),
      );

      await _deviceCalendar.createOrUpdateEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita sincronizada con el calendario'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Silently fail calendar sync — non-critical
    }
  }

  Future<void> _deleteEvent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: const Text('¿Seguro que deseas eliminar esta cita?'),
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
      await deleteCalendarEvent(id);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _eventsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios')),
      backgroundColor: kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar
                Card(
                  margin: const EdgeInsets.all(12),
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2100),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) =>
                        isSameDay(d, _selectedDay),
                    eventLoader: _eventsForDay,
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) =>
                        setState(() => _focusedDay = focused),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: kAccent,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    locale: 'es_ES',
                  ),
                ),

                // Events for selected day
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('d \'de\' MMMM', 'es')
                            .format(_selectedDay),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const Spacer(),
                      if (dayEvents.isNotEmpty)
                        Text(
                          '${dayEvents.length} cita${dayEvents.length > 1 ? 's' : ''}',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: dayEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Sin citas este día',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: dayEvents.length,
                          itemBuilder: (ctx, i) {
                            final e = dayEvents[i];
                            final dateStr =
                                e['event_date']?.toString() ?? '';
                            DateTime? dt;
                            if (dateStr.length >= 16) {
                              dt = DateTime.tryParse(dateStr);
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      kPrimary.withValues(alpha: 0.1),
                                  child: Icon(Icons.event,
                                      color: kPrimary),
                                ),
                                title: Text(
                                  e['title']?.toString() ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (dt != null)
                                      Text(
                                        DateFormat('HH:mm').format(dt),
                                        style: TextStyle(
                                            color: kPrimary,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    if (e['notes'] != null &&
                                        e['notes']
                                            .toString()
                                            .isNotEmpty)
                                      Text(
                                        e['notes'].toString(),
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
                                      icon:
                                          const Icon(Icons.edit_outlined),
                                      onPressed: () =>
                                          _showEditDialog(e),
                                      color: kPrimary,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline),
                                      onPressed: () => _deleteEvent(
                                          e['id'].toString()),
                                      color: kError,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
