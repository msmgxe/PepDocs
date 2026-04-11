import React, { useEffect, useState } from 'react';
import {
  StyleSheet,
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  TextInput,
  ActivityIndicator,
} from 'react-native';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'expo-router';
import { supabase } from '@/lib/supabase';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { MaterialCommunityIcons } from '@expo/vector-icons';

const TIPS = [
  'Recuerda beber al menos 8 vasos de agua al día para apoyar tu metabolismo y bienestar.',
  'Dormir bien es clave: 7-8 horas favorecen la pérdida de peso y la energía diaria.',
  'Pequeños cambios constantes crean grandes resultados. ¡Sigue así!',
  'Comer despacio y sin distracciones ayuda a sentir la saciedad a tiempo.',
  'Medir tu progreso semanalmente es más motivador que hacerlo cada día.',
  'La actividad física no tiene que ser intensa: caminar 30 min al día hace la diferencia.',
  'Incluir proteínas en cada comida te ayuda a mantener la masa muscular mientras bajas de peso.',
];

export default function HomeScreen() {
  const { user } = useAuth();
  const [profile, setProfile] = useState<any>(null);
  const [nextEvent, setNextEvent] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [datosExpanded, setDatosExpanded] = useState(true);
  const [notes, setNotes] = useState('');
  const [savingNotes, setSavingNotes] = useState(false);
  const router = useRouter();
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];

  async function fetchData() {
    if (!user) return;
    setLoading(true);

    const { data: profileData } = await supabase
      .from('profiles')
      .select('*')
      .eq('auth_uid', user.id)
      .single();

    if (profileData) {
      setProfile(profileData);
      setNotes(profileData.profile_notes || '');

      const today = new Date().toISOString().split('T')[0];
      const { data: eventData } = await supabase
        .from('calendar_events')
        .select('id, title, event_date, event_type')
        .eq('patient_id', profileData.id)
        .gte('event_date', today)
        .order('event_date', { ascending: true })
        .limit(1)
        .single();

      setNextEvent(eventData ?? null);
    }
    setLoading(false);
    setRefreshing(false);
  }

  async function saveNotes() {
    if (!profile) return;
    setSavingNotes(true);
    await supabase.from('profiles').update({ profile_notes: notes }).eq('id', profile.id);
    setSavingNotes(false);
  }

  async function handleLogout() {
    setDrawerOpen(false);
    await supabase.auth.signOut();
    router.replace('/(auth)/login');
  }

  useEffect(() => {
    fetchData();
  }, [user]);

  const onRefresh = () => {
    setRefreshing(true);
    fetchData();
  };

  const lostWeight =
    profile?.initial_weight_kg && profile?.current_weight_kg
      ? Math.max(0, parseFloat((profile.initial_weight_kg - profile.current_weight_kg).toFixed(1)))
      : 0;

  const weeksActive = profile?.registration_date
    ? Math.floor((Date.now() - new Date(profile.registration_date).getTime()) / (7 * 24 * 60 * 60 * 1000))
    : 0;

  const tipOfDay = TIPS[new Date().getDay() % TIPS.length];

  if (loading && !refreshing) {
    return (
      <View style={[styles.container, { backgroundColor: theme.background, justifyContent: 'center', alignItems: 'center' }]}>
        <ActivityIndicator color={theme.lilacDark} />
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      {/* Drawer Overlay */}
      {drawerOpen && (
        <TouchableOpacity
          style={styles.drawerOverlay}
          activeOpacity={1}
          onPress={() => setDrawerOpen(false)}
        />
      )}

      {/* Drawer */}
      <View
        style={[
          styles.drawer,
          drawerOpen && styles.drawerOpen,
          { backgroundColor: theme.background },
        ]}
      >
        <View style={[styles.drawerHeader, { borderBottomColor: theme.border }]}>
          <View style={[styles.drawerAvatar, { backgroundColor: theme.lilacLight }]}>
            <MaterialCommunityIcons name="account" size={24} color={theme.lilacDark} />
          </View>
          <View style={{ flex: 1, gap: 2 }}>
            <Text style={[styles.drawerName, { color: theme.text }]}>
              {profile?.full_name || 'Usuario'}
            </Text>
            <Text style={[styles.drawerEmail, { color: theme.icon }]}>{user?.email || ''}</Text>
          </View>
        </View>

        <View style={styles.drawerNav}>
          {([
            { icon: 'home-outline', label: 'Inicio', onPress: () => setDrawerOpen(false) },
            { icon: 'scale-bathroom', label: 'Registrar Peso', onPress: () => { setDrawerOpen(false); router.push('/(tabs)/weight'); } },
            { icon: 'chart-line', label: 'Progreso', onPress: () => { setDrawerOpen(false); router.push('/(tabs)/progress'); } },
            { icon: 'calendar-month-outline', label: 'Calendario', onPress: () => { setDrawerOpen(false); router.push('/(tabs)/calendar'); } },
          ] as const).map(item => (
            <TouchableOpacity key={item.label} style={styles.drawerItem} onPress={item.onPress}>
              <MaterialCommunityIcons name={item.icon} size={20} color={theme.lilacDark} style={styles.drawerItemIcon} />
              <Text style={[styles.drawerItemText, { color: theme.text }]}>{item.label}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <TouchableOpacity
          style={[styles.drawerItem, { borderTopWidth: 1, borderTopColor: theme.border, paddingVertical: 16 }]}
          onPress={handleLogout}
        >
          <MaterialCommunityIcons name="logout" size={20} color={theme.red} style={styles.drawerItemIcon} />
          <Text style={[styles.drawerItemText, { color: theme.red }]}>Cerrar Sesión</Text>
        </TouchableOpacity>

        <Text style={[styles.drawerFooter, { color: theme.icon }]}>Pep Education v1.0</Text>
      </View>

      {/* Header */}
      <View style={[styles.header, { borderBottomColor: theme.border }]}>
        <TouchableOpacity onPress={() => setDrawerOpen(true)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
          <MaterialCommunityIcons name="menu" size={26} color={theme.lilacDark} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: theme.text }]}>Inicio</Text>
        <MaterialCommunityIcons name="bell-outline" size={24} color={theme.lilacDark} />
      </View>

      <ScrollView
        contentContainerStyle={styles.content}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={theme.lilacDark} />}
        showsVerticalScrollIndicator={false}
      >
        {/* Profile Card */}
        <View style={styles.profileCard}>
          <View style={styles.profileAvatar}>
            <MaterialCommunityIcons name="account" size={36} color={theme.lilacDark} />
          </View>
          <View style={styles.profileInfo}>
            <Text style={styles.profileName}>{profile?.full_name || 'Usuario'}</Text>
            <Text style={styles.profileDate}>
              Miembro desde{' '}
              {profile?.registration_date
                ? new Date(profile.registration_date).toLocaleDateString('es-ES', {
                    month: 'long',
                    year: 'numeric',
                  })
                : '—'}
            </Text>
            <View style={styles.profileBadge}>
              <Text style={styles.profileBadgeText}>
                IMC: {profile?.bmi || '--'} · {profile?.bmi_category || 'N/A'}
              </Text>
            </View>
          </View>
        </View>

        {/* Mini Cards */}
        <View style={styles.miniCards}>
          <View style={[styles.miniCard, { borderColor: theme.lilacLight }]}>
            <MaterialCommunityIcons name="bullseye-arrow" size={24} color={theme.lilacDark} />
            <Text style={[styles.miniCardLabel, { color: theme.icon }]}>META</Text>
            <Text style={[styles.miniCardValue, { color: theme.lilacDark }]}>
              {profile?.goal_weight_kg ? `${profile.goal_weight_kg} kg` : '—'}
            </Text>
          </View>
          <View style={[styles.miniCard, { borderColor: theme.lilacLight }]}>
            <MaterialCommunityIcons name="trending-down" size={24} color={theme.lilacDark} />
            <Text style={[styles.miniCardLabel, { color: theme.icon }]}>PERDIDO</Text>
            <Text style={[styles.miniCardValue, { color: theme.lilacDark }]}>{lostWeight} kg</Text>
          </View>
          <View style={[styles.miniCard, { borderColor: theme.lilacLight }]}>
            <MaterialCommunityIcons name="calendar-week" size={24} color={theme.lilacDark} />
            <Text style={[styles.miniCardLabel, { color: theme.icon }]}>SEMANAS</Text>
            <Text style={[styles.miniCardValue, { color: theme.lilacDark }]}>{weeksActive}</Text>
          </View>
        </View>

        {/* Next Appointment */}
        {nextEvent ? (
          <View style={[styles.appointmentCard, { backgroundColor: theme.yellowSoft }]}>
            <MaterialCommunityIcons name="calendar-clock" size={28} color={theme.yellow} />
            <View style={{ flex: 1 }}>
              <Text style={[styles.appointmentTitle, { color: theme.lilacDark }]}>
                {nextEvent.title}
              </Text>
              <Text style={[styles.appointmentDate, { color: theme.text }]}>
                {new Date(nextEvent.event_date).toLocaleDateString('es-ES', {
                  weekday: 'short',
                  day: 'numeric',
                  month: 'short',
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </Text>
            </View>
          </View>
        ) : (
          <View style={[styles.appointmentCard, { backgroundColor: theme.lilacPale }]}>
            <MaterialCommunityIcons name="calendar-blank" size={28} color={theme.lilacMedium} />
            <View style={{ flex: 1 }}>
              <Text style={[styles.appointmentTitle, { color: theme.lilacDark }]}>
                Sin citas próximas
              </Text>
              <Text style={[styles.appointmentDate, { color: theme.icon }]}>
                Tu nutricionista te avisará
              </Text>
            </View>
          </View>
        )}

        {/* Mis Datos (collapsible) */}
        <View style={styles.section}>
          <TouchableOpacity
            style={styles.sectionHeader}
            onPress={() => setDatosExpanded(!datosExpanded)}
          >
            <Text style={[styles.sectionTitle, { color: theme.text }]}>Mis datos</Text>
            <MaterialCommunityIcons
              name={datosExpanded ? 'chevron-down' : 'chevron-right'}
              size={20}
              color={theme.icon}
            />
          </TouchableOpacity>

          {datosExpanded && (
            <View style={styles.sectionContent}>
              {[
                {
                  label: 'Peso inicial',
                  value: profile?.initial_weight_kg ? `${profile.initial_weight_kg} kg` : '—',
                },
                {
                  label: 'Peso actual',
                  value: profile?.current_weight_kg ? `${profile.current_weight_kg} kg` : '—',
                },
                {
                  label: 'Meta',
                  value: profile?.goal_weight_kg ? `${profile.goal_weight_kg} kg` : '—',
                },
                {
                  label: 'Altura',
                  value: profile?.height_cm ? `${profile.height_cm} cm` : '—',
                },
                { label: 'Edad', value: profile?.age ? `${profile.age} años` : '—' },
                { label: 'Sexo', value: profile?.sex || '—' },
              ].map(chip => (
                <View
                  key={chip.label}
                  style={[
                    styles.dataChip,
                    { backgroundColor: theme.lilacPale, borderColor: theme.lilacLight },
                  ]}
                >
                  <Text style={[styles.dataChipLabel, { color: theme.icon }]}>{chip.label}</Text>
                  <Text style={[styles.dataChipValue, { color: theme.lilacDark }]}>
                    {chip.value}
                  </Text>
                </View>
              ))}
            </View>
          )}
        </View>

        {/* Notas */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: theme.text }]}>Mis notas</Text>
          <TextInput
            style={[styles.notesInput, { borderColor: theme.lilacMedium, color: theme.text }]}
            placeholder="Escribe cómo te has sentido hoy..."
            placeholderTextColor={theme.icon}
            multiline
            maxLength={250}
            value={notes}
            onChangeText={setNotes}
            textAlignVertical="top"
          />
          <View style={styles.notesFooter}>
            <Text style={[styles.charCounter, { color: theme.icon }]}>{notes.length}/250</Text>
            <TouchableOpacity
              style={[styles.saveNotesBtn, { backgroundColor: theme.lilacDark }]}
              onPress={saveNotes}
              disabled={savingNotes}
            >
              <Text style={styles.saveNotesBtnText}>
                {savingNotes ? 'Guardando...' : 'Guardar'}
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Tip Card */}
        <View style={[styles.tipCard, { backgroundColor: theme.yellowSoft, borderLeftColor: theme.lilacDark }]}>
          <Text style={[styles.tipText, { color: theme.text }]}>{tipOfDay}</Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },

  // Drawer
  drawerOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.5)',
    zIndex: 25,
  },
  drawer: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    width: 280,
    left: -280,
    zIndex: 26,
    shadowColor: '#000',
    shadowOffset: { width: 2, height: 0 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
    elevation: 10,
  },
  drawerOpen: { left: 0 },
  drawerHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 16,
    paddingTop: 60,
    borderBottomWidth: 1,
  },
  drawerAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  drawerName: { fontSize: 16, fontWeight: '700' },
  drawerEmail: { fontSize: 13 },
  drawerNav: { flex: 1, paddingVertical: 16 },
  drawerItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 13,
    paddingHorizontal: 16,
  },
  drawerItemIcon: { fontSize: 20, width: 28 },
  drawerItemText: { fontSize: 16 },
  drawerFooter: { padding: 16, fontSize: 13, textAlign: 'center' },

  // Header
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 60,
    paddingBottom: 12,
    borderBottomWidth: 1,
  },
  headerTitle: { fontSize: 18, fontWeight: '600' },

  // Content
  content: { padding: 16, gap: 16, paddingBottom: 40 },

  // Profile Card
  profileCard: {
    borderRadius: 16,
    padding: 16,
    flexDirection: 'row',
    gap: 12,
    backgroundColor: '#7B2D8B',
  },
  profileAvatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: 'rgba(255,255,255,0.2)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  profileInfo: { flex: 1, gap: 4 },
  profileName: { color: 'white', fontSize: 18, fontWeight: '700' },
  profileDate: { color: 'rgba(255,255,255,0.85)', fontSize: 14 },
  profileBadge: {
    backgroundColor: '#FFF9C4',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    alignSelf: 'flex-start',
    marginTop: 4,
  },
  profileBadgeText: { fontSize: 13, fontWeight: '600', color: '#1A1A1A' },

  // Mini Cards
  miniCards: { flexDirection: 'row', gap: 10 },
  miniCard: {
    flex: 1,
    padding: 12,
    borderRadius: 12,
    alignItems: 'center',
    backgroundColor: '#F7F0FC',
    borderWidth: 1,
  },
  miniCardIcon: { fontSize: 22, marginBottom: 4 },
  miniCardLabel: {
    fontSize: 13,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    fontWeight: '600',
  },
  miniCardValue: { fontSize: 17, fontWeight: '700', marginTop: 4 },

  // Appointment
  appointmentCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 12,
    borderRadius: 12,
  },
  appointmentTitle: { fontSize: 16, fontWeight: '700' },
  appointmentDate: { fontSize: 14 },

  // Section
  section: { gap: 10 },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 4,
  },
  sectionTitle: { fontSize: 16, fontWeight: '700' },
  sectionContent: { gap: 8 },
  dataChip: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 10,
    borderRadius: 10,
    borderWidth: 1,
  },
  dataChipLabel: { fontSize: 16, fontWeight: '500' },
  dataChipValue: { fontSize: 16, fontWeight: '600' },

  // Notes
  notesInput: {
    borderWidth: 2,
    borderRadius: 12,
    padding: 12,
    fontSize: 16,
    minHeight: 80,
  },
  notesFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  charCounter: { fontSize: 13 },
  saveNotesBtn: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 10,
  },
  saveNotesBtnText: { color: 'white', fontSize: 15, fontWeight: '600' },

  // Tip
  tipCard: {
    borderLeftWidth: 4,
    borderRadius: 12,
    padding: 12,
  },
  tipText: { fontSize: 15, lineHeight: 24 },
});
