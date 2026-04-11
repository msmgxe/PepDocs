import React, { useEffect, useState, useCallback } from 'react';
import {
  StyleSheet,
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Modal,
  TextInput,
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import * as Calendar from 'expo-calendar';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useFocusEffect } from 'expo-router';
import { useAuth } from '@/context/AuthContext';
import { supabase } from '@/lib/supabase';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { MaterialCommunityIcons } from '@expo/vector-icons';

const WEEKDAYS = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const MONTHS = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

const NATIVE_KEY = (id: string) => `pep_cal_native_${id}`;

// Normaliza event_date sin importar si viene como 'YYYY-MM-DD' o 'YYYY-MM-DD HH:MM:SS+00'
function toDateStr(eventDate: string): string {
  return (eventDate || '').substring(0, 10);
}

function chunkArray<T>(arr: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < arr.length; i += size) chunks.push(arr.slice(i, i + size));
  return chunks;
}

function buildCalendarDays(year: number, month: number): (number | null)[] {
  const firstDay = new Date(year, month, 1).getDay();
  const adjustedFirst = (firstDay + 6) % 7;
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const days: (number | null)[] = [];
  for (let i = 0; i < adjustedFirst; i++) days.push(null);
  for (let d = 1; d <= daysInMonth; d++) days.push(d);
  while (days.length % 7 !== 0) days.push(null);
  return days;
}

// Obtiene o crea el calendario "Pep Education" en el dispositivo
async function getOrCreatePepCalendar(): Promise<string | null> {
  try {
    const { status } = await Calendar.requestCalendarPermissionsAsync();
    if (status !== 'granted') return null;

    const calendars = await Calendar.getCalendarsAsync(Calendar.EntityTypes.EVENT);
    const existing = calendars.find(c => c.title === 'Pep Education');
    if (existing) return existing.id;

    // Crear calendario nuevo
    const defaultSource =
      Platform.OS === 'ios'
        ? calendars.find(c => c.source?.name === 'Default')?.source ?? { isLocalAccount: true, name: 'Pep Education', type: 'local' }
        : { isLocalAccount: true, name: 'Pep Education', type: 'com.android.calendar' };

    const calId = await Calendar.createCalendarAsync({
      title: 'Pep Education',
      color: '#7B2D8B',
      entityType: Calendar.EntityTypes.EVENT,
      source: defaultSource as any,
      name: 'pep_education',
      ownerAccount: 'personal',
      accessLevel: Calendar.CalendarAccessLevel.OWNER,
    });
    return calId;
  } catch {
    return null;
  }
}

async function addToNativeCalendar(calId: string, title: string, dateStr: string, timeHour: number, timeMin: number, notes: string): Promise<string | null> {
  try {
    const start = new Date(dateStr + 'T12:00:00');
    start.setHours(timeHour, timeMin, 0, 0);
    const end = new Date(start);
    end.setHours(start.getHours() + 1);
    const eventId = await Calendar.createEventAsync(calId, {
      title,
      startDate: start,
      endDate: end,
      notes,
      alarms: [{ relativeOffset: -60 }],
    });
    return eventId;
  } catch {
    return null;
  }
}

async function updateNativeCalendarEvent(nativeId: string, title: string, dateStr: string, timeHour: number, timeMin: number, notes: string): Promise<void> {
  try {
    const start = new Date(dateStr + 'T12:00:00');
    start.setHours(timeHour, timeMin, 0, 0);
    const end = new Date(start);
    end.setHours(start.getHours() + 1);
    await Calendar.updateEventAsync(nativeId, { title, startDate: start, endDate: end, notes });
  } catch {}
}

async function deleteNativeCalendarEvent(nativeId: string): Promise<void> {
  try {
    await Calendar.deleteEventAsync(nativeId);
  } catch {}
}

