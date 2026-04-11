import React, { useState, useRef } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Alert,
  ActivityIndicator,
  Dimensions,
} from 'react-native';
import { useRouter } from 'expo-router';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/context/AuthContext';

const PURPLE = '#7B2D8B';
const PURPLE_MID = '#C4A2DC';
const PURPLE_PALE = '#F7F0FC';
const YELLOW = '#FFD700';
const DARK = '#1A1A1A';
const GRAY = '#6B7280';
const BG = '#F4EDF8';

const MEDICATIONS = ['Tirzepatide', 'Retatrutide', 'Lipo-C', 'NAD+', 'BPC-157'];

const TOTAL_STEPS = 6;

function kgToLbs(kg: number) { return +(kg * 2.20462).toFixed(1); }
function lbsToKg(lbs: number) { return +(lbs / 2.20462).toFixed(1); }
function cmToFtIn(cm: number) {
  const totalIn = cm / 2.54;
  const ft = Math.floor(totalIn / 12);
  const inch = Math.round(totalIn % 12);
  return { ft, inch };
}
function ftInToCm(ft: number, inch: number) { return +((ft * 12 + inch) * 2.54).toFixed(0); }

function getBmiCategory(bmi: number): { label: string; color: string; msg: string } {
  if (bmi < 18.5) return { label: 'Bajo peso', color: '#3B82F6', msg: 'Trabajaremos juntos para llegar a un peso saludable.' };
  if (bmi < 25)   return { label: 'Normal', color: '#10B981', msg: '¡Excelente! Mantengamos ese peso saludable.' };
  if (bmi < 30)   return { label: 'Sobrepeso', color: '#F59E0B', msg: 'Con pequeños cambios llegarás a tu meta. ¡Tú puedes!' };
  if (bmi < 35)   return { label: 'Obesidad I', color: '#EF4444', msg: 'Tu viaje de bienestar comienza hoy. ¡Juntos lo logramos!' };
  if (bmi < 40)   return { label: 'Obesidad II', color: '#DC2626', msg: 'Estamos contigo en cada paso. ¡Sin miedo!' };
  return           { label: 'Obesidad III', color: '#9F1239', msg: 'Cada día es una nueva oportunidad. ¡Comenzamos hoy!' };
}

