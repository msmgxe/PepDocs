/**
 * _layout.tsx — Tab navigator principal de la app
 *
 * Define las 4 pestañas visibles en el tab bar y registra
 * las pantallas ocultas (profile, support) que son accesibles
 * solo mediante navegación programática (drawer / router.push).
 */

import { Tabs } from 'expo-router';
import React from 'react';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function TabLayout() {
  // ── Tema y áreas seguras ──────────────────────────────────────────────────
  const colorScheme = useColorScheme() ?? 'light';
  const theme = Colors[colorScheme];
  const insets = useSafeAreaInsets();

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: theme.tint,
        tabBarInactiveTintColor: theme.icon,
        headerShown: false,
        tabBarStyle: {
          height: 60 + insets.bottom,
          paddingBottom: insets.bottom + 8,
          paddingTop: 8,
          backgroundColor: theme.background,
          borderTopWidth: 1,
          borderTopColor: theme.border,
        },
      }}
    >
      {/* ── Pestañas visibles en el tab bar ────────────────────────────── */}
      <Tabs.Screen
        name="index"
        options={{
          title: 'Inicio',
          tabBarIcon: ({ color, size }) => (
            <MaterialCommunityIcons name="home-variant" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="weight"
        options={{
          title: 'Peso',
          tabBarIcon: ({ color, size }) => (
            <MaterialCommunityIcons name="scale" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="progress"
        options={{
          title: 'Progreso',
          tabBarIcon: ({ color, size }) => (
            <MaterialCommunityIcons name="chart-line" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="calendar"
        options={{
          title: 'Recordatorios',
          tabBarIcon: ({ color, size }) => (
            <MaterialCommunityIcons name="calendar-month" size={size} color={color} />
          ),
        }}
      />

      {/* ── Pantallas ocultas del tab bar ───────────────────────────────── */}
      {/* Soporte: accesible desde el menú de ayuda */}
      <Tabs.Screen
        name="support"
        options={{ href: null }}
      />
      {/* Mi Perfil: accesible desde el drawer lateral */}
      <Tabs.Screen
        name="profile"
        options={{ href: null }}
      />
    </Tabs>
  );
}