export default function CalendarScreen() {
  const { user } = useAuth();
  const [profileId, setProfileId] = useState<string | null>(null);
  const [events, setEvents] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [currentMonth, setCurrentMonth] = useState(new Date());
  const [selectedDay, setSelectedDay] = useState<number | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editingEvent, setEditingEvent] = useState<any | null>(null);

  // Form state
  const [formTitle, setFormTitle] = useState('');
  const [formDate, setFormDate] = useState(new Date());
  const [formTime, setFormTime] = useState(() => { const d = new Date(); d.setHours(10, 0, 0, 0); return d; });
  const [formNotes, setFormNotes] = useState('');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);

  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];
  const today = new Date();

  async function fetchData() {
    if (!user) return;
    const { data: profile } = await supabase
      .from('profiles')
      .select('id')
      .eq('auth_uid', user.id)
      .single();
    if (!profile) { setLoading(false); setRefreshing(false); return; }
    setProfileId(profile.id);
    const { data } = await supabase
      .from('calendar_events')
      .select('*')
      .eq('patient_id', profile.id)
      .order('event_date', { ascending: true });
    if (data) setEvents(data);
    setLoading(false);
    setRefreshing(false);
  }

  useEffect(() => { fetchData(); }, [user]);
  useFocusEffect(useCallback(() => { fetchData(); }, [user]));

  const onRefresh = () => { setRefreshing(true); fetchData(); };

  const eventDays = new Set(
    events
      .filter(e => {
        const d = new Date(toDateStr(e.event_date) + 'T12:00:00');
        return d.getFullYear() === currentMonth.getFullYear() &&
          d.getMonth() === currentMonth.getMonth();
      })
      .map(e => new Date(toDateStr(e.event_date) + 'T12:00:00').getDate())
  );

  const calendarDays = buildCalendarDays(currentMonth.getFullYear(), currentMonth.getMonth());
  const weeks = chunkArray(calendarDays, 7);

  function prevMonth() { setCurrentMonth(m => new Date(m.getFullYear(), m.getMonth() - 1, 1)); setSelectedDay(null); }
  function nextMonth() { setCurrentMonth(m => new Date(m.getFullYear(), m.getMonth() + 1, 1)); setSelectedDay(null); }

  const displayedEvents = selectedDay
    ? events.filter(e => {
        const d = new Date(toDateStr(e.event_date) + 'T12:00:00');
        return d.getFullYear() === currentMonth.getFullYear() &&
          d.getMonth() === currentMonth.getMonth() &&
          d.getDate() === selectedDay;
      })
    : events.filter(e => new Date(toDateStr(e.event_date) + 'T12:00:00') >= new Date(today.toDateString()));

  function openNewModal() {
    setEditingEvent(null);
    const d = selectedDay
      ? new Date(currentMonth.getFullYear(), currentMonth.getMonth(), selectedDay)
      : new Date();
    setFormDate(d);
    const t = new Date(); t.setHours(10, 0, 0, 0);
    setFormTime(t);
    setFormTitle('');
    setFormNotes('');
    setShowModal(true);
  }

  function openEditModal(event: any) {
    setEditingEvent(event);
    setFormDate(new Date(toDateStr(event.event_date) + 'T12:00:00'));
    setFormTitle(event.title);
    setFormNotes(event.notes ?? '');
    const t = new Date(); t.setHours(10, 0, 0, 0);
    setFormTime(t);
    setShowModal(true);
  }

  async function saveEvent() {
    if (!formTitle.trim()) { Alert.alert('Error', 'El título es obligatorio'); return; }
    if (!profileId) { Alert.alert('Error', 'No se pudo identificar tu perfil.'); return; }

    const y = formDate.getFullYear();
    const m = String(formDate.getMonth() + 1).padStart(2, '0');
    const d = String(formDate.getDate()).padStart(2, '0');
    const dateStr = `${y}-${m}-${d}`;
    const timeH = formTime.getHours();
    const timeM = formTime.getMinutes();

    setSaving(true);

    if (editingEvent) {
      const { data: updated, error } = await supabase
        .from('calendar_events')
        .update({ title: formTitle.trim(), event_date: dateStr, notes: formNotes.trim() || null })
        .eq('id', editingEvent.id)
        .select('id');
      setSaving(false);
      if (error) { Alert.alert('Error', error.message); return; }
      if (!updated || updated.length === 0) {
        Alert.alert('Sin permisos', 'No se pudo actualizar la cita. Ejecuta el fix de RLS en Supabase.');
        return;
      }
      // Actualizar en calendario nativo
      const nativeId = await AsyncStorage.getItem(NATIVE_KEY(editingEvent.id));
      if (nativeId) {
        await updateNativeCalendarEvent(nativeId, formTitle.trim(), dateStr, timeH, timeM, formNotes.trim());
      }
    } else {
      const { data: inserted, error } = await supabase.from('calendar_events').insert([{
        patient_id: profileId,
        title: formTitle.trim(),
        event_date: dateStr,
        notes: formNotes.trim() || null,
      }]).select('id');
      setSaving(false);
      if (error) { Alert.alert('Error al guardar', error.message); return; }
      if (!inserted || inserted.length === 0) {
        Alert.alert('Sin permisos', 'La cita no se guardó. Ejecuta el fix de RLS en el dashboard de Supabase.');
        return;
      }
      // Agregar al calendario nativo del dispositivo
      const calId = await getOrCreatePepCalendar();
      if (calId) {
        const nativeId = await addToNativeCalendar(calId, formTitle.trim(), dateStr, timeH, timeM, formNotes.trim());
        if (nativeId) {
          await AsyncStorage.setItem(NATIVE_KEY(inserted[0].id), nativeId);
        }
      }
    }

    setShowModal(false);
    fetchData();
  }

  function confirmDelete(event: any) {
    Alert.alert(
      'Eliminar recordatorio',
      `¿Eliminar "${event.title}"?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Eliminar', style: 'destructive',
          onPress: async () => {
            const { error } = await supabase.from('calendar_events').delete().eq('id', event.id);
            if (error) { Alert.alert('Error', error.message); return; }
            // Eliminar del calendario nativo
            const nativeId = await AsyncStorage.getItem(NATIVE_KEY(event.id));
            if (nativeId) {
              await deleteNativeCalendarEvent(nativeId);
              await AsyncStorage.removeItem(NATIVE_KEY(event.id));
            }
            setEvents(prev => prev.filter(e => e.id !== event.id));
          },
        },
      ]
    );
  }

  const formDateLabel = formDate.toLocaleDateString('es-ES', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  const formTimeLabel = `${String(formTime.getHours()).padStart(2, '0')}:${String(formTime.getMinutes()).padStart(2, '0')}`;

  if (loading && !refreshing) {
    return (
      <View style={[styles.container, { backgroundColor: theme.background, justifyContent: 'center', alignItems: 'center' }]}>
        <ActivityIndicator color={theme.lilacDark} />
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <ScrollView
        contentContainerStyle={styles.content}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={theme.lilacDark} />}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Text style={[styles.title, { color: theme.text }]}>Recordatorios</Text>
        </View>

        {/* Month Navigation */}
        <View style={styles.monthNav}>
          <TouchableOpacity onPress={prevMonth} style={styles.monthNavBtn} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
            <MaterialCommunityIcons name="chevron-left" size={24} color={theme.lilacDark} />
          </TouchableOpacity>
          <Text style={[styles.monthTitle, { color: theme.text }]}>
            {MONTHS[currentMonth.getMonth()]} {currentMonth.getFullYear()}
          </Text>
          <TouchableOpacity onPress={nextMonth} style={styles.monthNavBtn} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
            <MaterialCommunityIcons name="chevron-right" size={24} color={theme.lilacDark} />
          </TouchableOpacity>
        </View>

        {/* Calendar Grid */}
        <View style={[styles.calendarGrid, { borderColor: theme.border, backgroundColor: theme.background }]}>
          <View style={styles.weekdayRow}>
            {WEEKDAYS.map(wd => (
              <Text key={wd} style={[styles.weekdayText, { color: theme.icon }]}>{wd}</Text>
            ))}
          </View>
          {weeks.map((week, wi) => (
            <View key={wi} style={styles.weekRow}>
              {week.map((day, di) => {
                const isTodayCell =
                  day !== null &&
                  day === today.getDate() &&
                  currentMonth.getMonth() === today.getMonth() &&
                  currentMonth.getFullYear() === today.getFullYear();
                const isSelected = day !== null && day === selectedDay;
                const hasEvent = day !== null && eventDays.has(day);
                return (
                  <TouchableOpacity
                    key={`${wi}-${di}`}
                    style={[
                      styles.dayCell,
                      isTodayCell && { backgroundColor: theme.lilacDark },
                      isSelected && !isTodayCell && { backgroundColor: theme.lilacLight, borderColor: theme.lilacDark, borderWidth: 1 },
                    ]}
                    onPress={() => day && setSelectedDay(day === selectedDay ? null : day)}
                    disabled={!day}
                    activeOpacity={0.7}
                  >
                    {day !== null && (
                      <>
                        <Text style={[styles.dayText, { color: isTodayCell ? 'white' : theme.text }]}>{day}</Text>
                        {hasEvent && (
                          <View style={[styles.eventDot, { backgroundColor: isTodayCell ? theme.yellow : theme.lilacDark }]} />
                        )}
                      </>
                    )}
                  </TouchableOpacity>
                );
              })}
            </View>
          ))}
        </View>

        {/* Appointments */}
        <View style={styles.appointmentsSection}>
          <Text style={[styles.sectionTitle, { color: theme.text }]}>
            {selectedDay
              ? `Recordatorios del ${selectedDay} de ${MONTHS[currentMonth.getMonth()]}`
              : 'Próximos recordatorios'}
          </Text>

          {displayedEvents.length === 0 ? (
            <View style={[styles.emptyCard, { backgroundColor: theme.lilacPale }]}>
              <MaterialCommunityIcons name="calendar-blank" size={40} color={theme.lilacMedium} />
              <Text style={[styles.emptyText, { color: theme.icon }]}>
                {selectedDay ? 'Sin recordatorios este día' : 'No tienes recordatorios programados'}
              </Text>
            </View>
          ) : (
            displayedEvents.map(item => (
              <View
                key={item.id}
                style={[styles.appointmentItem, { backgroundColor: theme.lilacPale, borderColor: theme.lilacLight }]}
              >
                <MaterialCommunityIcons name="bell-outline" size={20} color="#7B2D8B" />
                <View style={styles.appointmentInfo}>
                  <Text style={[styles.appointmentDate, { color: theme.icon }]}>
                    {new Date(toDateStr(item.event_date) + 'T12:00:00').toLocaleDateString('es-ES', {
                      weekday: 'short', day: 'numeric', month: 'short',
                    })}
                  </Text>
                  <Text style={[styles.appointmentName, { color: theme.text }]}>{item.title}</Text>
                  {item.notes ? (
                    <Text style={[styles.appointmentNotes, { color: theme.icon }]} numberOfLines={1}>{item.notes}</Text>
                  ) : null}
                </View>
                <View style={styles.appointmentActions}>
                  <TouchableOpacity
                    style={[styles.actionBtn, { backgroundColor: theme.lilacLight }]}
                    onPress={() => openEditModal(item)}
                  >
                    <MaterialCommunityIcons name="pencil-outline" size={16} color={theme.lilacDark} />
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[styles.actionBtn, { backgroundColor: '#FEE2E2' }]}
                    onPress={() => confirmDelete(item)}
                  >
                    <MaterialCommunityIcons name="trash-can-outline" size={16} color="#EF4444" />
                  </TouchableOpacity>
                </View>
              </View>
            ))
          )}
        </View>

        <View style={{ height: 80 }} />
      </ScrollView>

      {/* FAB */}
      <TouchableOpacity style={[styles.fab, { backgroundColor: theme.yellow }]} onPress={openNewModal} activeOpacity={0.85}>
        <MaterialCommunityIcons name="plus" size={30} color="#1A1A1A" />
      </TouchableOpacity>

      {/* New / Edit Modal */}
      <Modal visible={showModal} transparent animationType="slide" onRequestClose={() => setShowModal(false)}>
        <KeyboardAvoidingView style={styles.modalOverlay} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
          <TouchableOpacity style={StyleSheet.absoluteFillObject} activeOpacity={1} onPress={() => setShowModal(false)} />
          <View style={[styles.modalCard, { backgroundColor: theme.background }]}>
            <Text style={[styles.modalTitle, { color: theme.text }]}>
              {editingEvent ? 'Editar Recordatorio' : 'Nuevo Recordatorio'}
            </Text>

            <ScrollView showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled" style={{ flexGrow: 0 }}>
              <View style={styles.modalForm}>
                {/* Title */}
                <View>
                  <Text style={[styles.fieldLabel, { color: theme.icon }]}>Título *</Text>
                  <TextInput
                    style={[styles.modalInput, { borderColor: theme.lilacMedium, color: theme.text }]}
                    placeholder="Ej. Consulta con nutricionista"
                    placeholderTextColor={theme.icon}
                    value={formTitle}
                    onChangeText={setFormTitle}
                  />
                </View>

                {/* Date picker */}
                <View>
                  <Text style={[styles.fieldLabel, { color: theme.icon }]}>Fecha</Text>
                  <TouchableOpacity
                    style={[styles.datePickerBtn, { borderColor: theme.lilacMedium, backgroundColor: theme.lilacPale }]}
                    onPress={() => setShowDatePicker(true)}
                  >
                    <MaterialCommunityIcons name="calendar" size={18} color={theme.lilacDark} />
                    <Text style={[styles.datePickerText, { color: theme.text }]}>
                      {formDateLabel.charAt(0).toUpperCase() + formDateLabel.slice(1)}
                    </Text>
                  </TouchableOpacity>
                  {showDatePicker && (
                    <DateTimePicker
                      value={formDate}
                      mode="date"
                      display={Platform.OS === 'android' ? 'default' : 'spinner'}
                      onChange={(_, date) => {
                        setShowDatePicker(Platform.OS === 'ios');
                        if (date) setFormDate(date);
                      }}
                    />
                  )}
                </View>

                {/* Time picker */}
                <View style={{ width: 140 }}>
                  <Text style={[styles.fieldLabel, { color: theme.icon }]}>Hora</Text>
                  <TouchableOpacity
                    style={[styles.datePickerBtn, { borderColor: theme.lilacMedium, backgroundColor: theme.lilacPale }]}
                    onPress={() => setShowTimePicker(true)}
                  >
                    <MaterialCommunityIcons name="clock-outline" size={18} color={theme.lilacDark} />
                    <Text style={[styles.datePickerText, { color: theme.text }]}>{formTimeLabel}</Text>
                  </TouchableOpacity>
                  {showTimePicker && (
                    <DateTimePicker
                      value={formTime}
                      mode="time"
                      is24Hour={true}
                      display={Platform.OS === 'android' ? 'default' : 'spinner'}
                      onChange={(_, time) => {
                        setShowTimePicker(Platform.OS === 'ios');
                        if (time) setFormTime(time);
                      }}
                    />
                  )}
                </View>

                {/* Notes */}
                <View>
                  <Text style={[styles.fieldLabel, { color: theme.icon }]}>Notas (opcional)</Text>
                  <TextInput
                    style={[styles.modalTextarea, { borderColor: theme.lilacMedium, color: theme.text }]}
                    placeholder="Observaciones o recordatorios..."
                    placeholderTextColor={theme.icon}
                    multiline
                    value={formNotes}
                    onChangeText={setFormNotes}
                    textAlignVertical="top"
                  />
                </View>
              </View>
            </ScrollView>

            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalCancelBtn, { borderColor: theme.border }]}
                onPress={() => setShowModal(false)}
              >
                <Text style={[styles.modalCancelText, { color: theme.icon }]}>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalSaveBtn, { backgroundColor: theme.lilacDark }]}
                onPress={saveEvent}
                disabled={saving}
              >
                {saving
                  ? <ActivityIndicator color="white" size="small" />
                  : <MaterialCommunityIcons name="check" size={22} color="white" />}
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { padding: 16, paddingTop: 60, gap: 16 },

  header: { marginBottom: 4 },
  title: { fontSize: 24, fontWeight: '700' },

  monthNav: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  monthNavBtn: { padding: 4 },
  monthTitle: { fontSize: 20, fontWeight: '700' },

  calendarGrid: { borderRadius: 12, borderWidth: 1, padding: 12, gap: 4 },
  weekdayRow: { flexDirection: 'row', marginBottom: 6 },
  weekdayText: { flex: 1, textAlign: 'center', fontSize: 15, fontWeight: '600' },
  weekRow: { flexDirection: 'row' },
  dayCell: {
    flex: 1, aspectRatio: 1, alignItems: 'center', justifyContent: 'center',
    borderRadius: 8, position: 'relative',
  },
  dayText: { fontSize: 17, fontWeight: '600' },
  eventDot: { position: 'absolute', bottom: 3, width: 4, height: 4, borderRadius: 2 },

  appointmentsSection: { gap: 10 },
  sectionTitle: { fontSize: 18, fontWeight: '700' },
  emptyCard: { alignItems: 'center', gap: 10, padding: 24, borderRadius: 12 },
  emptyText: { fontSize: 18 },
  appointmentItem: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    padding: 12, borderRadius: 12, borderWidth: 1,
  },
  appointmentInfo: { flex: 1, gap: 2 },
  appointmentDate: { fontSize: 15, fontWeight: '500' },
  appointmentName: { fontSize: 17, fontWeight: '600' },
  appointmentNotes: { fontSize: 15 },
  appointmentActions: { flexDirection: 'row', gap: 6 },
  actionBtn: { width: 36, height: 36, borderRadius: 8, alignItems: 'center', justifyContent: 'center' },

  fab: {
    position: 'absolute', bottom: 84, right: 16,
    width: 60, height: 60, borderRadius: 30,
    alignItems: 'center', justifyContent: 'center',
    shadowColor: '#7B2D8B', shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3, shadowRadius: 8, elevation: 6,
  },

  modalOverlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: 'rgba(0,0,0,0.5)' },
  modalCard: {
    borderTopLeftRadius: 24, borderTopRightRadius: 24,
    padding: 24, paddingBottom: 32, gap: 16,
    maxHeight: '90%',
    shadowColor: '#000', shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.1, shadowRadius: 12, elevation: 10,
  },
  modalTitle: { fontSize: 22, fontWeight: '700' },
  modalForm: { gap: 14 },
  fieldLabel: { fontSize: 16, fontWeight: '600', marginBottom: 4 },
  modalInput: { borderWidth: 2, borderRadius: 12, padding: 13, fontSize: 18 },
  datePickerBtn: {
    flexDirection: 'row', alignItems: 'center', gap: 10,
    borderWidth: 2, borderRadius: 12, padding: 13,
  },
  datePickerText: { fontSize: 18, fontWeight: '500', flex: 1 },
  modalTextarea: { borderWidth: 2, borderRadius: 12, padding: 13, fontSize: 18, minHeight: 80 },
  modalButtons: { flexDirection: 'row', gap: 12, marginTop: 4 },
  modalCancelBtn: {
    flex: 1, height: 52, borderRadius: 12, borderWidth: 1.5,
    alignItems: 'center', justifyContent: 'center',
  },
  modalCancelText: { fontSize: 19, fontWeight: '600' },
  modalSaveBtn: {
    flex: 2, height: 52, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
  },
  modalSaveText: { color: 'white', fontSize: 19, fontWeight: '700' },
});
