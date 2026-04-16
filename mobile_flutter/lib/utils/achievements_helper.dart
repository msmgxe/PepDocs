// achievements_helper.dart
//
// Motor de Logros y Sugerencias para la app Flutter.
// Usa IconData (Material Icons) en vez de emojis — los emojis no renderizan
// en simuladores iOS (muestran "?").

import 'package:flutter/material.dart';

/// Modelo de un logro
class Achievement {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String name;
  final String desc;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.desc,
    required this.unlocked,
  });
}

/// Modelo de una sugerencia diaria
class Suggestion {
  final String id;
  final IconData icon;
  final String title;
  final String desc;
  final bool isYellow;

  const Suggestion({
    required this.id,
    required this.icon,
    required this.title,
    required this.desc,
    required this.isYellow,
  });
}

/// Calcula los logros del paciente a partir de sus estadísticas de salud.
List<Achievement> calculateAchievements({
  required double initialWeight,
  required double currentWeight,
  required double goalWeight,
  required double bmi,
  required int measurementCount,
  int? age,
  String? sex,
}) {
  final lost = initialWeight - currentWeight;
  final toGoal = currentWeight - goalWeight;

  return [
    Achievement(
      id: '1',
      icon: Icons.flag_outlined,
      iconColor: Colors.amber,
      name: 'Primer Paso',
      desc: 'Tu primer pesaje registrado',
      unlocked: measurementCount >= 1,
    ),
    Achievement(
      id: '2',
      icon: Icons.local_fire_department_outlined,
      iconColor: Colors.orange,
      name: 'Semana Activa',
      desc: '7 pesajes registrados',
      unlocked: measurementCount >= 7,
    ),
    Achievement(
      id: '3',
      icon: Icons.trending_down,
      iconColor: Colors.green,
      name: 'Avance Notable',
      desc: 'Has perdido el 5% de tu peso inicial',
      unlocked: initialWeight > 0 && lost >= (initialWeight * 0.05),
    ),
    Achievement(
      id: '4',
      icon: Icons.star_outline,
      iconColor: Colors.deepPurple,
      name: 'Meta Cercana',
      desc: 'A menos de 2 kg de tu meta',
      unlocked: goalWeight > 0 && toGoal > 0 && toGoal <= 2,
    ),
    Achievement(
      id: '5',
      icon: Icons.emoji_events_outlined,
      iconColor: Colors.amber,
      name: 'Meta Alcanzada',
      desc: '¡Llegaste a tu peso meta!',
      unlocked: goalWeight > 0 && toGoal <= 0 && measurementCount >= 1,
    ),
    Achievement(
      id: '6',
      icon: Icons.favorite_outline,
      iconColor: Colors.red,
      name: 'Salud Óptima',
      desc: 'Tu IMC está en rango normal (18.5–24.9)',
      unlocked: bmi >= 18.5 && bmi < 25,
    ),
  ];
}

/// Genera las sugerencias del día personalizadas según el perfil del paciente.
List<Suggestion> getSuggestions({
  required double bmi,
  int? age,
  String? sex,
}) {
  final hydration = Suggestion(
    id: 'water',
    icon: Icons.water_drop_outlined,
    title: 'Hidratación',
    desc: bmi >= 30
        ? 'Bebe al menos 3 litros de agua al día'
        : 'Bebe 8 vasos de agua al día',
    isYellow: false,
  );

  final Suggestion movement;
  if (age != null && age >= 60) {
    movement = const Suggestion(
      id: 'move_senior',
      icon: Icons.directions_walk_outlined,
      title: 'Movimiento',
      desc: '30 min de caminata a paso ligero',
      isYellow: true,
    );
  } else {
    movement = const Suggestion(
      id: 'move_active',
      icon: Icons.directions_run_outlined,
      title: 'Movimiento',
      desc: '30 min de actividad física',
      isYellow: true,
    );
  }

  return [hydration, movement];
}
