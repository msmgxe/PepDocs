import React, { useEffect, useState, useRef, useCallback } from 'react';
import { useFocusEffect } from 'expo-router';
import {
  StyleSheet,
  View,
  Text,
  ScrollView,
  RefreshControl,
  Dimensions,
} from 'react-native';
import { useAuth } from '@/context/AuthContext';
import { useUnits, formatWeight } from '@/context/UnitsContext';
import { supabase } from '@/lib/supabase';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Svg, Polyline, Circle, Line, Text as SvgText, Defs, ClipPath, Rect, Polygon } from 'react-native-svg';
import { GestureDetector, Gesture } from 'react-native-gesture-handler';
import { useSharedValue } from 'react-native-reanimated';

type AchievementIcon = React.ComponentProps<typeof MaterialCommunityIcons>['name'];

const ACHIEVEMENTS: { id: number; icon: AchievementIcon; name: string; desc: string; check: (count: number, diff: number) => boolean }[] = [
  { id: 1, icon: 'medal-outline',   name: 'Primer Paso',    desc: 'Tu primer pesaje registrado',  check: (c)       => c >= 1 },
  { id: 2, icon: 'fire',            name: 'Semana Activa',  desc: '7 pesajes registrados',         check: (c)       => c >= 7 },
  { id: 3, icon: 'star-outline',    name: 'Meta Cercana',   desc: 'A menos de 2 kg de tu meta',   check: (_, d)    => d > 0 && d <= 2 },
  { id: 4, icon: 'trophy-outline',  name: 'Meta Alcanzada', desc: '¡Llegaste a tu peso meta!',    check: (_, d)    => d <= 0 },
];

function dateLabel(dateStr: string) {
  const d = new Date(dateStr);
  const now = new Date();
  const sameYear = d.getFullYear() === now.getFullYear();
  return d.toLocaleDateString('es-ES', {
    day: 'numeric',
    month: 'short',
    ...(sameYear ? {} : { year: 'numeric' }),
  });
}

const SCREEN_W = Dimensions.get('window').width;
const CHART_W = SCREEN_W - 64;
const CHART_H = 200;
const PAD = { left: 44, right: 10, top: 14, bottom: 34 };

