import React, { useState, useEffect, useRef } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  Alert,
  ScrollView,
  RefreshControl,
  Image,
  ActivityIndicator,
  Dimensions,
  Platform,
  Modal,
  KeyboardAvoidingView,
} from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import * as ImagePicker from 'expo-image-picker';
import { Svg, Polyline, Circle, Line, Text as SvgText, Defs, ClipPath, Rect, Polygon } from 'react-native-svg';
import { GestureDetector, Gesture } from 'react-native-gesture-handler';
import { useSharedValue } from 'react-native-reanimated';
import { useAuth } from '@/context/AuthContext';
import { supabase } from '@/lib/supabase';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { MaterialCommunityIcons } from '@expo/vector-icons';

function kgToLbs(kg: number) { return parseFloat((kg * 2.20462).toFixed(1)); }
function lbsToKg(lbs: number) { return parseFloat((lbs / 2.20462).toFixed(2)); }
function fmt(n: number) { return n % 1 === 0 ? n.toFixed(1) : String(n); }

type Period = '1M' | '3M' | '6M' | 'Todo';
const PERIODS: Period[] = ['1M', '3M', '6M', 'Todo'];

function filterByPeriod(measurements: any[], period: Period) {
  if (period === 'Todo') return measurements;
  const days = period === '1M' ? 30 : period === '3M' ? 90 : 180;
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - days);
  return measurements.filter(m => new Date(m.measurement_date) >= cutoff);
}

const SCREEN_W = Dimensions.get('window').width;
// content padding (16×2) + chartSection padding (12×2) = 56
const CHART_W = SCREEN_W - 56;
const CHART_H = 190;
const PAD = { left: 42, right: 8, top: 12, bottom: 30 };

function WeightChart({ measurements, goalWeight, theme }: {
  measurements: any[];
  goalWeight: number;
  theme: typeof Colors.light;
}) {
  const n = measurements.length;
  const [visibleRange, setVisibleRange] = useState<[number, number]>([0, Math.max(0, n - 1)]);

  const currentStart = useSharedValue(0);
  const currentEnd = useSharedValue(Math.max(0, n - 1));
  const savedStart = useSharedValue(0);
  const savedEnd = useSharedValue(Math.max(0, n - 1));

  useEffect(() => {
    const end = Math.max(0, n - 1);
    setVisibleRange([0, end]);
    currentStart.value = 0;
    currentEnd.value = end;
  }, [n]);

  const updateRange = (s: number, e: number) => {
    currentStart.value = s;
    currentEnd.value = e;
    setVisibleRange([s, e]);
  };

  const pinch = Gesture.Pinch()
    .runOnJS(true)
    .onBegin(() => {
      savedStart.value = currentStart.value;
      savedEnd.value = currentEnd.value;
    })
    .onUpdate((e) => {
      const span = savedEnd.value - savedStart.value;
      const mid = (savedStart.value + savedEnd.value) / 2;
      const newSpan = Math.round(span / Math.max(0.1, e.scale));
      const clamped = Math.max(2, Math.min(Math.max(n - 1, 0), newSpan));
      const newStart = Math.max(0, Math.round(mid - clamped / 2));
      const newEnd = Math.min(Math.max(n - 1, 0), newStart + clamped);
      updateRange(newStart, newEnd);
    });

  if (n === 0) {
    return (
      <View style={[styles.chartEmpty, { backgroundColor: theme.lilacPale }]}>
        <Text style={{ color: theme.icon, fontSize: 15 }}>Sin datos para este período</Text>
      </View>
    );
  }

  const [startIdx, endIdx] = visibleRange;
  const visible = measurements.slice(startIdx, endIdx + 1);
  const weights = visible.map(m => parseFloat(m.weight_kg));
  const minW = Math.min(...weights, goalWeight) - 1.5;
  const maxW = Math.max(...weights, goalWeight) + 1.5;

  const innerW = CHART_W - PAD.left - PAD.right;
  const innerH = CHART_H - PAD.top - PAD.bottom;
  const toX = (i: number) => PAD.left + (visible.length <= 1 ? innerW / 2 : (i / (visible.length - 1)) * innerW);
  const toY = (w: number) => PAD.top + innerH - ((w - minW) / Math.max(maxW - minW, 0.1)) * innerH;

  const pts   = visible.map((m, i) => `${toX(i)},${toY(m.weight_kg)}`).join(' ');
  const goalY = toY(goalWeight);
  const areaPoints = visible.length > 1
    ? `${toX(0)},${PAD.top + innerH} ${pts} ${toX(visible.length - 1)},${PAD.top + innerH}`
    : '';
  const yTicks = [minW + 0.5, (minW + maxW) / 2, maxW - 0.5];

  const xLabels: { label: string; x: number }[] = [];
  const step = Math.max(1, Math.ceil(visible.length / 5));
  const nowYear = new Date().getFullYear();
  for (let i = 0; i < visible.length; i++) {
    if (i % step === 0 || i === visible.length - 1) {
      const d = new Date(visible[i].measurement_date);
      const sameYear = d.getFullYear() === nowYear;
      xLabels.push({
        label: d.toLocaleDateString('es-ES', { day: 'numeric', month: 'short', ...(sameYear ? {} : { year: '2-digit' }) }),
        x: toX(i),
      });
    }
  }

  const thumbLeft  = n > 1 ? (startIdx / (n - 1)) * innerW : 0;
  const thumbWidth = n > 1 ? Math.max(12, ((endIdx - startIdx) / (n - 1)) * innerW) : innerW;
  const showScrollbar = endIdx - startIdx < n - 1;

  return (
    <GestureDetector gesture={pinch}>
      <View>
        <Svg width={CHART_W} height={CHART_H}>
          <Defs>
            <ClipPath id="weightClip">
              <Rect x={PAD.left} y={PAD.top} width={innerW} height={innerH} />
            </ClipPath>
          </Defs>
          {/* Grid lines */}
          {yTicks.map((v, i) => (
            <Line key={`g${i}`} x1={PAD.left} y1={toY(v)} x2={PAD.left + innerW} y2={toY(v)}
              stroke={theme.border} strokeWidth={0.8} strokeDasharray="4,3" />
          ))}
          {/* Axis borders */}
          <Line x1={PAD.left} y1={PAD.top} x2={PAD.left} y2={PAD.top + innerH}
            stroke={theme.icon} strokeWidth={1.5} opacity={0.4} />
          <Line x1={PAD.left} y1={PAD.top + innerH} x2={PAD.left + innerW} y2={PAD.top + innerH}
            stroke={theme.icon} strokeWidth={1.5} opacity={0.4} />
          {/* Goal line */}
          <Line x1={PAD.left} y1={goalY} x2={PAD.left + innerW} y2={goalY}
            stroke={theme.yellow} strokeWidth={1.5} strokeDasharray="5,3" clipPath="url(#weightClip)" />
          {/* Area fill */}
          {areaPoints.length > 0 && (
            <Polygon points={areaPoints} fill={theme.lilacDark} fillOpacity={0.08} clipPath="url(#weightClip)" />
          )}
          {/* Line */}
          {visible.length > 1 && (
            <Polyline points={pts} fill="none" stroke={theme.lilacDark} strokeWidth={2.5}
              strokeLinecap="round" strokeLinejoin="round" clipPath="url(#weightClip)" />
          )}
          {/* Points */}
          {visible.map((m, i) => (
            <Circle key={m.id ?? i} cx={toX(i)} cy={toY(m.weight_kg)}
              r={visible.length <= 8 ? 4 : 2.5}
              fill={theme.yellow} stroke={theme.lilacDark} strokeWidth={1.5}
              clipPath="url(#weightClip)" />
          ))}
          {/* Y labels */}
          {yTicks.map((v, i) => (
            <SvgText key={`yt${i}`} x={PAD.left - 4} y={toY(v) + 4} fontSize={9} fill={theme.icon} textAnchor="end">
              {Math.round(v * 10) / 10}
            </SvgText>
          ))}
          {/* X labels */}
          {xLabels.map((l, i) => (
            <SvgText key={`xt${i}`} x={l.x} y={CHART_H - 4} fontSize={9} fill={theme.icon} textAnchor="middle">{l.label}</SvgText>
          ))}
        </Svg>
        {showScrollbar && (
          <View style={[styles.scrollbarTrack, { backgroundColor: theme.border, marginLeft: PAD.left, marginRight: PAD.right }]}>
            <View style={[styles.scrollbarThumb, { backgroundColor: theme.lilacMedium, marginLeft: thumbLeft, width: thumbWidth }]} />
          </View>
        )}
        <Text style={[styles.chartHint, { color: theme.icon }]}>
          Pellizca para hacer zoom · {visible.length} de {n} registros
        </Text>
      </View>
    </GestureDetector>
  );
}

