/**
 * profile.tsx — Pantalla "Mi Perfil"
 * Permite al usuario editar sus datos personales y alternar
 * unidades de peso (kg / lbs) y estatura (cm / ft+in).
 * Los valores se almacenan siempre en kg y cm en Supabase.
 */

import React, { useEffect, useState } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Alert,
  ActivityIndicator,
  Platform,
  KeyboardAvoidingView,
} from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useRouter } from 'expo-router';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/context/AuthContext';
import { useUnits } from '@/context/UnitsContext';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';

// ─── Conversión de unidades ───────────────────────────────────────────────────

function kgToLbs(kg: number): number { return parseFloat((kg * 2.20462).toFixed(1)); }
function lbsToKg(lbs: number): number { return parseFloat((lbs / 2.20462).toFixed(2)); }

function cmToFtIn(cm: number): { ft: number; inch: number } {
  const totalIn = cm / 2.54;
  const ft = Math.floor(totalIn / 12);
  const inch = Math.round(totalIn % 12);
  return { ft, inch };
}

function ftInToCm(ft: number, inch: number): number {
  return parseFloat(((ft * 12 + inch) * 2.54).toFixed(1));
}

/** Calcula la edad en años a partir de una fecha de nacimiento */
function calcAge(dob: Date): number {
  const today = new Date();
  let age = today.getFullYear() - dob.getFullYear();
  const m = today.getMonth() - dob.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) age--;
  return Math.max(0, age);
}

// ─── Componente principal ─────────────────────────────────────────────────────