function ProgressChart({ measurements, goalWeight, theme }: {
  measurements: any[];
  goalWeight: number;
  theme: typeof Colors.light;
}) {
  const n = measurements.length;
  const [visibleRange, setVisibleRange] = useState<[number, number]>([0, Math.max(0, n - 1)]);
  const currentStart = useSharedValue(0);
  const currentEnd   = useSharedValue(Math.max(0, n - 1));
  const savedStart   = useSharedValue(0);
  const savedEnd     = useSharedValue(Math.max(0, n - 1));

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
    .onBegin(() => { savedStart.value = currentStart.value; savedEnd.value = currentEnd.value; })
    .onUpdate((e) => {
      const span = savedEnd.value - savedStart.value;
      const mid  = (savedStart.value + savedEnd.value) / 2;
      const newSpan  = Math.round(span / Math.max(0.1, e.scale));
      const clamped  = Math.max(2, Math.min(Math.max(n - 1, 0), newSpan));
      const newStart = Math.max(0, Math.round(mid - clamped / 2));
      const newEnd   = Math.min(Math.max(n - 1, 0), newStart + clamped);
      updateRange(newStart, newEnd);
    });

  if (n === 0) {
    return (
      <View style={[styles.chartEmpty, { backgroundColor: theme.lilacPale }]}>
        <MaterialCommunityIcons name="chart-line" size={28} color={theme.icon} />
        <Text style={{ color: theme.icon, fontSize: 15, marginTop: 6, textAlign: 'center' }}>
          Registra al menos 2 pesajes para ver tu gráfico
        </Text>
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

  const goalY = toY(goalWeight);
  const pts   = visible.map((m, i) => `${toX(i)},${toY(m.weight_kg)}`).join(' ');

  // filled area polygon
  const areaPoints = visible.length > 1
    ? `${toX(0)},${PAD.top + innerH} ${pts} ${toX(visible.length - 1)},${PAD.top + innerH}`
    : '';

  // Y ticks
  const yStep = Math.ceil((maxW - minW) / 4);
  const yTicks: number[] = [];
  for (let v = Math.ceil(minW); v <= maxW; v += Math.max(1, yStep)) yTicks.push(v);

  // X labels (max 5)
  const xLabels: { label: string; x: number }[] = [];
  const step = Math.max(1, Math.ceil(visible.length / 5));
  for (let i = 0; i < visible.length; i++) {
    if (i % step === 0 || i === visible.length - 1) {
      xLabels.push({ label: dateLabel(visible[i].measurement_date), x: toX(i) });
    }
  }

  // scrollbar
  const thumbLeft  = n > 1 ? (startIdx / (n - 1)) * innerW : 0;
  const thumbWidth = n > 1 ? Math.max(14, ((endIdx - startIdx) / (n - 1)) * innerW) : innerW;
  const showScrollbar = endIdx - startIdx < n - 1;

  return (
    <GestureDetector gesture={pinch}>
      <View>
        <Svg width={CHART_W} height={CHART_H}>
          <Defs>
            <ClipPath id="progressClip">
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
          {goalWeight > 0 && (
            <Line x1={PAD.left} y1={goalY} x2={PAD.left + innerW} y2={goalY}
              stroke={theme.yellow} strokeWidth={1.5} strokeDasharray="6,3" clipPath="url(#progressClip)" />
          )}

          {/* Area fill */}
          {areaPoints.length > 0 && (
            <Polygon points={areaPoints} fill={theme.lilacDark} fillOpacity={0.08} clipPath="url(#progressClip)" />
          )}

          {/* Weight line */}
          {visible.length > 1 && (
            <Polyline points={pts} fill="none" stroke={theme.lilacDark} strokeWidth={2.5}
              strokeLinecap="round" strokeLinejoin="round" clipPath="url(#progressClip)" />
          )}

          {/* Data points */}
          {visible.map((m, i) => (
            <Circle key={m.id ?? i} cx={toX(i)} cy={toY(m.weight_kg)}
              r={visible.length <= 10 ? 4 : 2.5}
              fill={theme.yellow} stroke={theme.lilacDark} strokeWidth={1.5}
              clipPath="url(#progressClip)" />
          ))}

          {/* Y axis labels */}
          {yTicks.map((v, i) => (
            <SvgText key={`yt${i}`} x={PAD.left - 4} y={toY(v) + 4}
              fontSize={9} fill={theme.icon} textAnchor="end">
              {Math.round(v * 10) / 10}
            </SvgText>
          ))}

          {/* X axis labels */}
          {xLabels.map((l, i) => (
            <SvgText key={`xt${i}`} x={l.x} y={CHART_H - 4}
              fontSize={9} fill={theme.icon} textAnchor="middle">
              {l.label}
            </SvgText>
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

export default function ProgressScreen() {
  const { user } = useAuth();
  const { weightUnit } = useUnits();
  const [profile, setProfile] = useState<any>(null);
  const [measurements, setMeasurements] = useState<any[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [refreshing, setRefreshing] = useState(false);
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];

  async function fetchData() {
    if (!user) return;
    const { data: profileData } = await supabase.from('profiles').select('*').eq('auth_uid', user.id).single();
    if (profileData) {
      setProfile(profileData);
      const { data: chartData } = await supabase
        .from('measurements')
        .select('id, measurement_date, weight_kg')
        .eq('patient_id', profileData.id)
        .order('measurement_date', { ascending: true });
      if (chartData) setMeasurements(chartData);
      const { count } = await supabase
        .from('measurements')
        .select('id', { count: 'exact', head: true })
        .eq('patient_id', profileData.id);
      setTotalCount(count ?? 0);
    }
    setRefreshing(false);
  }

  useEffect(() => { fetchData(); }, [user]);

  // Re-fetch every time the tab comes into focus so chart reflects latest data
  useFocusEffect(useCallback(() => { fetchData(); }, [user]));

  const initial  = profile?.initial_weight_kg  ?? 0;
  const current  = profile?.current_weight_kg  ?? 0;
  const goal     = profile?.goal_weight_kg      ?? 0;
  const goalDiff = current - goal;

  return (
    <ScrollView
      style={[styles.container, { backgroundColor: theme.background }]}
      contentContainerStyle={styles.content}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); fetchData(); }} tintColor={theme.lilacDark} />}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.header}>
        <Text style={[styles.title, { color: theme.lilacDark }]}>Progreso</Text>
        <Text style={[styles.subtitle, { color: theme.icon }]}>Tu evolución a lo largo del tiempo</Text>
      </View>

      {/* Chart */}
      <View style={[styles.chartContainer, { borderColor: theme.border, backgroundColor: theme.background }]}>
        <ProgressChart
          measurements={measurements}
          goalWeight={goal}
          theme={theme}
        />
      </View>

      {/* Stats Row */}
      <View style={styles.statsRow}>
        {([
          { icon: 'flag-checkered' as AchievementIcon, label: 'INICIO', value: initial ? formatWeight(initial, weightUnit) : '—' },
          { icon: 'map-marker'     as AchievementIcon, label: 'HOY',    value: current ? formatWeight(current, weightUnit) : '—' },
          { icon: 'bullseye-arrow' as AchievementIcon, label: 'META',   value: goal    ? formatWeight(goal, weightUnit)    : '—' },
        ]).map(s => (
          <View key={s.label} style={[styles.statCard, { backgroundColor: theme.lilacPale, borderColor: theme.lilacLight }]}>
            <MaterialCommunityIcons name={s.icon} size={18} color={theme.lilacDark} />
            <Text style={[styles.statLabel, { color: theme.icon }]}>{s.label}</Text>
            <Text style={[styles.statValue, { color: theme.lilacDark }]}>{s.value}</Text>
          </View>
        ))}
      </View>

      {/* Summary */}
      {initial > 0 && current > 0 && (
        <View style={[styles.summaryCard, { backgroundColor: theme.yellowSoft }]}>
          <MaterialCommunityIcons
            name={goalDiff <= 0 ? 'trophy' : current < initial ? 'trending-down' : 'trending-up'}
            size={24} color={theme.lilacDark}
          />
          <View style={{ flex: 1 }}>
            <Text style={[styles.summaryTitle, { color: theme.lilacDark }]}>
              {goalDiff <= 0 ? '¡Meta alcanzada!' : current < initial ? `Has bajado ${formatWeight(initial - current, weightUnit)}` : `Inicio en ${formatWeight(initial, weightUnit)}`}
            </Text>
            <Text style={[styles.summarySubtitle, { color: theme.text }]}>
              {goalDiff > 0 ? `Faltan ${formatWeight(goalDiff, weightUnit)} para tu meta de ${formatWeight(goal, weightUnit)}` : '¡Excelente trabajo, sigue así!'}
            </Text>
          </View>
        </View>
      )}

      {/* Achievements */}
      <Text style={[styles.sectionTitle, { color: theme.text }]}>Logros</Text>
      <View style={styles.achievementsGrid}>
        {ACHIEVEMENTS.map(a => {
          const unlocked = a.check(totalCount, goalDiff);
          return (
            <View key={a.id} style={[styles.achievementCard,
              unlocked
                ? { backgroundColor: theme.lilacLight, borderColor: theme.lilacMedium }
                : { backgroundColor: '#F3F4F6', borderColor: theme.border, opacity: 0.55 }
            ]}>
              <MaterialCommunityIcons name={a.icon} size={32} color={unlocked ? theme.lilacDark : '#9CA3AF'} />
              <Text style={[styles.achievementName, { color: theme.text }]}>{a.name}</Text>
              <Text style={[styles.achievementDesc, { color: theme.icon }]}>{a.desc}</Text>
              {!unlocked && <MaterialCommunityIcons name="lock-outline" size={16} color="#9CA3AF" />}
            </View>
          );
        })}
      </View>

      {/* Suggestions */}
      <Text style={[styles.sectionTitle, { color: theme.text }]}>Sugerencias del día</Text>
      <View style={styles.suggestionsRow}>
        <View style={[styles.suggestionCard, { backgroundColor: theme.lilacPale, borderColor: theme.lilacLight }]}>
          <MaterialCommunityIcons name="cup-water" size={32} color={theme.lilacDark} />
          <Text style={[styles.suggestionTitle, { color: theme.text }]}>Hidratación</Text>
          <Text style={[styles.suggestionDesc, { color: theme.icon }]}>Bebe 8 vasos de agua al día</Text>
        </View>
        <View style={[styles.suggestionCard, { backgroundColor: theme.yellowSoft, borderColor: '#F5F3C6' }]}>
          <MaterialCommunityIcons name="run-fast" size={32} color={theme.lilacDark} />
          <Text style={[styles.suggestionTitle, { color: theme.text }]}>Movimiento</Text>
          <Text style={[styles.suggestionDesc, { color: theme.icon }]}>30 min de actividad física</Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { padding: 16, paddingTop: 60, gap: 16, paddingBottom: 40 },

  header: { gap: 4, marginBottom: 4 },
  title: { fontSize: 24, fontWeight: '700' },
  subtitle: { fontSize: 15 },

  chartContainer: { borderRadius: 12, padding: 12, borderWidth: 1, overflow: 'hidden' },
  chartEmpty: { height: 120, borderRadius: 12, alignItems: 'center', justifyContent: 'center', padding: 16 },
  scrollbarTrack: { height: 3, borderRadius: 2, marginTop: 4 },
  scrollbarThumb: { height: 3, borderRadius: 2 },
  chartHint: { fontSize: 12, textAlign: 'center', marginTop: 6 },

  statsRow: { flexDirection: 'row', gap: 10 },
  statCard: { flex: 1, padding: 12, borderRadius: 12, alignItems: 'center', gap: 4, borderWidth: 1 },
  statLabel: { fontSize: 13, textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: '600' },
  statValue: { fontSize: 17, fontWeight: '700' },

  summaryCard: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 14, borderRadius: 12 },
  summaryTitle: { fontSize: 18, fontWeight: '700' },
  summarySubtitle: { fontSize: 15, marginTop: 2 },

  sectionTitle: { fontSize: 18, fontWeight: '700', marginTop: 4 },

  achievementsGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  achievementCard: { width: '47%', borderRadius: 12, padding: 12, alignItems: 'center', gap: 6, borderWidth: 1 },
  achievementName: { fontSize: 15, fontWeight: '700', textAlign: 'center' },
  achievementDesc: { fontSize: 14, textAlign: 'center', lineHeight: 18 },

  suggestionsRow: { flexDirection: 'row', gap: 10 },
  suggestionCard: { flex: 1, borderRadius: 12, padding: 14, alignItems: 'center', gap: 6, borderWidth: 1 },
  suggestionTitle: { fontSize: 16, fontWeight: '700', textAlign: 'center' },
  suggestionDesc: { fontSize: 15, textAlign: 'center', lineHeight: 20 },
});