export default function WeightScreen() {
  const [weightDisplay, setWeightDisplay] = useState('');
  const [unit, setUnit] = useState<'kg' | 'lb'>('kg');
  const [showNote, setShowNote] = useState(false);
  const [noteText, setNoteText] = useState('');
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [profile, setProfile] = useState<any>(null);
  const [allHistory, setAllHistory] = useState<any[]>([]);
  const [period, setPeriod] = useState<Period>('3M');
  const [photoUri, setPhotoUri] = useState<string | null>(null);
  const [photoBase64, setPhotoBase64] = useState<string | null>(null);

  // Date picker
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [showDatePicker, setShowDatePicker] = useState(false);

  const inputRef = useRef<TextInput>(null);
  const { user } = useAuth();
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];

  // Multi-select state
  const [selectMode, setSelectMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  // Edit modal state
  const [editItem, setEditItem] = useState<any | null>(null);
  const [editWeight, setEditWeight] = useState('');
  const [editDate, setEditDate] = useState(new Date());
  const [editNote, setEditNote] = useState('');
  const [editUnit, setEditUnit] = useState<'kg' | 'lb'>('kg');
  const [showEditDatePicker, setShowEditDatePicker] = useState(false);
  const [savingEdit, setSavingEdit] = useState(false);
  const [editPhotoUri, setEditPhotoUri] = useState<string | null>(null);
  const [editPhotoBase64, setEditPhotoBase64] = useState<string | null>(null);
  const [editRemovePhoto, setEditRemovePhoto] = useState(false);

  const chartData = filterByPeriod(allHistory, period);
  const listData = [...allHistory].reverse().slice(0, 10);

  async function fetchData() {
    if (!user) return;
    const { data: profileData } = await supabase
      .from('profiles')
      .select('id, current_weight_kg, initial_weight_kg, goal_weight_kg')
      .eq('auth_uid', user.id)
      .single();
    if (profileData) {
      setProfile(profileData);
      const { data: historyData } = await supabase
        .from('measurements')
        .select('*')
        .eq('patient_id', profileData.id)
        .order('measurement_date', { ascending: true });
      if (historyData) setAllHistory(historyData);
    }
    setRefreshing(false);
  }

  useEffect(() => { fetchData(); }, [user]);

  // ── Unit conversion: when toggling, convert the currently entered value ──────
  function handleUnitToggle(newUnit: 'kg' | 'lb') {
    if (newUnit === unit) return;
    const val = parseFloat(weightDisplay);
    if (!isNaN(val) && val > 0) {
      if (newUnit === 'lb') {
        setWeightDisplay(fmt(kgToLbs(val)));
      } else {
        setWeightDisplay(fmt(lbsToKg(val)));
      }
    }
    setUnit(newUnit);
  }

  const weightKg = (() => {
    const val = parseFloat(weightDisplay);
    if (isNaN(val) || val <= 0) return 0;
    return unit === 'kg' ? val : lbsToKg(val);
  })();

  const equivalenceLabel = (() => {
    const val = parseFloat(weightDisplay);
    if (!val || isNaN(val)) return '';
    return unit === 'kg' ? `= ${kgToLbs(val)} lbs` : `= ${fmt(lbsToKg(val))} kg`;
  })();

  const motivationMsg = (() => {
    if (!profile?.goal_weight_kg || !weightKg) return '¡Cada pesaje es un paso hacia tu meta!';
    const diff = weightKg - profile.goal_weight_kg;
    if (diff <= 0) return '¡Alcanzaste tu meta! Increíble logro.';
    if (diff <= 2) return `¡Estás a solo ${diff.toFixed(1)} kg de tu meta!`;
    if (diff <= 5) return `¡Vas muy bien! Solo ${diff.toFixed(1)} kg más.`;
    return '¡Sigue adelante, cada gramo cuenta!';
  })();

  const progressPercent = (() => {
    if (!profile?.initial_weight_kg || !profile?.goal_weight_kg || !profile?.current_weight_kg) return 0;
    const total = profile.initial_weight_kg - profile.goal_weight_kg;
    const done = profile.initial_weight_kg - profile.current_weight_kg;
    if (total <= 0) return 100;
    return Math.min(100, Math.max(0, (done / total) * 100));
  })();

  async function pickFromGallery() {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== 'granted') { Alert.alert('Permiso requerido', 'Necesitamos acceso a tu galería.'); return; }
    const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], allowsEditing: false, quality: 0.6, base64: true });
    if (!result.canceled) { setPhotoUri(result.assets[0].uri); setPhotoBase64(result.assets[0].base64 ?? null); }
  }

  async function takePhoto() {
    try {
      const { status } = await ImagePicker.requestCameraPermissionsAsync();
      if (status !== 'granted') { Alert.alert('Permiso requerido', 'Necesitamos acceso a tu cámara.'); return; }
      const result = await ImagePicker.launchCameraAsync({ allowsEditing: false, quality: 0.6, base64: true });
      if (!result.canceled) { setPhotoUri(result.assets[0].uri); setPhotoBase64(result.assets[0].base64 ?? null); }
    } catch { Alert.alert('Cámara no disponible', 'Usa la galería para seleccionar una foto.'); }
  }

  async function pickFromGalleryEdit() {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== 'granted') { Alert.alert('Permiso requerido', 'Necesitamos acceso a tu galería.'); return; }
    const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], allowsEditing: false, quality: 0.6, base64: true });
    if (!result.canceled) { setEditPhotoUri(result.assets[0].uri); setEditPhotoBase64(result.assets[0].base64 ?? null); setEditRemovePhoto(false); }
  }

  async function takePhotoEdit() {
    try {
      const { status } = await ImagePicker.requestCameraPermissionsAsync();
      if (status !== 'granted') { Alert.alert('Permiso requerido', 'Necesitamos acceso a tu cámara.'); return; }
      const result = await ImagePicker.launchCameraAsync({ allowsEditing: false, quality: 0.6, base64: true });
      if (!result.canceled) { setEditPhotoUri(result.assets[0].uri); setEditPhotoBase64(result.assets[0].base64 ?? null); setEditRemovePhoto(false); }
    } catch { Alert.alert('Cámara no disponible', 'Usa la galería para seleccionar una foto.'); }
  }

  // Upload usando base64 — evita el error "Network request failed" en Android
  // que ocurre al hacer fetch() sobre URIs content:// locales
  async function uploadPhoto(patientId: string, b64?: string | null): Promise<string | null> {
    const base64Data = b64 ?? photoBase64;
    if (!base64Data) return null;
    setUploading(true);
    try {
      const fileName = `${patientId}/${Date.now()}.jpg`;
      // Decodificar base64 a ArrayBuffer sin depender de expo-file-system
      const binaryStr = atob(base64Data);
      const bytes = new Uint8Array(binaryStr.length);
      for (let i = 0; i < binaryStr.length; i++) bytes[i] = binaryStr.charCodeAt(i);
      const { data: uploadData, error } = await supabase.storage
        .from('patient-photos')
        .upload(fileName, bytes.buffer, { contentType: 'image/jpeg', upsert: false });
      if (error) { Alert.alert('Error', 'No se pudo subir la foto. Intenta de nuevo.'); return null; }
      const { data } = supabase.storage.from('patient-photos').getPublicUrl(uploadData.path);
      return data.publicUrl;
    } catch {
      Alert.alert('Error', 'No se pudo subir la foto. Intenta de nuevo.');
      return null;
    } finally {
      setUploading(false);
    }
  }

  async function saveWeight() {
    if (!weightDisplay || isNaN(parseFloat(weightDisplay))) { Alert.alert('Error', 'Por favor ingresa un peso válido'); return; }
    const displayVal = parseFloat(weightDisplay);
    const finalKgCheck = unit === 'kg' ? displayVal : lbsToKg(displayVal);
    if (finalKgCheck < 1 || finalKgCheck > 600) { Alert.alert('Peso fuera de rango', 'Ingresa un valor entre 1 y 600 kg.'); return; }
    if (!profile) { Alert.alert('Error', 'No se encontró tu perfil. Intenta recargar.'); return; }
    setLoading(true);
    const photoUrl = await uploadPhoto(profile.id, photoBase64);
    const finalWeightKg = unit === 'kg' ? parseFloat(weightDisplay) : lbsToKg(parseFloat(weightDisplay));
    const dateStr = selectedDate.toISOString().split('T')[0];
    const insertPayload: any = {
      patient_id: profile.id,
      weight_kg: finalWeightKg,
      measurement_date: dateStr,
      notes: noteText || 'Registrado desde la app móvil',
    };
    if (photoUrl) insertPayload.photo_url = photoUrl;
    const { error } = await supabase.from('measurements').insert([insertPayload]);
    if (error) {
      Alert.alert('Error', 'No se pudo guardar el registro. Intenta de nuevo.');
    } else {
      // Update current_weight_kg with the latest measurement by date
      const latestDate = [...allHistory.map(m => m.measurement_date), dateStr].sort().reverse()[0];
      if (dateStr >= latestDate) {
        await supabase.from('profiles').update({ current_weight_kg: finalWeightKg }).eq('id', profile.id);
      }
      Alert.alert('¡Guardado!', 'Tu peso ha sido registrado correctamente.');
      setWeightDisplay(''); setNoteText(''); setShowNote(false); setPhotoUri(null); setPhotoBase64(null);
      setSelectedDate(new Date());
      fetchData();
    }
    setLoading(false);
  }

  // ── Delete one or many measurements ──────────────────────────────────────────
  async function performDelete(ids: string[]) {
    const snapshot = allHistory;
    const remaining = snapshot.filter(m => !ids.includes(m.id));
    setAllHistory(remaining);
    setSelectedIds([]);
    setSelectMode(false);

    const { error } = await supabase
      .from('measurements')
      .delete()
      .in('id', ids);

    if (error) {
      setAllHistory(snapshot);
      Alert.alert('Error', 'No se pudieron eliminar los registros. Intenta de nuevo.');
      return;
    }

    // Verify the rows are actually gone (silent RLS blocks return no error but delete nothing)
    const { data: stillExists } = await supabase
      .from('measurements')
      .select('id')
      .in('id', ids);

    if (stillExists && stillExists.length > 0) {
      setAllHistory(snapshot);
      Alert.alert('Error al eliminar', `No se eliminaron los registros (${stillExists.length} aún existen). Intenta de nuevo.`);
      return;
    }

    if (profile) {
      if (remaining.length > 0) {
        const latest = [...remaining].sort((a, b) =>
          new Date(b.measurement_date).getTime() - new Date(a.measurement_date).getTime()
        )[0];
        await supabase.from('profiles').update({ current_weight_kg: latest.weight_kg }).eq('id', profile.id);
        setProfile((p: any) => p ? { ...p, current_weight_kg: latest.weight_kg } : p);
      } else {
        await supabase.from('profiles').update({ current_weight_kg: null }).eq('id', profile.id);
        setProfile((p: any) => p ? { ...p, current_weight_kg: null } : p);
      }
    }
  }

  function deleteRecord(item: any) {
    Alert.alert(
      'Eliminar registro',
      `¿Eliminar el registro de ${item.weight_kg} kg del ${new Date(item.measurement_date).toLocaleDateString('es-ES', { day: 'numeric', month: 'long', year: 'numeric' })}?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        { text: 'Eliminar', style: 'destructive', onPress: () => performDelete([item.id]) },
      ]
    );
  }

  function deleteSelected() {
    Alert.alert(
      'Eliminar registros',
      `¿Eliminar ${selectedIds.length} registro${selectedIds.length > 1 ? 's' : ''}?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        { text: 'Eliminar', style: 'destructive', onPress: () => performDelete(selectedIds) },
      ]
    );
  }

  function toggleSelect(id: string) {
    setSelectedIds(prev =>
      prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]
    );
  }

  function openEdit(item: any) {
    setEditItem(item);
    setEditWeight(String(item.weight_kg));
    setEditUnit('kg');
    setEditDate(new Date(item.measurement_date + 'T12:00:00'));
    setEditNote(item.notes === 'Registrado desde la app móvil' ? '' : (item.notes ?? ''));
    setSavingEdit(false);
    setEditPhotoUri(null);
    setEditPhotoBase64(null);
    setEditRemovePhoto(false);
  }

  async function saveEdit() {
    if (!editItem) return;
    const wKg = editUnit === 'kg' ? parseFloat(editWeight) : lbsToKg(parseFloat(editWeight));
    if (isNaN(wKg) || wKg <= 0) { Alert.alert('Error', 'Ingresa un peso válido'); return; }
    const dateStr = editDate.toISOString().split('T')[0];
    setSavingEdit(true);

    // Resolve photo_url: upload new, remove, or keep existing (undefined = no change)
    let newPhotoUrl: string | null | undefined = undefined;
    if (editPhotoBase64) {
      const uploaded = await uploadPhoto(profile?.id ?? editItem.patient_id, editPhotoBase64);
      if (uploaded === null) {
        // Upload failed — Alert already shown inside uploadPhoto; abort save
        setSavingEdit(false);
        return;
      }
      newPhotoUrl = uploaded;
    } else if (editRemovePhoto) {
      newPhotoUrl = null;
    }

    const updatePayload: any = {
      weight_kg: wKg,
      measurement_date: dateStr,
      notes: editNote || 'Registrado desde la app móvil',
    };
    if (newPhotoUrl !== undefined) updatePayload.photo_url = newPhotoUrl;

    const { error } = await supabase
      .from('measurements')
      .update(updatePayload)
      .eq('id', editItem.id);
    setSavingEdit(false);
    if (error) { Alert.alert('Error', 'No se pudo actualizar el registro. Intenta de nuevo.'); return; }

    const resolvedPhoto = newPhotoUrl !== undefined ? newPhotoUrl : editItem.photo_url;
    setAllHistory(prev => prev.map(m =>
      m.id === editItem.id
        ? { ...m, weight_kg: wKg, measurement_date: dateStr, notes: updatePayload.notes, photo_url: resolvedPhoto }
        : m
    ));
    if (profile) {
      const updated = allHistory.map(m =>
        m.id === editItem.id ? { ...m, weight_kg: wKg, measurement_date: dateStr } : m
      );
      const latest = [...updated].sort((a, b) =>
        new Date(b.measurement_date).getTime() - new Date(a.measurement_date).getTime()
      )[0];
      await supabase.from('profiles').update({ current_weight_kg: latest.weight_kg }).eq('id', profile.id);
      setProfile((p: any) => p ? { ...p, current_weight_kg: latest.weight_kg } : p);
    }
    setEditItem(null);
  }

  const onRefresh = () => { setRefreshing(true); fetchData(); };

  const dateLabel = selectedDate.toLocaleDateString('es-ES', { weekday: 'long', day: 'numeric', month: 'long' });
  const isToday = selectedDate.toISOString().split('T')[0] === new Date().toISOString().split('T')[0];

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
    <ScrollView
      style={{ flex: 1 }}
      contentContainerStyle={styles.content}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={theme.lilacDark} />}
      keyboardShouldPersistTaps="handled"
    >
      {/* Header */}
      <View style={styles.headerSection}>
        <Text style={[styles.title, { color: theme.text }]}>Registrar Peso</Text>
        {/* Date selector */}
        <TouchableOpacity
          style={[styles.datePicker, { borderColor: theme.lilacMedium, backgroundColor: theme.lilacPale }]}
          onPress={() => setShowDatePicker(true)}
        >
          <MaterialCommunityIcons name="calendar" size={16} color={theme.lilacDark} />
          <Text style={[styles.datePickerText, { color: theme.lilacDark }]}>
            {isToday ? 'Hoy, ' : ''}{dateLabel.charAt(0).toUpperCase() + dateLabel.slice(1)}
          </Text>
          <MaterialCommunityIcons name="chevron-down" size={16} color={theme.lilacMedium} />
        </TouchableOpacity>
        {showDatePicker && (
          <DateTimePicker
            value={selectedDate}
            mode="date"
            display={Platform.OS === 'android' ? 'default' : 'spinner'}
            maximumDate={new Date()}
            onChange={(_, date) => {
              setShowDatePicker(Platform.OS === 'ios');
              if (date) setSelectedDate(date);
            }}
          />
        )}
      </View>

      {/* Circle Weight Input */}
      <View style={styles.weightInputContainer}>
        <TouchableOpacity
          style={[styles.weightCircle, { borderColor: theme.lilacMedium, backgroundColor: theme.lilacPale }]}
          onPress={() => inputRef.current?.focus()}
          activeOpacity={0.8}
        >
          <Text style={[styles.weightCircleValue, { color: theme.lilacDark }]}>{weightDisplay || '0.0'}</Text>
          <Text style={[styles.weightCircleUnit, { color: theme.lilacMedium }]}>{unit}</Text>
        </TouchableOpacity>
        <TextInput ref={inputRef} style={styles.hiddenInput} value={weightDisplay} onChangeText={setWeightDisplay} keyboardType="decimal-pad" caretHidden />
        <View style={styles.unitToggle}>
          {(['kg', 'lb'] as const).map(u => (
            <TouchableOpacity
              key={u}
              style={[styles.unitBtn, { borderColor: theme.lilacMedium, backgroundColor: unit === u ? theme.lilacDark : theme.background }]}
              onPress={() => handleUnitToggle(u)}
            >
              <Text style={[styles.unitBtnText, { color: unit === u ? 'white' : theme.text }]}>{u}</Text>
            </TouchableOpacity>
          ))}
        </View>
        {equivalenceLabel ? <Text style={[styles.equivalence, { color: theme.icon }]}>{equivalenceLabel}</Text> : null}
        <Text style={[styles.motivation, { color: theme.text }]}>{motivationMsg}</Text>
      </View>

      {/* Progress Bar */}
      <View style={styles.progressSection}>
        <Text style={[styles.progressLabel, { color: theme.text }]}>Progreso hacia tu meta</Text>
        <View style={[styles.progressBarBg, { backgroundColor: theme.border }]}>
          <View style={[styles.progressBarFill, { width: `${progressPercent}%` as any, backgroundColor: theme.yellow }]} />
        </View>
        <Text style={[styles.progressText, { color: theme.icon }]}>
          {profile?.current_weight_kg && profile?.goal_weight_kg
            ? `${Math.max(0, profile.current_weight_kg - profile.goal_weight_kg).toFixed(1)} kg para llegar a ${profile.goal_weight_kg} kg`
            : 'Registra tu peso para ver el progreso'}
        </Text>
      </View>

      {/* Chart */}
      {allHistory.length > 0 && (
        <View style={[styles.chartSection, { backgroundColor: theme.lilacPale, borderColor: theme.border }]}>
          <Text style={[styles.sectionTitle, { color: theme.text, marginBottom: 10 }]}>Evolución del peso</Text>
          <View style={styles.periodTabs}>
            {PERIODS.map(p => (
              <TouchableOpacity
                key={p}
                style={[styles.periodTab, { borderColor: theme.lilacMedium, backgroundColor: period === p ? theme.lilacDark : 'transparent' }]}
                onPress={() => setPeriod(p)}
              >
                <Text style={[styles.periodTabText, { color: period === p ? 'white' : theme.lilacDark }]}>{p}</Text>
              </TouchableOpacity>
            ))}
          </View>
          <WeightChart measurements={chartData} goalWeight={profile?.goal_weight_kg ?? 70} theme={theme} />
        </View>
      )}

      {/* Note */}
      <TouchableOpacity style={[styles.noteToggle, { borderColor: theme.lilacMedium }]} onPress={() => setShowNote(!showNote)}>
        <MaterialCommunityIcons name={showNote ? 'note-minus-outline' : 'note-plus-outline'} size={20} color={theme.lilacDark} />
        <Text style={[styles.noteToggleText, { color: theme.lilacDark }]}>{showNote ? 'Ocultar nota' : 'Agregar nota (opcional)'}</Text>
      </TouchableOpacity>
      {showNote && (
        <TextInput
          style={[styles.noteTextarea, { borderColor: theme.lilacMedium, color: theme.text }]}
          placeholder="¿Cómo te sientes hoy? ¿Algo especial que quieras anotar?"
          placeholderTextColor={theme.icon}
          multiline value={noteText} onChangeText={setNoteText} textAlignVertical="top"
        />
      )}

      {/* Photo */}
      <View style={[styles.photoSection, { backgroundColor: theme.lilacPale, borderColor: theme.lilacMedium }]}>
        <View style={styles.photoHeader}>
          <MaterialCommunityIcons name="camera-outline" size={20} color={theme.lilacDark} />
          <Text style={[styles.photoLabel, { color: theme.lilacDark }]}>Foto de progreso (opcional)</Text>
        </View>
        {photoUri ? (
          <View style={styles.photoPreviewContainer}>
            <Image source={{ uri: photoUri }} style={styles.photoPreview} />
            <TouchableOpacity style={[styles.removePhotoBtn, { backgroundColor: theme.lilacDark }]} onPress={() => setPhotoUri(null)}>
              <MaterialCommunityIcons name="close" size={18} color="white" />
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.photoButtons}>
            <TouchableOpacity style={[styles.photoBtn, { borderColor: theme.lilacDark }]} onPress={takePhoto}>
              <MaterialCommunityIcons name="camera" size={22} color={theme.lilacDark} />
              <Text style={[styles.photoBtnText, { color: theme.lilacDark }]}>Cámara</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.photoBtn, { borderColor: theme.lilacDark }]} onPress={pickFromGallery}>
              <MaterialCommunityIcons name="image-multiple" size={22} color={theme.lilacDark} />
              <Text style={[styles.photoBtnText, { color: theme.lilacDark }]}>Galería</Text>
            </TouchableOpacity>
          </View>
        )}
      </View>

      {/* Save Button */}
      <TouchableOpacity style={[styles.saveButton, { backgroundColor: theme.yellow }]} onPress={saveWeight} disabled={loading || uploading}>
        {loading || uploading
          ? <ActivityIndicator color="#1A1A1A" />
          : <Text style={styles.saveButtonText}>Guardar Pesaje</Text>}
      </TouchableOpacity>

      {/* History list with delete / multi-select */}
      {listData.length > 0 && (
        <View style={styles.historySection}>
          <View style={styles.historyHeader}>
            <Text style={[styles.sectionTitle, { color: theme.text }]}>Historial reciente</Text>
            <TouchableOpacity
              style={[styles.selectToggleBtn, { borderColor: selectMode ? '#EF4444' : theme.lilacMedium }]}
              onPress={() => { setSelectMode(s => !s); setSelectedIds([]); }}
            >
              <Text style={[styles.selectToggleText, { color: selectMode ? '#EF4444' : theme.lilacDark }]}>
                {selectMode ? 'Cancelar' : 'Seleccionar'}
              </Text>
            </TouchableOpacity>
          </View>

          {selectMode && selectedIds.length > 0 && (
            <TouchableOpacity
              style={styles.bulkDeleteBtn}
              onPress={deleteSelected}
            >
              <MaterialCommunityIcons name="trash-can-outline" size={18} color="white" />
              <Text style={styles.bulkDeleteText}>Eliminar {selectedIds.length} seleccionado{selectedIds.length > 1 ? 's' : ''}</Text>
            </TouchableOpacity>
          )}

          {listData.map(item => {
            const isChecked = selectedIds.includes(item.id);
            return (
              <TouchableOpacity
                key={item.id}
                style={[
                  styles.historyRow,
                  { borderBottomColor: theme.border },
                  isChecked && { backgroundColor: theme.lilacPale },
                ]}
                onPress={() => selectMode ? toggleSelect(item.id) : undefined}
                activeOpacity={selectMode ? 0.7 : 1}
              >
                {selectMode && (
                  <View style={[styles.checkbox, { borderColor: isChecked ? '#EF4444' : theme.border, backgroundColor: isChecked ? '#FEE2E2' : 'transparent' }]}>
                    {isChecked && <MaterialCommunityIcons name="check" size={14} color="#EF4444" />}
                  </View>
                )}
                <View style={styles.historyLeft}>
                  {item.photo_url ? (
                    <Image source={{ uri: item.photo_url }} style={styles.historyThumb} />
                  ) : (
                    <View style={[styles.historyThumbPlaceholder, { backgroundColor: theme.lilacPale }]}>
                      <MaterialCommunityIcons name="camera-off-outline" size={16} color={theme.icon} />
                    </View>
                  )}
                  <View>
                    <Text style={[styles.historyDate, { color: theme.text }]}>
                      {new Date(item.measurement_date).toLocaleDateString('es-ES', { day: 'numeric', month: 'long' })}
                    </Text>
                    {item.notes && item.notes !== 'Registrado desde la app móvil' && (
                      <Text style={[styles.historyNote, { color: theme.icon }]} numberOfLines={1}>{item.notes}</Text>
                    )}
                  </View>
                </View>
                <View style={styles.historyRight}>
                  <Text style={[styles.historyWeight, { color: theme.lilacDark }]}>{item.weight_kg} kg</Text>
                  {!selectMode && (
                    <>
                      <TouchableOpacity
                        style={[styles.deleteBtn, { backgroundColor: theme.lilacLight }]}
                        onPress={() => openEdit(item)}
                      >
                        <MaterialCommunityIcons name="pencil-outline" size={16} color={theme.lilacDark} />
                      </TouchableOpacity>
                      <TouchableOpacity
                        style={[styles.deleteBtn, { backgroundColor: '#FEE2E2' }]}
                        onPress={() => deleteRecord(item)}
                      >
                        <MaterialCommunityIcons name="trash-can-outline" size={16} color="#EF4444" />
                      </TouchableOpacity>
                    </>
                  )}
                </View>
              </TouchableOpacity>
            );
          })}
        </View>
      )}
    </ScrollView>

    {/* ── Edit record modal ─────────────────────────────────────────────── */}
    <Modal visible={!!editItem} transparent animationType="slide" onRequestClose={() => setEditItem(null)}>
      <KeyboardAvoidingView style={styles.modalOverlay} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
        <TouchableOpacity style={StyleSheet.absoluteFillObject} activeOpacity={1} onPress={() => setEditItem(null)} />
        <View style={[styles.modalCard, { backgroundColor: theme.background }]}>
          <Text style={[styles.modalTitle, { color: theme.text }]}>Editar registro</Text>
          <ScrollView showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled" style={{ flexGrow: 0 }} contentContainerStyle={{ gap: 16, paddingBottom: 8 }}>

          {/* Weight input */}
          <View>
            <Text style={[styles.fieldLabel, { color: theme.icon }]}>Peso</Text>
            <View style={styles.editWeightRow}>
              <TextInput
                style={[styles.editWeightInput, { borderColor: theme.lilacMedium, color: theme.text }]}
                value={editWeight}
                onChangeText={setEditWeight}
                keyboardType="decimal-pad"
              />
              <View style={styles.editUnitToggle}>
                {(['kg', 'lb'] as const).map(u => (
                  <TouchableOpacity
                    key={u}
                    style={[styles.editUnitBtn, { borderColor: theme.lilacMedium, backgroundColor: editUnit === u ? theme.lilacDark : 'transparent' }]}
                    onPress={() => {
                      const val = parseFloat(editWeight);
                      if (!isNaN(val)) {
                        setEditWeight(u === 'lb' && editUnit === 'kg' ? fmt(kgToLbs(val)) : u === 'kg' && editUnit === 'lb' ? fmt(lbsToKg(val)) : editWeight);
                      }
                      setEditUnit(u);
                    }}
                  >
                    <Text style={{ color: editUnit === u ? 'white' : theme.text, fontSize: 15, fontWeight: '700' }}>{u}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          </View>

          {/* Date */}
          <View>
            <Text style={[styles.fieldLabel, { color: theme.icon }]}>Fecha</Text>
            <TouchableOpacity
              style={[styles.editDateBtn, { borderColor: theme.lilacMedium, backgroundColor: theme.lilacPale }]}
              onPress={() => setShowEditDatePicker(true)}
            >
              <MaterialCommunityIcons name="calendar" size={18} color={theme.lilacDark} />
              <Text style={{ color: theme.text, fontSize: 16, flex: 1 }}>
                {editDate.toLocaleDateString('es-ES', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
              </Text>
            </TouchableOpacity>
            {showEditDatePicker && (
              <DateTimePicker
                value={editDate}
                mode="date"
                display={Platform.OS === 'android' ? 'default' : 'spinner'}
                maximumDate={new Date()}
                onChange={(_, date) => { setShowEditDatePicker(Platform.OS === 'ios'); if (date) setEditDate(date); }}
              />
            )}
          </View>

          {/* Note */}
          <View>
            <Text style={[styles.fieldLabel, { color: theme.icon }]}>Nota (opcional)</Text>
            <TextInput
              style={[styles.editNoteInput, { borderColor: theme.lilacMedium, color: theme.text }]}
              placeholder="Ej. Después de entrenar..."
              placeholderTextColor={theme.icon}
              value={editNote}
              onChangeText={setEditNote}
              multiline
              textAlignVertical="top"
            />
          </View>

          {/* Photo section */}
          <View>
            <Text style={[styles.fieldLabel, { color: theme.icon }]}>Foto de progreso</Text>
            {editPhotoUri ? (
              <View style={styles.photoPreviewContainer}>
                <Image source={{ uri: editPhotoUri }} style={styles.photoPreview} />
                <TouchableOpacity
                  style={[styles.removePhotoBtn, { backgroundColor: '#EF4444' }]}
                  onPress={() => setEditPhotoUri(null)}
                >
                  <MaterialCommunityIcons name="close" size={16} color="white" />
                </TouchableOpacity>
              </View>
            ) : (editItem?.photo_url && !editRemovePhoto) ? (
              <View style={{ gap: 8 }}>
                <View style={styles.photoPreviewContainer}>
                  <Image source={{ uri: editItem.photo_url }} style={styles.photoPreview} />
                </View>
                <TouchableOpacity
                  style={[styles.editPhotoActionBtn, { borderColor: '#EF4444' }]}
                  onPress={() => setEditRemovePhoto(true)}
                >
                  <MaterialCommunityIcons name="trash-can-outline" size={16} color="#EF4444" />
                  <Text style={{ color: '#EF4444', fontSize: 15, fontWeight: '600' }}>Eliminar foto</Text>
                </TouchableOpacity>
              </View>
            ) : (
              <View style={styles.photoButtons}>
                <TouchableOpacity
                  style={[styles.photoBtn, { borderColor: theme.lilacMedium }]}
                  onPress={takePhotoEdit}
                >
                  <MaterialCommunityIcons name="camera-outline" size={18} color={theme.lilacDark} />
                  <Text style={[styles.photoBtnText, { color: theme.lilacDark }]}>Cámara</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.photoBtn, { borderColor: theme.lilacMedium }]}
                  onPress={pickFromGalleryEdit}
                >
                  <MaterialCommunityIcons name="image-outline" size={18} color={theme.lilacDark} />
                  <Text style={[styles.photoBtnText, { color: theme.lilacDark }]}>Galería</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
          </ScrollView>

          <View style={[styles.modalButtons, { marginTop: 8 }]}>
            <TouchableOpacity style={[styles.modalCancelBtn, { borderColor: theme.border }]} onPress={() => setEditItem(null)}>
              <Text style={[styles.modalCancelText, { color: theme.icon }]}>Cancelar</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.modalSaveBtn, { backgroundColor: theme.lilacDark }]} onPress={saveEdit} disabled={savingEdit}>
              {savingEdit
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
  content: { padding: 16, paddingTop: 60, paddingBottom: 40, gap: 20 },

  headerSection: { alignItems: 'center', gap: 10 },
  title: { fontSize: 24, fontWeight: '700' },

  datePicker: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingHorizontal: 16, paddingVertical: 8, borderRadius: 12, borderWidth: 1.5 },
  datePickerText: { fontSize: 15, fontWeight: '600', textTransform: 'capitalize' },

  weightInputContainer: { alignItems: 'center', gap: 16 },
  weightCircle: { width: 200, height: 200, borderRadius: 100, borderWidth: 3, alignItems: 'center', justifyContent: 'center', gap: 4 },
  weightCircleValue: { fontSize: 58, fontWeight: '700', lineHeight: 66 },
  weightCircleUnit: { fontSize: 18, fontWeight: '600' },
  hiddenInput: { position: 'absolute', opacity: 0, width: 1, height: 1 },

  unitToggle: { flexDirection: 'row', gap: 8 },
  unitBtn: { paddingHorizontal: 20, paddingVertical: 8, borderRadius: 12, borderWidth: 2 },
  unitBtnText: { fontSize: 15, fontWeight: '600' },
  equivalence: { fontSize: 15 },
  motivation: { fontSize: 16, fontWeight: '500', textAlign: 'center', paddingHorizontal: 20 },

  progressSection: { gap: 8 },
  progressLabel: { fontSize: 14, fontWeight: '600' },
  progressBarBg: { height: 12, borderRadius: 6, overflow: 'hidden' },
  progressBarFill: { height: '100%', borderRadius: 6 },
  progressText: { fontSize: 13 },

  chartSection: { borderRadius: 16, padding: 12, borderWidth: 1 },
  periodTabs: { flexDirection: 'row', gap: 6, marginBottom: 10 },
  periodTab: { flex: 1, paddingVertical: 6, borderRadius: 8, borderWidth: 1.5, alignItems: 'center' },
  periodTabText: { fontSize: 14, fontWeight: '700' },
  chartEmpty: { height: 80, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  scrollbarTrack: { height: 3, borderRadius: 2, marginTop: 4 },
  scrollbarThumb: { height: 3, borderRadius: 2 },
  chartHint: { fontSize: 12, textAlign: 'center', marginTop: 6 },

  noteToggle: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, padding: 12, borderWidth: 2, borderRadius: 12 },
  noteToggleText: { fontSize: 16, fontWeight: '600' },
  noteTextarea: { borderWidth: 2, borderRadius: 12, padding: 12, fontSize: 16, minHeight: 80 },

  photoSection: { borderRadius: 16, padding: 16, gap: 12, borderWidth: 1, borderStyle: 'dashed' },
  photoHeader: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  photoLabel: { fontSize: 16, fontWeight: '600' },
  photoButtons: { flexDirection: 'row', gap: 12 },
  photoBtn: { flex: 1, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, paddingVertical: 12, borderRadius: 12, borderWidth: 1.5 },
  photoBtnText: { fontSize: 16, fontWeight: '600' },
  photoPreviewContainer: { position: 'relative', alignSelf: 'center' },
  photoPreview: { width: 120, height: 160, borderRadius: 12 },
  removePhotoBtn: { position: 'absolute', top: -10, right: -10, width: 28, height: 28, borderRadius: 14, alignItems: 'center', justifyContent: 'center' },

  saveButton: { height: 56, borderRadius: 16, alignItems: 'center', justifyContent: 'center', shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.15, shadowRadius: 8, elevation: 4 },
  saveButtonText: { fontSize: 19, fontWeight: '700', color: '#1A1A1A' },

  historySection: { gap: 12 },
  sectionTitle: { fontSize: 18, fontWeight: '700' },
  historyHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  selectToggleBtn: { paddingHorizontal: 12, paddingVertical: 5, borderRadius: 8, borderWidth: 1.5 },
  selectToggleText: { fontSize: 14, fontWeight: '700' },
  bulkDeleteBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, backgroundColor: '#EF4444', borderRadius: 10, paddingVertical: 10 },
  bulkDeleteText: { color: 'white', fontSize: 16, fontWeight: '700' },
  checkbox: { width: 22, height: 22, borderRadius: 6, borderWidth: 2, alignItems: 'center', justifyContent: 'center', marginRight: 4 },
  historyRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 10, borderBottomWidth: 1, borderRadius: 6, paddingHorizontal: 4 },
  historyLeft: { flexDirection: 'row', alignItems: 'center', gap: 12, flex: 1 },
  historyRight: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  historyThumb: { width: 44, height: 58, borderRadius: 8 },
  historyThumbPlaceholder: { width: 44, height: 58, borderRadius: 8, alignItems: 'center', justifyContent: 'center' },
  historyDate: { fontSize: 16, fontWeight: '600' },
  historyNote: { fontSize: 14, marginTop: 2, maxWidth: 160 },
  historyWeight: { fontSize: 20, fontWeight: '700' },
  deleteBtn: { width: 32, height: 32, borderRadius: 8, alignItems: 'center', justifyContent: 'center' },

  // Edit modal
  modalOverlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: 'rgba(0,0,0,0.5)' },
  modalCard: {
    borderTopLeftRadius: 24, borderTopRightRadius: 24,
    padding: 24, paddingBottom: 32, gap: 16,
    maxHeight: '90%',
    shadowColor: '#000', shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.1, shadowRadius: 12, elevation: 10,
  },
  modalTitle: { fontSize: 22, fontWeight: '700' },
  fieldLabel: { fontSize: 14, fontWeight: '600', marginBottom: 4 },
  editWeightRow: { flexDirection: 'row', gap: 12, alignItems: 'center' },
  editWeightInput: { flex: 1, borderWidth: 2, borderRadius: 12, padding: 12, fontSize: 20, fontWeight: '700' },
  editUnitToggle: { flexDirection: 'row', gap: 6 },
  editUnitBtn: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 10, borderWidth: 2 },
  editDateBtn: { flexDirection: 'row', alignItems: 'center', gap: 10, borderWidth: 2, borderRadius: 12, padding: 12 },
  editNoteInput: { borderWidth: 2, borderRadius: 12, padding: 12, fontSize: 16, minHeight: 70 },
  editPhotoActionBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 6, borderWidth: 1.5, borderRadius: 10, paddingVertical: 10 },
  modalButtons: { flexDirection: 'row', gap: 12 },
  modalCancelBtn: { flex: 1, height: 48, borderRadius: 12, borderWidth: 1.5, alignItems: 'center', justifyContent: 'center' },
  modalCancelText: { fontSize: 17, fontWeight: '600' },
  modalSaveBtn: { flex: 2, height: 48, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
});
