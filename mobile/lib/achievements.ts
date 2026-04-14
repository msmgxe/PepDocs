export type SexInfo = "M" | "F" | "O" | null;

export interface UserStats {
  initialWeight: number;
  currentWeight: number;
  goalWeight: number;
  bmi: number;
  age?: number;
  sex?: SexInfo;
  measurementCount: number;
}

export interface Achievement {
  id: string;
  icon: string;
  name: string;
  desc: string;
  unlocked: boolean;
}

export interface Suggestion {
  id: string;
  icon: string;
  title: string;
  desc: string;
  colorTheme: "lilac" | "yellow";
}

export function calculateAchievements(stats: UserStats): Achievement[] {
  const { initialWeight, currentWeight, goalWeight, measurementCount, bmi } = stats;
  const diff = currentWeight - goalWeight;
  const lost = initialWeight - currentWeight;

  return [
    {
      id: "1",
      icon: "medal-outline",
      name: "Primer Paso",
      desc: "Tu primer pesaje registrado",
      unlocked: measurementCount >= 1,
    },
    {
      id: "2",
      icon: "fire",
      name: "Semana Activa",
      desc: "7 pesajes registrados",
      unlocked: measurementCount >= 7,
    },
    {
      id: "3",
      icon: "trending-down",
      name: "Avance Notable",
      desc: "Has perdido 5% de tu peso inicial",
      unlocked: initialWeight > 0 && lost >= (initialWeight * 0.05),
    },
    {
      id: "4",
      icon: "star-outline",
      name: "Meta Cercana",
      desc: "A menos de 2 kg de tu meta",
      unlocked: goalWeight > 0 && diff > 0 && diff <= 2,
    },
    {
      id: "5",
      icon: "trophy-outline",
      name: "Meta Alcanzada",
      desc: "¡Llegaste a tu peso meta!",
      unlocked: goalWeight > 0 && diff <= 0 && measurementCount >= 1,
    },
    {
      id: "6",
      icon: "heart-pulse",
      name: "Salud Óptima",
      desc: "Tu IMC está en rango normal",
      unlocked: bmi >= 18.5 && bmi < 25,
    }
  ];
}

export function getSuggestions(stats: UserStats): Suggestion[] {
  const { bmi, age } = stats;
  
  const suggestions: Suggestion[] = [];
  
  // Basic Hydration
  suggestions.push({
    id: "water",
    icon: "cup-water",
    title: "Hidratación",
    desc: bmi >= 30 ? "Bebe al menos 3 litros de agua" : "Bebe 8 vasos de agua al día",
    colorTheme: "lilac"
  });

  // Movement
  if (age && age >= 60) {
    suggestions.push({
      id: "move_senior",
      icon: "walk",
      title: "Movimiento",
      desc: "30 min de caminata a paso ligero",
      colorTheme: "yellow"
    });
  } else {
    suggestions.push({
      id: "move_active",
      icon: "run-fast",
      title: "Movimiento",
      desc: "30 min de actividad física",
      colorTheme: "yellow"
    });
  }

  return suggestions.slice(0, 2);
}