export default function ProfileScreen() {
  // — Tema y navegación —
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];
  const router = useRouter();
  const { user } = useAuth();

  // — Estado del perfil (valores en unidad nativa: kg y cm) —
  const [profileId, setProfileId] = useState<string | null>(null);
  const [fullName, setFullName] = useState('');
  const [sex, setSex] = useState<'masculino' | 'femenino'>('masculino');
  const [dob, setDob] = useState<Date>(new Date(1990, 0, 1));
  const [showDobPicker, setShowDobPicker] = useState(false);

  // — Unidades (global, persistido en AsyncStorage) —
  const { weightUnit, setWeightUnit, heightUnit, setHeightUnit } = useUnits();

  // — Estatura —
  const [heightCm, setHeightCm] = useState('');          // texto en cm
  const [heightFt, setHeightFt] = useState('');          // texto en pies (ft)
  const [heightIn, setHeightIn] = useState('');          // texto en pulgadas (in)

  // — Peso —
  const [currentWeight, setCurrentWeight] = useState(''); // texto en unidad activa
  const [goalWeight, setGoalWeight] = useState('');       // texto en unidad activa

  // — UI —
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // ─── Carga inicial del perfil ──────────────────────────────────────────────

  useEffect(() => {
    async function loadProfile() {
      if (!user) return;
      setLoading(true);

      const { data } = await supabase
        .from('profiles')
        .select('id, full_name, sex, age, height_cm, current_weight_kg, goal_weight_kg')
        .eq('auth_uid', user.id)
        .single();

      if (data) {
        setProfileId(data.id);
        setFullName(data.full_name ?? '');
        setSex((data.sex as 'masculino' | 'femenino') ?? 'masculino');

        // Reconstruir fecha aproximada de nacimiento desde la edad
        if (data.age) {
          const approxYear = new Date().getFullYear() - data.age;
          setDob(new Date(approxYear, 0, 1));
        }

        // Estatura: mostrar según unidad activa
        if (data.height_cm) {
          if (heightUnit === 'ft') {
            const { ft, inch } = cmToFtIn(data.height_cm);
            setHeightFt(String(ft));
            setHeightIn(String(inch));
          } else {
            setHeightCm(String(data.height_cm));
          }
        }

        // Peso: mostrar según unidad activa
        if (data.current_weight_kg) {
          setCurrentWeight(weightUnit === 'lbs' ? String(kgToLbs(data.current_weight_kg)) : String(data.current_weight_kg));
        }
        if (data.goal_weight_kg) {
          setGoalWeight(weightUnit === 'lbs' ? String(kgToLbs(data.goal_weight_kg)) : String(data.goal_weight_kg));
        }
      }

      setLoading(false);
    }

    loadProfile();
  }, [user]);

  // ─── Toggle de unidades de estatura ───────────────────────────────────────

  function toggleHeightUnit() {
    if (heightUnit === 'cm') {
      // cm → ft+in: convertir el valor actual
      const cm = parseFloat(heightCm) || 0;
      if (cm > 0) {
        const { ft, inch } = cmToFtIn(cm);
        setHeightFt(String(ft));
        setHeightIn(String(inch));
      }
      setHeightUnit('ft');
    } else {
      // ft+in → cm: convertir los valores actuales
      const ft = parseInt(heightFt) || 0;
      const inch = parseInt(heightIn) || 0;
      if (ft > 0 || inch > 0) {
        setHeightCm(String(ftInToCm(ft, inch)));
      }
      setHeightUnit('cm');
    }
  }

  // ─── Toggle de unidades de peso ───────────────────────────────────────────

  function toggleWeightUnit() {
    if (weightUnit === 'kg') {
      // kg → lbs: convertir peso actual y meta
      const cw = parseFloat(currentWeight) || 0;
      const gw = parseFloat(goalWeight) || 0;
      if (cw > 0) setCurrentWeight(String(kgToLbs(cw)));
      if (gw > 0) setGoalWeight(String(kgToLbs(gw)));
      setWeightUnit('lbs');
    } else {
      // lbs → kg
      const cw = parseFloat(currentWeight) || 0;
      const gw = parseFloat(goalWeight) || 0;
      if (cw > 0) setCurrentWeight(String(lbsToKg(cw)));
      if (gw > 0) setGoalWeight(String(lbsToKg(gw)));
      setWeightUnit('kg');
    }
  }

  // ─── Guardar cambios en Supabase ──────────────────────────────────────────

  async function handleSave() {
    if (!profileId) return;

    // Normalizar estatura a cm para almacenar
    let finalHeightCm: number;
    if (heightUnit === 'cm') {
      finalHeightCm = parseFloat(heightCm) || 0;
    } else {
      finalHeightCm = ftInToCm(parseInt(heightFt) || 0, parseInt(heightIn) || 0);
    }

    // Normalizar pesos a kg para almacenar
    const finalCurrentKg = weightUnit === 'kg'
      ? parseFloat(currentWeight) || 0
      : lbsToKg(parseFloat(currentWeight) || 0);
    const finalGoalKg = weightUnit === 'kg'
      ? parseFloat(goalWeight) || 0
      : lbsToKg(parseFloat(goalWeight) || 0);

    // Calcular edad desde la fecha de nacimiento seleccionada
    const finalAge = calcAge(dob);

    // Validaciones básicas
    if (!fullName.trim()) {
      Alert.alert('Campo requerido', 'Ingresa tu nombre completo.');
      return;
    }
    if (finalHeightCm <= 0 || finalHeightCm > 300) {
      Alert.alert('Estatura inválida', 'Verifica los datos de estatura.');
      return;
    }
    if (finalCurrentKg <= 0 || finalCurrentKg > 600) {
      Alert.alert('Peso inválido', 'Verifica el peso actual.');
      return;
    }
    if (finalGoalKg <= 0 || finalGoalKg > 600) {
      Alert.alert('Peso objetivo inválido', 'Verifica el peso objetivo.');
      return;
    }

    setSaving(true);

    const { error } = await supabase
      .from('profiles')
      .update({
        full_name: fullName.trim(),
        sex,
        age: finalAge,
        height_cm: finalHeightCm,
        current_weight_kg: finalCurrentKg,
        goal_weight_kg: finalGoalKg,
      })
      .eq('id', profileId);

    setSaving(false);

    if (error) {
      Alert.alert('Error', 'No se pudieron guardar los cambios. Intenta de nuevo.');
    } else {
      Alert.alert('Guardado', 'Tu perfil ha sido actualizado.');
    }
  }

  // ─── Renderizado de carga ──────────────────────────────────────────────────

  if (loading) {
    return (
      <View style={[styles.centered, { backgroundColor: theme.background }]}>
        <ActivityIndicator size="large" color={theme.lilacDark} />
      </View>
    );
  }

  // ─── Render principal ──────────────────────────────────────────────────────

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: theme.background }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      {/* ── Cabecera con botón de retroceso ── */}
      <View style={[styles.header, { borderBottomColor: theme.border, backgroundColor: theme.background }]}>
        <TouchableOpacity
          onPress={() => router.back()}
          hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
        >
          <MaterialCommunityIcons name="arrow-left" size={24} color={theme.lilacDark} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: theme.text }]}>Mi Perfil</Text>
        {/* Placeholder para centrar el título */}
        <View style={{ width: 24 }} />
      </View>

      <ScrollView
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        {/* ── Nombre completo ── */}
        <View style={styles.fieldGroup}>
          <Text style={[styles.label, { color: theme.icon }]}>Nombre completo</Text>
          <View style={[styles.inputRow, { borderColor: theme.border }]}>
            <MaterialCommunityIcons name="account-outline" size={20} color={theme.icon} style={styles.inputIcon} />
            <TextInput
              style={[styles.input, { color: theme.text }]}
              value={fullName}
              onChangeText={setFullName}
              placeholder="Tu nombre"
              placeholderTextColor={theme.icon}
              autoCapitalize="words"
              maxLength={100}
            />
          </View>
        </View>

        {/* ── Sexo: toggle Masculino / Femenino ── */}
        <View style={styles.fieldGroup}>
          <Text style={[styles.label, { color: theme.icon }]}>Sexo</Text>
          <View style={styles.sexToggle}>
            {(['masculino', 'femenino'] as const).map(option => (
              <TouchableOpacity
                key={option}
                style={[
                  styles.sexBtn,
                  { borderColor: theme.border },
                  sex === option && { backgroundColor: theme.lilacDark, borderColor: theme.lilacDark },
                ]}
                onPress={() => setSex(option)}
              >
                <MaterialCommunityIcons
                  name={option === 'masculino' ? 'gender-male' : 'gender-female'}
                  size={18}
                  color={sex === option ? '#FFFFFF' : theme.icon}
                />
                <Text style={[
                  styles.sexBtnText,
                  { color: sex === option ? '#FFFFFF' : theme.text },
                ]}>
                  {option === 'masculino' ? 'Masculino' : 'Femenino'}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* ── Fecha de nacimiento ── */}
        <View style={styles.fieldGroup}>
          <Text style={[styles.label, { color: theme.icon }]}>Fecha de nacimiento</Text>
          <TouchableOpacity
            style={[styles.inputRow, { borderColor: theme.border }]}
            onPress={() => setShowDobPicker(true)}
          >
            <MaterialCommunityIcons name="calendar-outline" size={20} color={theme.icon} style={styles.inputIcon} />
            <Text style={[styles.inputText, { color: theme.text }]}>
              {dob.toLocaleDateString('es-ES', { day: 'numeric', month: 'numeric', year: 'numeric' })}
            </Text>
          </TouchableOpacity>

          {/* Date picker — iOS muestra inline, Android abre modal nativo */}
          {showDobPicker && (
            <DateTimePicker
              value={dob}
              mode="date"
              display={Platform.OS === 'ios' ? 'spinner' : 'default'}
              maximumDate={new Date()}
              onChange={(_, date) => {
                setShowDobPicker(Platform.OS === 'ios');
                if (date) setDob(date);
              }}
            />
          )}
          {/* Botón de confirmar en iOS (cierra el spinner) */}
          {showDobPicker && Platform.OS === 'ios' && (
            <TouchableOpacity
              style={[styles.dobConfirm, { backgroundColor: theme.lilacDark }]}
              onPress={() => setShowDobPicker(false)}
            >
              <Text style={styles.dobConfirmText}>Confirmar</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* ── Estatura con toggle cm / ft ── */}
        <View style={styles.fieldGroup}>
          {/* Encabezado con toggle de unidad */}
          <View style={styles.labelRow}>
            <Text style={[styles.label, { color: theme.icon }]}>
              Estatura ({heightUnit === 'cm' ? 'cm' : 'ft + in'})
            </Text>
            <TouchableOpacity
              style={[styles.unitToggle, { borderColor: theme.lilacDark }]}
              onPress={toggleHeightUnit}
            >
              <Text style={[styles.unitToggleText, { color: theme.lilacDark }]}>
                {heightUnit === 'cm' ? 'Cambiar a ft' : 'Cambiar a cm'}
              </Text>
            </TouchableOpacity>
          </View>

          {heightUnit === 'cm' ? (
            /* Campo en centímetros */
            <View style={[styles.inputRow, { borderColor: theme.lilacDark }]}>
              <MaterialCommunityIcons name="human-male-height" size={20} color={theme.lilacDark} style={styles.inputIcon} />
              <TextInput
                style={[styles.input, { color: theme.text }]}
                value={heightCm}
                onChangeText={setHeightCm}
                placeholder="175"
                placeholderTextColor={theme.icon}
                keyboardType="decimal-pad"
              />
              <Text style={[styles.unitLabel, { color: theme.icon }]}>cm</Text>
            </View>
          ) : (
            /* Campos en pies e pulgadas */
            <View style={styles.ftRow}>
              <View style={[styles.inputRow, styles.ftField, { borderColor: theme.lilacDark }]}>
                <MaterialCommunityIcons name="human-male-height" size={20} color={theme.lilacDark} style={styles.inputIcon} />
                <TextInput
                  style={[styles.input, { color: theme.text }]}
                  value={heightFt}
                  onChangeText={setHeightFt}
                  placeholder="5"
                  placeholderTextColor={theme.icon}
                  keyboardType="number-pad"
                />
                <Text style={[styles.unitLabel, { color: theme.icon }]}>ft</Text>
              </View>
              <View style={[styles.inputRow, styles.ftField, { borderColor: theme.lilacDark }]}>
                <TextInput
                  style={[styles.input, { color: theme.text }]}
                  value={heightIn}
                  onChangeText={setHeightIn}
                  placeholder="9"
                  placeholderTextColor={theme.icon}
                  keyboardType="number-pad"
                />
                <Text style={[styles.unitLabel, { color: theme.icon }]}>in</Text>
              </View>
            </View>
          )}
        </View>

        {/* ── Peso actual con toggle kg / lbs ── */}
        <View style={styles.fieldGroup}>
          <View style={styles.labelRow}>
            <Text style={[styles.label, { color: theme.icon }]}>
              Peso actual ({weightUnit})
            </Text>
            <TouchableOpacity
              style={[styles.unitToggle, { borderColor: theme.lilacDark }]}
              onPress={toggleWeightUnit}
            >
              <Text style={[styles.unitToggleText, { color: theme.lilacDark }]}>
                {weightUnit === 'kg' ? 'Cambiar a lbs' : 'Cambiar a kg'}
              </Text>
            </TouchableOpacity>
          </View>
          <View style={[styles.inputRow, { borderColor: theme.border }]}>
            <MaterialCommunityIcons name="scale-bathroom" size={20} color={theme.icon} style={styles.inputIcon} />
            <TextInput
              style={[styles.input, { color: theme.text }]}
              value={currentWeight}
              onChangeText={setCurrentWeight}
              placeholder={weightUnit === 'kg' ? '80.0' : '176.0'}
              placeholderTextColor={theme.icon}
              keyboardType="decimal-pad"
            />
            <Text style={[styles.unitLabel, { color: theme.icon }]}>{weightUnit}</Text>
          </View>
        </View>

        {/* ── Peso objetivo (hereda toggle del peso actual) ── */}
        <View style={styles.fieldGroup}>
          <Text style={[styles.label, { color: theme.icon }]}>
            Peso objetivo ({weightUnit})
          </Text>
          <View style={[styles.inputRow, { borderColor: theme.border }]}>
            <MaterialCommunityIcons name="flag-outline" size={20} color={theme.icon} style={styles.inputIcon} />
            <TextInput
              style={[styles.input, { color: theme.text }]}
              value={goalWeight}
              onChangeText={setGoalWeight}
              placeholder={weightUnit === 'kg' ? '70.0' : '154.0'}
              placeholderTextColor={theme.icon}
              keyboardType="decimal-pad"
            />
            <Text style={[styles.unitLabel, { color: theme.icon }]}>{weightUnit}</Text>
          </View>
        </View>

        {/* ── Botón guardar ── */}
        <TouchableOpacity
          style={[styles.saveBtn, { backgroundColor: theme.lilacDark }, saving && styles.saveBtnDisabled]}
          onPress={handleSave}
          disabled={saving}
        >
          {saving
            ? <ActivityIndicator color="#FFFFFF" size="small" />
            : <Text style={styles.saveBtnText}>Guardar cambios</Text>
          }
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

// ─── Estilos ──────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  // Pantalla centrada (estado de carga)
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },

  // Cabecera
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 60,
    paddingBottom: 14,
    borderBottomWidth: 1,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
  },

  // Scroll content
  content: {
    padding: 20,
    paddingBottom: 48,
    gap: 20,
  },

  // Grupo de campo
  fieldGroup: {
    gap: 8,
  },

  // Fila de etiqueta con toggle de unidad
  labelRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },

  // Etiqueta de campo
  label: {
    fontSize: 13,
    fontWeight: '500',
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },

  // Fila de input con icono
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1.5,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: Platform.OS === 'ios' ? 14 : 10,
    gap: 8,
  },
  inputIcon: {
    marginRight: 4,
  },
  input: {
    flex: 1,
    fontSize: 16,
  },
  inputText: {
    flex: 1,
    fontSize: 16,
  },
  unitLabel: {
    fontSize: 14,
    fontWeight: '600',
  },

  // Selector de sexo
  sexToggle: {
    flexDirection: 'row',
    gap: 10,
  },
  sexBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    borderWidth: 1.5,
    borderRadius: 12,
    paddingVertical: 12,
  },
  sexBtnText: {
    fontSize: 15,
    fontWeight: '600',
  },

  // Toggle de unidad (cm/ft, kg/lbs)
  unitToggle: {
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  unitToggleText: {
    fontSize: 12,
    fontWeight: '600',
  },

  // Fila ft + in (dos campos lado a lado)
  ftRow: {
    flexDirection: 'row',
    gap: 10,
  },
  ftField: {
    flex: 1,
  },

  // Confirmación de date picker en iOS
  dobConfirm: {
    marginTop: 8,
    padding: 12,
    borderRadius: 12,
    alignItems: 'center',
  },
  dobConfirmText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 15,
  },

  // Botón guardar
  saveBtn: {
    paddingVertical: 16,
    borderRadius: 14,
    alignItems: 'center',
    marginTop: 8,
  },
  saveBtnDisabled: {
    opacity: 0.7,
  },
  saveBtnText: {
    color: '#FFFFFF',
    fontSize: 17,
    fontWeight: '700',
  },
});
