// achievements_helper.dart
//
// Motor de Logros y Sugerencias para la app Flutter.
// Usa IconData (Material Icons) en vez de emojis — los emojis no renderizan
// en simuladores iOS (muestran "?").

import 'package:flutter/material.dart';
import '../services/language_service.dart';

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
  final l = LanguageService.instance;
  final lost = initialWeight - currentWeight;
  final toGoal = currentWeight - goalWeight;

  return [
    Achievement(
      id: '1',
      icon: Icons.flag_outlined,
      iconColor: Colors.amber,
      name: l.tr('ach_1_name'),
      desc: l.tr('ach_1_desc'),
      unlocked: measurementCount >= 1,
    ),
    Achievement(
      id: '2',
      icon: Icons.local_fire_department_outlined,
      iconColor: Colors.orange,
      name: l.tr('ach_2_name'),
      desc: l.tr('ach_2_desc'),
      unlocked: measurementCount >= 7,
    ),
    Achievement(
      id: '3',
      icon: Icons.trending_down,
      iconColor: Colors.green,
      name: l.tr('ach_3_name'),
      desc: l.tr('ach_3_desc'),
      unlocked: initialWeight > 0 && lost >= (initialWeight * 0.05),
    ),
    Achievement(
      id: '4',
      icon: Icons.star_outline,
      iconColor: Colors.deepPurple,
      name: l.tr('ach_4_name'),
      desc: l.tr('ach_4_desc'),
      unlocked: goalWeight > 0 && toGoal > 0 && toGoal <= 2,
    ),
    Achievement(
      id: '5',
      icon: Icons.emoji_events_outlined,
      iconColor: Colors.amber,
      name: l.tr('ach_5_name'),
      desc: l.tr('ach_5_desc'),
      unlocked: goalWeight > 0 && toGoal <= 0 && measurementCount >= 1,
    ),
    Achievement(
      id: '6',
      icon: Icons.favorite_outline,
      iconColor: Colors.red,
      name: l.tr('ach_6_name'),
      desc: l.tr('ach_6_desc'),
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
  final l = LanguageService.instance;

  final hydration = Suggestion(
    id: 'water',
    icon: Icons.water_drop_outlined,
    title: l.tr('sug_water_title'),
    desc: bmi >= 30
        ? l.tr('sug_water_desc_high')
        : l.tr('sug_water_desc_normal'),
    isYellow: false,
  );

  final Suggestion movement;
  if (age != null && age >= 60) {
    movement = Suggestion(
      id: 'move_senior',
      icon: Icons.directions_walk_outlined,
      title: l.tr('sug_move_title'),
      desc: l.tr('sug_move_senior_desc'),
      isYellow: true,
    );
  } else {
    movement = Suggestion(
      id: 'move_active',
      icon: Icons.directions_run_outlined,
      title: l.tr('sug_move_title'),
      desc: l.tr('sug_move_active_desc'),
      isYellow: true,
    );
  }

  return [hydration, movement];
}
