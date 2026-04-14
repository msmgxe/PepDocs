// achievements_helper.dart
//
// Motor de Logros y Sugerencias para la app Flutter.
// La lógica es equivalente a la de admin/src/lib/achievements.ts.
// Evalúa los datos del perfil del paciente y devuelve:
//   - Lista de Achievement con estado desbloqueado/bloqueado
//   - Lista de Suggestion personalizadas según IMC, edad y sexo

/// Modelo de un logro
class Achievement {
  final String id;
  final String emoji;      // Emoji de representación visual del logro
  final String name;       // Nombre corto del logro
  final String desc;       // Descripción de la condición de desbloqueo
  final bool unlocked;     // true = logro desbloqueado

  const Achievement({
    required this.id,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.unlocked,
  });
}

/// Modelo de una sugerencia diaria
class Suggestion {
  final String id;
  final String emoji;      // Emoji para el icono de la tarjeta
  final String title;      // Nombre de la sugerencia
  final String desc;       // Descripción corta
  final bool isYellow;     // true = fondo amarillo pastel, false = fondo lila

  const Suggestion({
    required this.id,
    required this.emoji,
    required this.title,
    required this.desc,
    required this.isYellow,
  });
}

/// Calcula los logros del paciente a partir de sus estadísticas de salud.
///
/// [initialWeight]    : Peso inicial registrado (kg).
/// [currentWeight]    : Peso actual (kg).
/// [goalWeight]       : Peso meta (kg), 0 si no aplica.
/// [bmi]              : Índice de masa corporal actual.
/// [measurementCount] : Número total de pesajes registrados.
/// [age]              : Edad del paciente (puede ser null).
/// [sex]              : Sexo del paciente — 'M', 'F', 'O', o null.
List<Achievement> calculateAchievements({
  required double initialWeight,
  required double currentWeight,
  required double goalWeight,
  required double bmi,
  required int measurementCount,
  int? age,
  String? sex,
}) {
  final lost = initialWeight - currentWeight;           // kg perdidos
  final toGoal = currentWeight - goalWeight;            // kg restantes para meta

  return [
    Achievement(
      id: '1',
      emoji: '🥇',
      name: 'Primer Paso',
      desc: 'Tu primer pesaje registrado',
      unlocked: measurementCount >= 1,
    ),
    Achievement(
      id: '2',
      emoji: '🔥',
      name: 'Semana Activa',
      desc: '7 pesajes registrados',
      unlocked: measurementCount >= 7,
    ),
    Achievement(
      id: '3',
      emoji: '📉',
      name: 'Avance Notable',
      desc: 'Has perdido el 5% de tu peso inicial',
      unlocked: initialWeight > 0 && lost >= (initialWeight * 0.05),
    ),
    Achievement(
      id: '4',
      emoji: '⭐',
      name: 'Meta Cercana',
      desc: 'A menos de 2 kg de tu meta',
      unlocked: goalWeight > 0 && toGoal > 0 && toGoal <= 2,
    ),
    Achievement(
      id: '5',
      emoji: '🏆',
      name: 'Meta Alcanzada',
      desc: '¡Llegaste a tu peso meta!',
      unlocked: goalWeight > 0 && toGoal <= 0 && measurementCount >= 1,
    ),
    Achievement(
      id: '6',
      emoji: '❤️',
      name: 'Salud Óptima',
      desc: 'Tu IMC está en rango normal (18.5–24.9)',
      unlocked: bmi >= 18.5 && bmi < 25,
    ),
  ];
}

/// Genera las sugerencias del día personalizadas según el perfil del paciente.
///
/// Devuelve siempre 2 sugerencias (la primera en lila, la segunda en amarillo)
/// para respetar el layout de dos columnas de la pantalla de Progreso.
List<Suggestion> getSuggestions({
  required double bmi,
  int? age,
  String? sex,
}) {
  // Sugerencia 1: Hidratación (siempre presente, texto ajustado por IMC)
  final hydration = Suggestion(
    id: 'water',
    emoji: '🥤',
    title: 'Hidratación',
    desc: bmi >= 30
        ? 'Bebe al menos 3 litros de agua al día'
        : 'Bebe 8 vasos de agua al día',
    isYellow: false,
  );

  // Sugerencia 2: Movimiento (adaptada por edad)
  final Suggestion movement;
  if (age != null && age >= 60) {
    movement = const Suggestion(
      id: 'move_senior',
      emoji: '🚶',
      title: 'Movimiento',
      desc: '30 min de caminata a paso ligero',
      isYellow: true,
    );
  } else {
    movement = const Suggestion(
      id: 'move_active',
      emoji: '🏃',
      title: 'Movimiento',
      desc: '30 min de actividad física',
      isYellow: true,
    );
  }

  return [hydration, movement];
}