export default function OnboardingScreen() {
  const [step, setStep] = useState(1);
  const [phone, setPhone] = useState('');
  const [weightVal, setWeightVal] = useState('');
  const [weightUnit, setWeightUnit] = useState<'kg' | 'lb'>('kg');
  const [goalVal, setGoalVal] = useState('');
  const [heightVal, setHeightVal] = useState('');
  const [heightFt, setHeightFt] = useState('');
  const [heightIn, setHeightIn] = useState('');
  const [heightUnit, setHeightUnit] = useState<'cm' | 'ft'>('cm');
  const [ageVal, setAgeVal] = useState('');
  const [sex, setSex] = useState<'femenino' | 'masculino' | null>(null);
  const [medications, setMedications] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);

  const weightRef = useRef<TextInput>(null);
  const heightRef = useRef<TextInput>(null);
  const heightInRef = useRef<TextInput>(null);
  const ageRef = useRef<TextInput>(null);

  const { user, refreshProfile } = useAuth();
  const router = useRouter();

  const fullName: string = (user?.user_metadata?.full_name as string) || 'Usuario';

  // Derived values
  const weightKg = weightVal
    ? (weightUnit === 'kg' ? parseFloat(weightVal) : lbsToKg(parseFloat(weightVal)))
    : 0;
  const goalKg = goalVal
    ? (weightUnit === 'kg' ? parseFloat(goalVal) : lbsToKg(parseFloat(goalVal)))
    : 0;
  const heightCm = heightUnit === 'cm'
    ? (heightVal ? parseFloat(heightVal) : 0)
    : ftInToCm(parseInt(heightFt) || 0, parseInt(heightIn) || 0);
  const age = parseInt(ageVal) || 0;
  const bmi = heightCm > 0 && weightKg > 0
    ? parseFloat((weightKg / Math.pow(heightCm / 100, 2)).toFixed(1))
    : 0;
  const bmiInfo = bmi > 0 ? getBmiCategory(bmi) : null;
  // Gauge marker position (BMI range 15–45)
  const markerPercent = bmi > 0
    ? Math.min(97, Math.max(3, ((bmi - 15) / 30) * 100))
    : 50;

  function validate(): boolean {
    if (step === 1) {
      if (!phone.trim()) { Alert.alert('Falta tu teléfono', 'Por favor ingresa tu número de WhatsApp'); return false; }
    }
    if (step === 2) {
      if (!weightVal || parseFloat(weightVal) <= 0) { Alert.alert('Falta tu peso', 'Ingresa tu peso actual'); return false; }
      if (!goalVal || parseFloat(goalVal) <= 0) { Alert.alert('Falta tu meta', 'Ingresa tu peso meta'); return false; }
    }
    if (step === 3) {
      if (heightUnit === 'cm' && (!heightVal || parseFloat(heightVal) <= 0)) {
        Alert.alert('Falta tu altura', 'Ingresa tu altura en cm'); return false;
      }
      if (heightUnit === 'ft' && (!heightFt)) {
        Alert.alert('Falta tu altura', 'Ingresa tu altura en pies'); return false;
      }
    }
    if (step === 4) {
      if (!ageVal || parseInt(ageVal) <= 0 || parseInt(ageVal) > 120) {
        Alert.alert('Falta tu edad', 'Ingresa una edad válida'); return false;
      }
    }
    if (step === 5) {
      if (!sex) { Alert.alert('Selecciona tu sexo', 'Elige una opción para continuar'); return false; }
    }
    if (step === 6) {
      if (medications.length === 0) { Alert.alert('Selecciona un medicamento', 'Elige al menos un medicamento de tu programa'); return false; }
    }
    return true;
  }

  async function handleNext() {
    if (!validate()) return;
    if (step < TOTAL_STEPS) {
      setStep(step + 1);
    } else {
      await completeOnboarding();
    }
  }

  async function completeOnboarding() {
    if (!user) return;
    setLoading(true);

    // Upsert profile (handles case where email already exists from data import)
    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .upsert([{
        auth_uid: user.id,
        full_name: fullName,
        email: user.email,
        phone: phone.trim(),
        sex,
        age,
        height_cm: heightCm,
        initial_weight_kg: weightKg,
        current_weight_kg: weightKg,
        goal_weight_kg: goalKg,
        bmi,
        bmi_category: bmiInfo?.label ?? 'Normal',
        role: 'usuario',
        is_active: true,
      }], { onConflict: 'email' })
      .select('id')
      .single();

    if (profileError) {
      Alert.alert('Error al guardar perfil', profileError.message);
      setLoading(false);
      return;
    }

    // Insert medications (one row per medication)
    if (medications.length > 0 && profileData?.id) {
      await supabase.from('patient_medications').insert(
        medications.map(med => ({
          patient_id: profileData.id,
          medication_name: med,
          active: true,
        }))
      );
    }

    setLoading(false);
    // Show celebration FIRST — refreshProfile() is called only when user taps "¡Ir a mi panel!"
    // Calling it here would trigger _layout.tsx to redirect before the user sees the screen
    setStep(TOTAL_STEPS + 1);
  }

  // ─── Celebration screen ───────────────────────────────────────────────────
  if (step === TOTAL_STEPS + 1) {
    return (
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.celebrationContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.celebrationCard}>
          <MaterialCommunityIcons name="trophy-variant" size={56} color={PURPLE} />
          <Text style={styles.celebrationTitle}>¡Tu IMC calculado!</Text>

          <Text style={[styles.bmiNumber, { color: bmiInfo?.color ?? PURPLE }]}>{bmi}</Text>

          <View style={[styles.bmiCategoryBadge, { backgroundColor: bmiInfo?.color ? `${bmiInfo.color}22` : PURPLE_PALE }]}>
            <Text style={[styles.bmiCategoryText, { color: bmiInfo?.color ?? PURPLE }]}>
              {bmiInfo?.label ?? 'N/A'} — ¡{bmiInfo?.msg ?? 'Bienvenido!'}
            </Text>
          </View>

          {/* Gauge bar */}
          <View style={styles.gaugeContainer}>
            <View style={styles.gaugeBar}>
              <View style={[styles.gaugeSegment, { backgroundColor: '#3B82F6', flex: 1 }]} />
              <View style={[styles.gaugeSegment, { backgroundColor: '#10B981', flex: 1.1 }]} />
              <View style={[styles.gaugeSegment, { backgroundColor: '#F59E0B', flex: 0.9 }]} />
              <View style={[styles.gaugeSegment, { backgroundColor: '#EF4444', flex: 0.9 }]} />
              <View style={[styles.gaugeSegment, { backgroundColor: '#DC2626', flex: 1.1 }]} />
            </View>
            {/* Marker */}
            <View style={[styles.gaugeMarker, { left: `${markerPercent}%` as any }]} />
          </View>

          <Text style={styles.gaugeStats}>
            {weightKg} kg · {(heightCm / 100).toFixed(2)} m · {age} años
          </Text>

          <Text style={styles.celebrationMsg}>
            Tu viaje de bienestar comienza hoy.{'\n'}
            Juntos vamos a llegar a tu meta. ¡Tú puedes!
          </Text>

          <TouchableOpacity
            style={styles.panelButton}
            onPress={async () => {
              await refreshProfile();
              router.replace('/(tabs)');
            }}
          >
            <Text style={styles.panelButtonText}>¡Ir a mi panel!</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    );
  }

  // ─── Progress dots ────────────────────────────────────────────────────────
  const ProgressDots = () => (
    <View style={styles.dotsRow}>
      {Array.from({ length: TOTAL_STEPS }, (_, i) => (
        <View
          key={i}
          style={[
            styles.dot,
            i + 1 === step
              ? { backgroundColor: PURPLE, width: 28, borderRadius: 6 }
              : { backgroundColor: '#D1D5DB', width: 10, borderRadius: 5 },
          ]}
        />
      ))}
    </View>
  );

  const stepLabel = `Paso ${step} de ${TOTAL_STEPS}`;

  // ─── Step renders ─────────────────────────────────────────────────────────
  function renderStep() {
    switch (step) {
      // ── STEP 1: Phone ───────────────────────────────────────────────────
      case 1:
        return (
          <View style={styles.stepContent}>
            <MaterialCommunityIcons name="cellphone" size={64} color={PURPLE} style={{ marginBottom: 4 }} />
            <Text style={styles.stepTitle}>¿Cómo podemos{'\n'}contactarte?</Text>
            <Text style={styles.stepSubtitle}>Solo para enviarte recordatorios importantes</Text>

            <TextInput
              style={styles.phoneInput}
              placeholder="+1 (000) 000-0000"
              placeholderTextColor={GRAY}
              keyboardType="phone-pad"
              value={phone}
              onChangeText={setPhone}
              autoFocus
            />
            <Text style={styles.hint}>Tu número no será compartido con nadie</Text>
          </View>
        );

      // ── STEP 2: Weight ──────────────────────────────────────────────────
      case 2:
        return (
          <View style={styles.stepContent}>
            <MaterialCommunityIcons name="scale-bathroom" size={64} color={PURPLE} style={{ marginBottom: 4 }} />
            <Text style={styles.stepTitle}>¿Cuánto pesas hoy?</Text>
            <Text style={styles.stepSubtitle}>No te preocupes, esto es solo el punto de partida</Text>

            {/* Unit toggle */}
            <View style={styles.toggle}>
              {(['kg', 'lb'] as const).map(u => (
                <TouchableOpacity
                  key={u}
                  style={[styles.toggleBtn, weightUnit === u && styles.toggleBtnActive]}
                  onPress={() => setWeightUnit(u)}
                >
                  <Text style={[styles.toggleBtnText, weightUnit === u && styles.toggleBtnTextActive]}>{u}</Text>
                </TouchableOpacity>
              ))}
            </View>

            {/* Big display input */}
            <TouchableOpacity style={styles.bigBox} onPress={() => weightRef.current?.focus()} activeOpacity={0.8}>
              <Text style={[styles.bigBoxText, !weightVal && { color: '#BEBEBE' }]}>
                {weightVal || '00.0'}
              </Text>
            </TouchableOpacity>
            <TextInput ref={weightRef} style={styles.hiddenInput} value={weightVal} onChangeText={setWeightVal} keyboardType="decimal-pad" caretHidden />
            <Text style={styles.unitLabel}>{weightUnit}</Text>
            <Text style={[styles.hint, { color: PURPLE, fontWeight: '600' }]}>
              Ej: {weightUnit === 'kg' ? '60-80 kg' : '132-176 lb'}
            </Text>

            {/* Goal weight */}
            <Text style={[styles.goalLabel]}>Meta de peso ({weightUnit})</Text>
            <TextInput
              style={styles.goalInput}
              placeholder={weightUnit === 'kg' ? 'Ej. 65' : 'Ej. 143'}
              placeholderTextColor={GRAY}
              keyboardType="decimal-pad"
              value={goalVal}
              onChangeText={setGoalVal}
            />
          </View>
        );

      // ── STEP 3: Height ──────────────────────────────────────────────────
      case 3:
        return (
          <View style={styles.stepContent}>
            <MaterialCommunityIcons name="human-male-height" size={64} color={PURPLE} style={{ marginBottom: 4 }} />
            <Text style={styles.stepTitle}>¿Cuánto mides?</Text>
            <Text style={styles.stepSubtitle}>Necesitamos esto para calcular tu índice de salud</Text>

            <View style={styles.toggle}>
              {(['cm', 'ft'] as const).map(u => (
                <TouchableOpacity
                  key={u}
                  style={[styles.toggleBtn, heightUnit === u && styles.toggleBtnActive]}
                  onPress={() => setHeightUnit(u)}
                >
                  <Text style={[styles.toggleBtnText, heightUnit === u && styles.toggleBtnTextActive]}>
                    {u === 'ft' ? 'ft/in' : 'cm'}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            {heightUnit === 'cm' ? (
              <>
                <TouchableOpacity style={styles.bigBox} onPress={() => heightRef.current?.focus()} activeOpacity={0.8}>
                  <Text style={[styles.bigBoxText, !heightVal && { color: '#BEBEBE' }]}>
                    {heightVal || '000'}
                  </Text>
                </TouchableOpacity>
                <TextInput ref={heightRef} style={styles.hiddenInput} value={heightVal} onChangeText={setHeightVal} keyboardType="number-pad" caretHidden />
                <Text style={styles.unitLabel}>cm</Text>
                <Text style={[styles.hint, { color: GRAY }]}>¿Sabías que la altura promedio mundial es 171 cm?</Text>
              </>
            ) : (
              <>
                <View style={styles.ftRow}>
                  <View style={styles.ftCol}>
                    <TouchableOpacity style={styles.bigBox} onPress={() => heightRef.current?.focus()} activeOpacity={0.8}>
                      <Text style={[styles.bigBoxText, !heightFt && { color: '#BEBEBE' }]}>{heightFt || '0'}</Text>
                    </TouchableOpacity>
                    <TextInput ref={heightRef} style={styles.hiddenInput} value={heightFt} onChangeText={setHeightFt} keyboardType="number-pad" caretHidden />
                    <Text style={styles.unitLabel}>pies</Text>
                  </View>
                  <View style={styles.ftCol}>
                    <TouchableOpacity style={styles.bigBox} onPress={() => heightInRef.current?.focus()} activeOpacity={0.8}>
                      <Text style={[styles.bigBoxText, !heightIn && { color: '#BEBEBE' }]}>{heightIn || '0'}</Text>
                    </TouchableOpacity>
                    <TextInput ref={heightInRef} style={styles.hiddenInput} value={heightIn} onChangeText={setHeightIn} keyboardType="number-pad" caretHidden />
                    <Text style={styles.unitLabel}>pulgadas</Text>
                  </View>
                </View>
                {heightCm > 0 && (
                  <Text style={[styles.hint, { color: PURPLE }]}>= {heightCm} cm</Text>
                )}
              </>
            )}
          </View>
        );

      // ── STEP 4: Age ─────────────────────────────────────────────────────
      case 4:
        return (
          <View style={styles.stepContent}>
            <MaterialCommunityIcons name="cake-variant" size={64} color={PURPLE} style={{ marginBottom: 4 }} />
            <Text style={styles.stepTitle}>¿Cuántos años tienes?</Text>
            <Text style={styles.stepSubtitle}>¡La edad es solo un número!</Text>

            <TouchableOpacity style={styles.bigBox} onPress={() => ageRef.current?.focus()} activeOpacity={0.8}>
              <Text style={[styles.bigBoxText, !ageVal && { color: '#BEBEBE' }]}>
                {ageVal || '00'}
              </Text>
            </TouchableOpacity>
            <TextInput ref={ageRef} style={styles.hiddenInput} value={ageVal} onChangeText={setAgeVal} keyboardType="number-pad" caretHidden />
            <Text style={styles.unitLabel}>años</Text>
            <Text style={[styles.hint, { color: GRAY }]}>Solo para personalizar mejor tu programa</Text>
          </View>
        );

      // ── STEP 5: Sex ─────────────────────────────────────────────────────
      case 5:
        return (
          <View style={styles.stepContent}>
            <MaterialCommunityIcons name="account-heart" size={64} color={PURPLE} style={{ marginBottom: 4 }} />
            <Text style={styles.stepTitle}>¿Cómo te identificas?</Text>
            <Text style={styles.stepSubtitle}>Esto nos ayuda a personalizar tu experiencia</Text>

            <View style={styles.sexRow}>
              {[
                { value: 'femenino' as const, icon: 'face-woman' as const, label: 'Femenino' },
                { value: 'masculino' as const, icon: 'face-man' as const, label: 'Masculino' },
              ].map(opt => (
                <TouchableOpacity
                  key={opt.value}
                  style={[styles.sexCard, sex === opt.value && styles.sexCardActive]}
                  onPress={() => setSex(opt.value)}
                >
                  <MaterialCommunityIcons
                    name={opt.icon}
                    size={48}
                    color={sex === opt.value ? PURPLE : GRAY}
                  />
                  <Text style={[styles.sexLabel, sex === opt.value && { color: PURPLE, fontWeight: '700' }]}>
                    {opt.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
              <MaterialCommunityIcons name="lock" size={13} color={GRAY} />
              <Text style={[styles.hint, { color: GRAY }]}>Tu información es privada y segura</Text>
            </View>
          </View>
        );

      // ── STEP 6: Medication ───────────────────────────────────────────────
      case 6:
        return (
          <View style={styles.stepContent}>
            <MaterialCommunityIcons name="pill" size={64} color={PURPLE} style={{ marginBottom: 4 }} />
            <Text style={styles.stepTitle}>¿Cuál es tu{'\n'}medicamento?</Text>
            <Text style={styles.stepSubtitle}>Selecciona el medicamento de tu programa</Text>

            <Text style={[styles.hint, { color: PURPLE, marginBottom: 4 }]}>
              Puedes seleccionar más de uno
            </Text>
            <View style={styles.medGrid}>
              {MEDICATIONS.map(med => {
                const active = medications.includes(med);
                return (
                  <TouchableOpacity
                    key={med}
                    style={[styles.medCard, active && styles.medCardActive]}
                    onPress={() =>
                      setMedications(prev =>
                        active ? prev.filter(m => m !== med) : [...prev, med]
                      )
                    }
                  >
                    {active && (
                      <MaterialCommunityIcons name="check-circle" size={16} color="white" style={{ position: 'absolute', top: 8, right: 8 }} />
                    )}
                    <Text style={[styles.medText, active && { color: 'white', fontWeight: '700' }]}>
                      {med}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        );

      default:
        return null;
    }
  }

  // ─── Main render ──────────────────────────────────────────────────────────
  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.scrollContent}
      keyboardShouldPersistTaps="handled"
      showsVerticalScrollIndicator={false}
    >
      <ProgressDots />
      <Text style={styles.stepLabel}>{stepLabel}</Text>

      {renderStep()}

      {/* Buttons */}
      <View style={styles.footer}>
        {step === TOTAL_STEPS ? (
          <TouchableOpacity
            style={[styles.continueBtn, loading && { opacity: 0.7 }]}
            onPress={handleNext}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color={DARK} />
            ) : (
              <Text style={styles.continueBtnText}>Calcular IMC</Text>
            )}
          </TouchableOpacity>
        ) : (
          <TouchableOpacity style={styles.continueBtn} onPress={handleNext}>
            <Text style={styles.continueBtnText}>Continuar →</Text>
          </TouchableOpacity>
        )}

        {step > 1 && (
          <TouchableOpacity style={styles.backBtn} onPress={() => setStep(step - 1)}>
            <Text style={styles.backBtnText}>← Atrás</Text>
          </TouchableOpacity>
        )}
      </View>
    </ScrollView>
  );
}

const { width } = Dimensions.get('window');

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: BG },
  scrollContent: { paddingHorizontal: 24, paddingTop: 60, paddingBottom: 40 },

  // Dots
  dotsRow: { flexDirection: 'row', gap: 6, justifyContent: 'center', marginBottom: 10 },
  dot: { height: 10 },
  stepLabel: { textAlign: 'center', color: GRAY, fontSize: 13, marginBottom: 32 },

  // Step content
  stepContent: { alignItems: 'center', gap: 14 },
  stepTitle: { fontSize: 26, fontWeight: '800', color: PURPLE, textAlign: 'center', lineHeight: 34 },
  stepSubtitle: { fontSize: 14, color: GRAY, textAlign: 'center', lineHeight: 20, paddingHorizontal: 10 },

  // Phone input
  phoneInput: {
    width: '100%',
    height: 60,
    borderWidth: 2,
    borderColor: PURPLE_MID,
    borderRadius: 16,
    paddingHorizontal: 20,
    fontSize: 22,
    color: DARK,
    textAlign: 'center',
    backgroundColor: 'white',
    marginTop: 8,
  },

  // Toggle
  toggle: {
    flexDirection: 'row',
    backgroundColor: '#EDE4F7',
    borderRadius: 14,
    padding: 4,
    gap: 4,
  },
  toggleBtn: {
    paddingHorizontal: 24,
    paddingVertical: 8,
    borderRadius: 10,
  },
  toggleBtnActive: { backgroundColor: YELLOW },
  toggleBtnText: { fontSize: 14, fontWeight: '600', color: GRAY },
  toggleBtnTextActive: { color: DARK },

  // Big box input
  bigBox: {
    width: width - 80,
    height: 90,
    borderWidth: 2,
    borderColor: PURPLE_MID,
    borderRadius: 16,
    backgroundColor: 'white',
    alignItems: 'center',
    justifyContent: 'center',
  },
  bigBoxText: { fontSize: 52, fontWeight: '700', color: DARK },
  hiddenInput: { position: 'absolute', opacity: 0, width: 1, height: 1 },
  unitLabel: { fontSize: 14, color: GRAY, fontWeight: '500' },
  hint: { fontSize: 12, color: GRAY, textAlign: 'center' },

  // Goal
  goalLabel: { fontSize: 13, fontWeight: '600', color: DARK, alignSelf: 'flex-start' },
  goalInput: {
    width: '100%',
    height: 52,
    borderWidth: 2,
    borderColor: PURPLE_MID,
    borderRadius: 14,
    paddingHorizontal: 16,
    fontSize: 18,
    color: DARK,
    textAlign: 'center',
    backgroundColor: 'white',
  },

  // Ft/in
  ftRow: { flexDirection: 'row', gap: 16 },
  ftCol: { alignItems: 'center', gap: 8 },

  // Sex
  sexRow: { flexDirection: 'row', gap: 16, marginTop: 8 },
  sexCard: {
    flex: 1,
    paddingVertical: 24,
    borderRadius: 16,
    borderWidth: 2,
    borderColor: PURPLE_MID,
    alignItems: 'center',
    gap: 10,
    backgroundColor: 'white',
  },
  sexCardActive: { borderColor: PURPLE, borderWidth: 3, backgroundColor: PURPLE_PALE },
  sexLabel: { fontSize: 15, fontWeight: '600', color: DARK },

  // Medication
  medGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, justifyContent: 'center', marginTop: 8 },
  medCard: {
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderRadius: 14,
    borderWidth: 2,
    borderColor: PURPLE_MID,
    backgroundColor: 'white',
    minWidth: '44%',
    alignItems: 'center',
  },
  medCardActive: { backgroundColor: PURPLE, borderColor: PURPLE },
  medText: { fontSize: 14, fontWeight: '600', color: DARK },

  // Footer buttons
  footer: { marginTop: 36, gap: 12 },
  continueBtn: {
    height: 56,
    backgroundColor: YELLOW,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
  },
  continueBtnText: { fontSize: 17, fontWeight: '800', color: DARK },
  backBtn: { alignItems: 'center', paddingVertical: 8 },
  backBtnText: { fontSize: 14, color: PURPLE, fontWeight: '600', textDecorationLine: 'underline' },

  // Celebration
  celebrationContent: { flex: 1, justifyContent: 'center', padding: 24, paddingTop: 60 },
  celebrationCard: {
    backgroundColor: 'white',
    borderRadius: 24,
    padding: 24,
    alignItems: 'center',
    gap: 14,
    shadowColor: '#7B2D8B',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.12,
    shadowRadius: 20,
    elevation: 8,
  },
  celebrationTitle: { fontSize: 22, fontWeight: '800', color: PURPLE, textAlign: 'center' },
  bmiNumber: { fontSize: 72, fontWeight: '900', lineHeight: 80 },
  bmiCategoryBadge: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 12,
    alignItems: 'center',
  },
  bmiCategoryText: { fontSize: 14, fontWeight: '700', textAlign: 'center' },

  // Gauge
  gaugeContainer: { width: '100%', marginVertical: 4, position: 'relative' },
  gaugeBar: {
    flexDirection: 'row',
    height: 14,
    borderRadius: 7,
    overflow: 'hidden',
  },
  gaugeSegment: { height: '100%' },
  gaugeMarker: {
    position: 'absolute',
    top: -8,
    width: 4,
    height: 28,
    backgroundColor: DARK,
    borderRadius: 2,
    marginLeft: -2,
  },
  gaugeStats: { fontSize: 13, color: GRAY, marginTop: 4 },
  celebrationMsg: { fontSize: 14, color: DARK, textAlign: 'center', lineHeight: 22, paddingHorizontal: 8 },
  panelButton: {
    width: '100%',
    height: 56,
    backgroundColor: YELLOW,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 4,
  },
  panelButtonText: { fontSize: 17, fontWeight: '800', color: DARK },
});
